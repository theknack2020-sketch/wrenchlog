import SwiftData
import SwiftUI

struct EditFuelLogView: View {
    @Bindable var fuelLog: FuelLog
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var date: Date = .now
    @State private var mileage = ""
    @State private var volume = ""
    @State private var totalCost = ""
    @State private var pricePerUnit = ""
    @State private var fuelType: FuelType = .regular
    @State private var station = ""
    @State private var isFullTank = true
    @State private var notes = ""

    // Validation & error state
    @State private var validationError: String?
    @State private var saveError: String?
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
                                .onChange(of: volume) { _, _ in validationError = nil }
                            Text(fuelType.volumeLabel(fallback: fuelLog.volumeUnit))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, alignment: .leading)
                        }
                    }

                    Toggle("Full Tank", isOn: $isFullTank)
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
                        }
                    }

                    HStack {
                        Text("Price/\(fuelLog.volumeUnit.label)")
                        Spacer()
                        HStack(spacing: 2) {
                            Text(settings.currency.symbol)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $pricePerUnit)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                }

                Section("Station") {
                    TextField("Gas station name", text: $station)
                }

                Section("Notes") {
                    TextField("Notes...", text: $notes, axis: .vertical)
                        .lineLimit(3 ... 6)
                }
            }
            .formStyle(.grouped)
            .scrollDismissesKeyboard(.interactively)
            .frame(maxWidth: sizeClass == .regular ? 500 : .infinity)
            .navigationTitle("Edit Fuel Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                    .accessibilityIdentifier("editFuelLogCancel")
                    .accessibilityLabel("Cancel editing fuel log")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.shared.buttonTap()
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.accent)
                    .accessibilityIdentifier("editFuelLogSave")
                    .accessibilityLabel("Save fuel log changes")
                }
            }
            .onAppear {
                date = fuelLog.date
                mileage = fuelLog.mileage > 0 ? "\(fuelLog.mileage)" : ""
                volume = fuelLog.volume > 0 ? String(format: "%.2f", fuelLog.volume) : ""
                totalCost = fuelLog.totalCost > 0 ? String(format: "%.2f", fuelLog.totalCost) : ""
                pricePerUnit = fuelLog.pricePerUnit > 0 ? String(format: "%.3f", fuelLog.pricePerUnit) : ""
                fuelType = fuelLog.fuelType
                station = fuelLog.station
                isFullTank = fuelLog.isFullTank
                notes = fuelLog.notes
            }
            .alert("Save Failed", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "An unexpected error occurred.")
            }
        }
        .smoothSheetTransition()
    }

    private func saveChanges() {
        // Validate
        let result = FuelLogValidator.validate(
            volume: volume,
            totalCost: totalCost,
            mileage: mileage
        )
        guard result.isValid else {
            validationError = result.firstError
            HapticManager.shared.error()
            return
        }

        fuelLog.date = date
        fuelLog.mileage = max(0, Int(mileage) ?? fuelLog.mileage)
        fuelLog.volume = max(0, Double(volume) ?? fuelLog.volume)
        fuelLog.totalCost = max(0, Double(totalCost) ?? fuelLog.totalCost)
        fuelLog.pricePerUnit = max(0, Double(pricePerUnit) ?? fuelLog.pricePerUnit)
        fuelLog.fuelTypeRaw = fuelType.rawValue
        fuelLog.station = station.trimmingCharacters(in: .whitespaces)
        fuelLog.isFullTank = isFullTank
        fuelLog.notes = notes.trimmingCharacters(in: .whitespaces)

        // Update vehicle lastUpdated
        fuelLog.vehicle?.lastUpdated = .now

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
