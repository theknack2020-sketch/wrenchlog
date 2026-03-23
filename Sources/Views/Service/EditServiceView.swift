import SwiftUI
import SwiftData

struct EditServiceView: View {
    @Bindable var record: ServiceRecord
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme

    @State private var date: Date = .now
    @State private var mileage: String = ""
    @State private var cost: String = ""
    @State private var notes: String = ""

    // Validation & error state
    @State private var validationError: String?
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    HStack {
                        Image(systemName: record.icon)
                            .foregroundStyle(record.color)
                            .accessibilityHidden(true)
                        Text(record.displayServiceType)
                            .font(.subheadline.weight(.medium))
                    }
                    .accessibilityLabel("Service type: \(record.displayServiceType)")
                }

                Section {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                        .accessibilityLabel("Service date")

                    HStack {
                        Text("Mileage")
                        Spacer()
                        TextField(UserSettings.shared.distanceUnit.label, text: $mileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                            .accessibilityLabel("Odometer reading")
                            .onChange(of: mileage) { _, _ in validationError = nil }
                    }

                    HStack {
                        Text("Cost")
                        Spacer()
                        HStack(spacing: 2) {
                            Text(UserSettings.shared.currency.symbol)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $cost)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .accessibilityLabel("Service cost")
                                .onChange(of: cost) { _, _ in validationError = nil }
                        }
                    }
                } header: {
                    Text("Details")
                } footer: {
                    if let error = validationError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section("Notes") {
                    TextField("Notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Service notes")
                }
            }
            .navigationTitle("Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel editing")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                        .accessibilityLabel("Save changes")
                }
            }
            .onAppear {
                date = record.date
                mileage = record.mileage > 0 ? "\(record.mileage)" : ""
                cost = record.cost > 0 ? String(format: "%.2f", record.cost) : ""
                notes = record.notes
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
    }

    private func saveChanges() {
        // Validate
        let result = ServiceRecordValidator.validate(
            mileage: mileage,
            cost: cost
        )
        guard result.isValid else {
            validationError = result.firstError
            HapticManager.shared.error()
            return
        }

        record.date = date
        record.mileage = max(0, Int(mileage) ?? record.mileage)
        record.cost = max(0, Double(cost) ?? record.cost)
        record.notes = notes

        // Update vehicle lastUpdated
        record.vehicle?.lastUpdated = .now

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
