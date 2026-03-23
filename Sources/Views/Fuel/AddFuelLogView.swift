import SwiftUI
import SwiftData

struct AddFuelLogView: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date.now
    @State private var mileage = ""
    @State private var volume = ""
    @State private var totalCost = ""
    @State private var pricePerUnit = ""
    @State private var fuelType: FuelType = .regular
    @State private var station = ""
    @State private var isFullTank = true
    @State private var notes = ""
    @State private var editingCost = true // true = editing total cost, false = editing price/unit

    // Validation & error state
    @State private var validationError: String?
    @State private var saveError: String?
    @State private var isSaving = false

    private let settings = UserSettings.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Fuel Type") {
                    Picker("Type", selection: $fuelType) {
                        ForEach(FuelType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .accessibilityLabel("Fuel type: \(fuelType.rawValue)")
                }

                Section {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)

                    HStack {
                        Text("Odometer")
                        Spacer()
                        TextField(settings.distanceUnit.label, text: $mileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                            .onChange(of: mileage) { _, _ in validationError = nil }
                    }

                    HStack {
                        Text("Volume")
                        Spacer()
                        HStack(spacing: 2) {
                            TextField("0.00", text: $volume)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .onChange(of: volume) { _, _ in
                                    validationError = nil
                                    recalcFromVolume()
                                }
                            Text(settings.volumeUnit.label)
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .leading)
                        }
                    }

                    Toggle("Full Tank", isOn: $isFullTank)

                    if !isFullTank {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.orange)
                            Text("Partial fills can't calculate efficiency accurately")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Fill-Up Details")
                } footer: {
                    if let error = validationError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section("Cost") {
                    HStack {
                        Text("Total Cost")
                        Spacer()
                        HStack(spacing: 2) {
                            Text(settings.currency.symbol)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $totalCost)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .onChange(of: totalCost) { _, _ in
                                    validationError = nil
                                    if editingCost { recalcPricePerUnit() }
                                }
                                .onTapGesture { editingCost = true }
                        }
                    }

                    HStack {
                        Text("Price/\(settings.volumeUnit.label)")
                        Spacer()
                        HStack(spacing: 2) {
                            Text(settings.currency.symbol)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $pricePerUnit)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .onChange(of: pricePerUnit) { _, _ in
                                    if !editingCost { recalcTotalCost() }
                                }
                                .onTapGesture { editingCost = false }
                        }
                    }
                }

                Section("Station (optional)") {
                    TextField("Gas station name", text: $station)
                }

                Section("Notes (optional)") {
                    TextField("Any additional details...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log Fuel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel fuel log")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveFuelLog() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.wrenchAmber)
                        .disabled(!isValid || isSaving)
                        .accessibilityLabel("Save fuel log")
                        .accessibilityHint("Logs this fuel fill-up")
                }
            }
            .onAppear {
                mileage = vehicle.currentMileage > 0 ? "\(vehicle.currentMileage)" : ""
            }
            .alert("Save Failed", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil; isSaving = false }
            } message: {
                Text(saveError ?? "An unexpected error occurred.")
            }
        }
    }

    private var isValid: Bool {
        guard let vol = Double(volume), vol > 0 else { return false }
        guard let cost = Double(totalCost), cost > 0 else { return false }
        return true
    }

    private func recalcPricePerUnit() {
        guard let cost = Double(totalCost), let vol = Double(volume), vol > 0 else { return }
        pricePerUnit = String(format: "%.3f", cost / vol)
    }

    private func recalcTotalCost() {
        guard let price = Double(pricePerUnit), let vol = Double(volume), vol > 0 else { return }
        totalCost = String(format: "%.2f", price * vol)
    }

    private func recalcFromVolume() {
        if editingCost {
            recalcPricePerUnit()
        } else {
            recalcTotalCost()
        }
    }

    private func saveFuelLog() {
        // Validate
        let result = FuelLogValidator.validate(
            volume: volume,
            totalCost: totalCost,
            mileage: mileage,
            vehicleCurrentMileage: vehicle.currentMileage
        )
        guard result.isValid else {
            validationError = result.firstError
            HapticManager.shared.error()
            return
        }

        isSaving = true

        let log = FuelLog(
            date: date,
            mileage: max(0, Int(mileage) ?? 0),
            volume: max(0, Double(volume) ?? 0),
            totalCost: max(0, Double(totalCost) ?? 0),
            pricePerUnit: max(0, Double(pricePerUnit) ?? 0),
            fuelType: fuelType,
            station: station.trimmingCharacters(in: .whitespaces),
            isFullTank: isFullTank,
            notes: notes.trimmingCharacters(in: .whitespaces),
            volumeUnit: settings.volumeUnit
        )

        log.vehicle = vehicle

        // Update vehicle mileage if higher
        if let m = Int(mileage), m > vehicle.currentMileage {
            vehicle.currentMileage = m
        }
        vehicle.lastUpdated = .now

        context.insert(log)

        do {
            try DataManager.save(context)
            HapticManager.shared.success()
            SoundManager.playSaveSuccess()
            dismiss()
        } catch {
            saveError = error.errorDescription
            HapticManager.shared.error()
            SoundManager.playError()
        }
    }
}
