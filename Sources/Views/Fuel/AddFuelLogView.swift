import SwiftData
import SwiftUI

struct AddFuelLogView: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass

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
    @State private var volumeError: String?
    @State private var costError: String?
    @State private var mileageError: String?
    @State private var saveError: String?
    @State private var isSaving = false
    @State private var shakeTrigger = 0
    @FocusState private var isFocused: Bool

    private let settings = UserSettings.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select fuel type")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        FlowLayout(spacing: 8) {
                            ForEach(FuelType.allCases) { type in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        fuelType = type
                                    }
                                    HapticManager.shared.selection()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: type.icon)
                                            .font(.caption.weight(.semibold))
                                        Text(type.rawValue)
                                            .font(.caption.weight(.medium))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        fuelType == type
                                            ? AnyShapeStyle(type.color.opacity(0.18))
                                            : AnyShapeStyle(Color(.systemGray6)),
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(fuelType == type ? type.color.opacity(0.4) : .clear, lineWidth: 1.5)
                                    )
                                    .foregroundStyle(fuelType == type ? type.color : .primary)
                                    .scaleEffect(fuelType == type ? 1.03 : 1.0)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(type.rawValue)
                                .accessibilityAddTraits(fuelType == type ? .isSelected : [])
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Fuel Type")
                }

                Section {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Odometer")
                            Spacer()
                            TextField(settings.distanceUnit.label, text: $mileage)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                                .accessibilityLabel("Odometer reading")
                                .accessibilityIdentifier("addFuelMileage")
                                .onChange(of: mileage) { _, _ in validationError = nil; mileageError = nil }
                        }
                        if let err = mileageError {
                            Text(err)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    .listRowBackground(
                        mileageError != nil
                            ? Color.red.opacity(0.06)
                            : Color(.secondarySystemGroupedBackground)
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Volume")
                            Spacer()
                            HStack(spacing: 2) {
                                TextField("0.00", text: $volume)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .accessibilityLabel("Fuel volume")
                                    .accessibilityIdentifier("addFuelVolume")
                                    .onChange(of: volume) { _, _ in
                                        validationError = nil
                                        volumeError = nil
                                        recalcFromVolume()
                                    }
                                Text(fuelType.volumeLabel(fallback: settings.volumeUnit))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, alignment: .leading)
                            }
                        }
                        if let err = volumeError {
                            Text(err)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    .listRowBackground(
                        volumeError != nil
                            ? Color.red.opacity(0.06)
                            : Color(.secondarySystemGroupedBackground)
                    )

                    Toggle("Full Tank", isOn: $isFullTank)
                        .onChange(of: isFullTank) { _, _ in HapticManager.shared.sectionToggle() }

                    if !isFullTank {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                            Text("Partial fills can't calculate efficiency accurately")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Note: Partial fills can't calculate efficiency accurately")
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
                    VStack(alignment: .leading, spacing: 4) {
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
                                        costError = nil
                                        if editingCost { recalcPricePerUnit() }
                                    }
                                    .onTapGesture { editingCost = true }
                            }
                        }
                        if let err = costError {
                            Text(err)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    .listRowBackground(
                        costError != nil
                            ? Color.red.opacity(0.06)
                            : Color(.secondarySystemGroupedBackground)
                    )

                    HStack {
                        Text("Price/\(fuelType.volumeLabel(fallback: settings.volumeUnit))")
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
                        .accessibilityLabel("Gas station name")
                        .accessibilityIdentifier("addFuelStation")
                }

                Section("Notes (optional)") {
                    TextField("Any additional details...", text: $notes, axis: .vertical)
                        .lineLimit(3 ... 6)
                        .accessibilityLabel("Fuel log notes")
                        .accessibilityIdentifier("addFuelNotes")
                }
            }
            .formStyle(.grouped)
            .scrollDismissesKeyboard(.interactively)
            .frame(maxWidth: sizeClass == .regular ? 500 : .infinity)
            .navigationTitle("Log Fuel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                    .accessibilityIdentifier("addFuelLogCancel")
                    .accessibilityLabel("Cancel fuel log")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.shared.buttonTap()
                        saveFuelLog()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accent, theme.accent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .disabled(isSaving)
                    .shake(trigger: shakeTrigger)
                    .accessibilityIdentifier("addFuelLogSave")
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
        .smoothSheetTransition()
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
        // Clear previous field errors
        volumeError = nil
        costError = nil
        mileageError = nil
        validationError = nil

        var hasFieldError = false

        // Per-field inline validation
        if let vol = Double(volume) {
            if vol <= 0 {
                volumeError = "Volume must be greater than zero."
                hasFieldError = true
            }
        } else if volume.isEmpty {
            volumeError = "Volume is required."
            hasFieldError = true
        } else {
            volumeError = "Volume must be a valid number."
            hasFieldError = true
        }

        if let cost = Double(totalCost) {
            if cost < 0 {
                costError = "Cost cannot be negative."
                hasFieldError = true
            }
        } else if totalCost.isEmpty {
            costError = "Total cost is required."
            hasFieldError = true
        }

        if let m = Int(mileage) {
            if m < 0 {
                mileageError = "Mileage cannot be negative."
                hasFieldError = true
            } else if m > 0, m < vehicle.currentMileage, vehicle.currentMileage > 0 {
                mileageError = "Mileage is less than current odometer (\(vehicle.currentMileage.formatted()))."
                hasFieldError = true
            }
        } else if !mileage.isEmpty {
            mileageError = "Mileage must be a whole number."
            hasFieldError = true
        }

        guard !hasFieldError else {
            withAnimation(.default) { shakeTrigger += 1 }
            HapticManager.shared.error()
            return
        }

        // Run centralized validation as fallback
        let result = FuelLogValidator.validate(
            volume: volume,
            totalCost: totalCost,
            mileage: mileage,
            vehicleCurrentMileage: vehicle.currentMileage
        )
        guard result.isValid else {
            validationError = result.firstError
            withAnimation(.default) { shakeTrigger += 1 }
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
            HapticManager.shared.saveSuccess()
            SoundManager.playSaveSuccess()
            SoftPaywallTracker.shared.recordAction()
            TelemetryService.fuelLogged()
            dismiss()
        } catch {
            saveError = error.errorDescription
            HapticManager.shared.error()
            SoundManager.playError()
        }
    }
}
