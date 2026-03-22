import SwiftUI

struct AddServiceView: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ServiceType = .oilChange
    @State private var customTypeName = ""
    @State private var isCustom = false
    @State private var date = Date.now
    @State private var mileage = ""
    @State private var cost = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                // Service type
                Section("Service Type") {
                    Toggle("Custom Service", isOn: $isCustom)

                    if isCustom {
                        TextField("Service name", text: $customTypeName)
                    } else {
                        Picker("Type", selection: $selectedType) {
                            ForEach(ServiceCategory.allCases.filter { $0 != .custom }) { category in
                                Section(category.rawValue) {
                                    ForEach(ServiceType.types(for: category)) { type in
                                        Label(type.rawValue, systemImage: type.icon)
                                            .tag(type)
                                    }
                                }
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }

                // Details
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    HStack {
                        Text("Mileage")
                        Spacer()
                        TextField(UserSettings.shared.distanceUnit.label, text: $mileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
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
                        }
                    }
                }

                // Notes
                Section("Notes (optional)") {
                    TextField("Any additional details...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Reminder hint
                if !isCustom && selectedType.defaultMileageInterval > 0 {
                    Section {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(Color.wrenchAmber)
                            Text("Next reminder: \(selectedType.defaultMileageInterval.formatted()) \(UserSettings.shared.distanceUnit.label)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRecord() }
                        .fontWeight(.semibold)
                        .disabled(isCustom && customTypeName.isEmpty)
                }
            }
            .onAppear {
                mileage = vehicle.currentMileage > 0 ? "\(vehicle.currentMileage)" : ""
            }
        }
    }

    private func saveRecord() {
        let record: ServiceRecord
        if isCustom {
            record = ServiceRecord(
                customType: customTypeName.trimmingCharacters(in: .whitespaces),
                date: date,
                mileage: Int(mileage) ?? 0,
                cost: Double(cost) ?? 0,
                notes: notes
            )
        } else {
            record = ServiceRecord(
                serviceType: selectedType,
                date: date,
                mileage: Int(mileage) ?? 0,
                cost: Double(cost) ?? 0,
                notes: notes
            )
        }

        record.vehicle = vehicle

        // Update vehicle mileage if higher
        if let m = Int(mileage), m > vehicle.currentMileage {
            vehicle.currentMileage = m
        }

        context.insert(record)
        try? context.save()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
