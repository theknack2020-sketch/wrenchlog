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

    // New detail fields
    @State private var partsUsed: [String] = []
    @State private var newPartText = ""
    @State private var oilType = ""
    @State private var shopName = ""
    @State private var showOilTypePicker = false

    // Validation & error state
    @State private var validationError: String?
    @State private var saveError: String?
    @FocusState private var isFocused: Bool

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

                // MARK: - Shop / Service Provider
                Section("Service Provider") {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        TextField("Shop or mechanic name", text: $shopName)
                            .accessibilityLabel("Service provider name")
                    }

                    if !recentShops.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentShops, id: \.self) { shop in
                                    Button {
                                        shopName = shop
                                    } label: {
                                        Text(shop)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(shopName == shop ? theme.accent.opacity(0.2) : Color(.systemGray6))
                                            .foregroundStyle(shopName == shop ? theme.accent : .primary)
                                            .clipShape(Capsule())
                                    }
                                    .accessibilityLabel("Select \(shop)")
                                    .accessibilityAddTraits(shopName == shop ? .isSelected : [])
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // MARK: - Parts Used
                Section {
                    // Suggested parts chips
                    if let serviceType = record.serviceType {
                        let suggestions = serviceType.recommendedParts.filter { !partsUsed.contains($0) }
                        if !suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Suggested parts")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                FlowLayout(spacing: 6) {
                                    ForEach(suggestions, id: \.self) { part in
                                        Button {
                                            withAnimation(.snappy(duration: 0.2)) {
                                                partsUsed.append(part)
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.caption2)
                                                Text(part)
                                                    .font(.caption)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(Color(.systemGray6))
                                            .foregroundStyle(.primary)
                                            .clipShape(Capsule())
                                        }
                                        .accessibilityLabel("Add \(part)")
                                    }
                                }
                            }
                        }
                    }

                    // Added parts
                    ForEach(partsUsed, id: \.self) { part in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(part)
                                .font(.subheadline)
                            Spacer()
                            Button {
                                withAnimation(.snappy(duration: 0.2)) {
                                    partsUsed.removeAll { $0 == part }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .accessibilityLabel("Remove \(part)")
                        }
                    }

                    // Custom part entry
                    HStack {
                        Image(systemName: "wrench.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        TextField("Add custom part...", text: $newPartText)
                            .onSubmit { addCustomPart() }
                            .accessibilityLabel("Custom part name")
                        if !newPartText.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button {
                                addCustomPart()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(theme.accent)
                            }
                            .accessibilityLabel("Add part")
                        }
                    }
                } header: {
                    Text("Parts Used")
                }

                // MARK: - Oil Type (contextual)
                if record.serviceType?.involvesOil == true || record.serviceType == nil {
                    Section("Oil / Fluid Type") {
                        Button {
                            showOilTypePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
                                if oilType.isEmpty {
                                    Text("Select oil type")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(oilType)
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel("Oil type: \(oilType.isEmpty ? "not set" : oilType)")

                        if !oilType.isEmpty {
                            Button(role: .destructive) {
                                oilType = ""
                            } label: {
                                Text("Clear oil type")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("editServiceCancel")
                        .accessibilityLabel("Cancel editing")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.wrenchAmber)
                        .accessibilityIdentifier("editServiceSave")
                        .accessibilityLabel("Save changes")
                        .accessibilityHint("Saves updated service record")
                }
            }
            .onAppear {
                date = record.date
                mileage = record.mileage > 0 ? "\(record.mileage)" : ""
                cost = record.cost > 0 ? String(format: "%.2f", record.cost) : ""
                notes = record.notes
                partsUsed = record.partsUsed
                oilType = record.oilType
                shopName = record.shopName
            }
            .alert("Save Failed", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "An unexpected error occurred.")
            }
            .sheet(isPresented: $showOilTypePicker) {
                OilTypePickerView(selectedOilType: $oilType)
            }
        }
    }

    /// Recent shop names from this vehicle's history for quick selection
    private var recentShops: [String] {
        guard let vehicle = record.vehicle else { return [] }
        let shops = vehicle.safeServiceRecords
            .map(\.shopName)
            .filter { !$0.isEmpty }
        var seen = Set<String>()
        return shops.reversed().filter { seen.insert($0).inserted }
    }

    private func addCustomPart() {
        let trimmed = newPartText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !partsUsed.contains(trimmed) else { return }
        withAnimation(.snappy(duration: 0.2)) {
            partsUsed.append(trimmed)
        }
        newPartText = ""
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
        record.partsUsed = partsUsed
        record.oilType = oilType
        record.shopName = shopName.trimmingCharacters(in: .whitespaces)

        // Update vehicle lastUpdated
        record.vehicle?.lastUpdated = .now

        // Calendar sync — update event if enabled
        if CalendarStore.calendarSyncEnabled, let vehicle = record.vehicle {
            if !record.calendarEventId.isEmpty {
                let eventId = CalendarService.shared.updateServiceEvent(
                    identifier: record.calendarEventId,
                    serviceType: record.displayServiceType,
                    vehicleName: vehicle.displayName,
                    date: date,
                    cost: record.cost,
                    shopName: record.shopName,
                    notes: notes
                )
                if let eventId { record.calendarEventId = eventId }
            } else {
                let eventId = CalendarService.shared.addServiceEvent(
                    serviceType: record.displayServiceType,
                    vehicleName: vehicle.displayName,
                    date: date,
                    cost: record.cost,
                    shopName: record.shopName,
                    notes: notes
                )
                if let eventId { record.calendarEventId = eventId }
            }
        }

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
