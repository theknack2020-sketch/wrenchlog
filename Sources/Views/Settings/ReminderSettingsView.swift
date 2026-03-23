import SwiftUI

struct ReminderSettingsView: View {
    let vehicle: Vehicle
    @State private var overrides: [String: ReminderOverride] = [:]
    @State private var remindersEnabled = ReminderStore.remindersEnabled
    @State private var mileageNudge = ReminderStore.mileageNudgeEnabled
    @Environment(\.dismiss) private var dismiss

    private let settings = UserSettings.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Service Reminders", isOn: $remindersEnabled)
                        .onChange(of: remindersEnabled) { _, val in
                            ReminderStore.remindersEnabled = val
                        }
                    Toggle("Weekly Mileage Nudge", isOn: $mileageNudge)
                        .onChange(of: mileageNudge) { _, val in
                            ReminderStore.mileageNudgeEnabled = val
                        }
                } footer: {
                    Text("Get a weekly reminder to update your odometer for accurate service tracking.")
                }

                if let pace = ServiceReminderEngine.drivingPace(for: vehicle) {
                    Section("Driving Pace") {
                        HStack {
                            Image(systemName: "gauge.open.with.needle.33percent")
                                .foregroundStyle(Color.wrenchAmber)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("~\(Int(pace.milesPerMonth).formatted()) \(settings.distanceUnit.label)/month")
                                    .font(.subheadline.weight(.medium))
                                Text("Based on \(pace.dataPoints) service records")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                ForEach(ServiceCategory.allCases.filter({ $0 != .custom }), id: \.self) { category in
                    let types = ServiceType.types(for: category).filter {
                        $0.defaultMileageInterval > 0 || $0.defaultMonthInterval > 0
                    }
                    if !types.isEmpty {
                        Section(category.rawValue) {
                            ForEach(types, id: \.self) { serviceType in
                                reminderRow(for: serviceType)
                            }
                        }
                    }
                }

                Section {
                    Button("Reset All to Defaults", role: .destructive) {
                        ReminderStore.resetOverrides(for: vehicle.id)
                        overrides = [:]
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Save all overrides
                        for (key, override) in overrides {
                            if let st = ServiceType(rawValue: key) {
                                ReminderStore.setOverride(override, for: vehicle.id, serviceType: st)
                            }
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel("Save reminder settings")
                }
            }
            .onAppear {
                overrides = ReminderStore.overrides(for: vehicle.id)
            }
        }
    }

    @ViewBuilder
    private func reminderRow(for serviceType: ServiceType) -> some View {
        let key = serviceType.rawValue
        let currentOverride = overrides[key] ?? ReminderOverride()
        let isEnabled = currentOverride.isEnabled
        let mileage = currentOverride.mileageInterval ?? serviceType.defaultMileageInterval
        let months = currentOverride.monthInterval ?? serviceType.defaultMonthInterval

        DisclosureGroup {
            // Enable/disable
            Toggle("Enabled", isOn: binding(for: key, keyPath: \.isEnabled))

            // Mileage interval
            if serviceType.defaultMileageInterval > 0 || mileage > 0 {
                HStack {
                    Text("Every")
                    Spacer()
                    TextField("mi", value: mileageBinding(for: key, default: serviceType.defaultMileageInterval), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text(settings.distanceUnit.label)
                        .foregroundStyle(.secondary)
                }
            }

            // Month interval
            if serviceType.defaultMonthInterval > 0 || months > 0 {
                HStack {
                    Text("Every")
                    Spacer()
                    TextField("mo", value: monthBinding(for: key, default: serviceType.defaultMonthInterval), format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("months")
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: serviceType.uniqueIcon)
                    .foregroundStyle(isEnabled ? serviceType.color : .secondary)
                    .frame(width: 24)
                Text(serviceType.rawValue)
                    .font(.subheadline)
                Spacer()
                if !isEnabled {
                    Text("Off")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    summaryLabel(mileage: mileage, months: months)
                }
            }
        }
    }

    private func summaryLabel(mileage: Int, months: Int) -> some View {
        let unit = settings.distanceUnit.label
        var parts: [String] = []
        if mileage > 0 { parts.append("\(mileage.formatted()) \(unit)") }
        if months > 0 { parts.append("\(months)mo") }
        return Text(parts.joined(separator: " / "))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // MARK: - Bindings

    private func binding(for key: String, keyPath: WritableKeyPath<ReminderOverride, Bool>) -> Binding<Bool> {
        Binding(
            get: { (overrides[key] ?? ReminderOverride())[keyPath: keyPath] },
            set: { newValue in
                var ov = overrides[key] ?? ReminderOverride()
                ov[keyPath: keyPath] = newValue
                overrides[key] = ov
            }
        )
    }

    private func mileageBinding(for key: String, default defaultVal: Int) -> Binding<Int> {
        Binding(
            get: { overrides[key]?.mileageInterval ?? defaultVal },
            set: { newValue in
                var ov = overrides[key] ?? ReminderOverride()
                ov.mileageInterval = max(0, newValue)
                overrides[key] = ov
            }
        )
    }

    private func monthBinding(for key: String, default defaultVal: Int) -> Binding<Int> {
        Binding(
            get: { overrides[key]?.monthInterval ?? defaultVal },
            set: { newValue in
                var ov = overrides[key] ?? ReminderOverride()
                ov.monthInterval = max(0, newValue)
                overrides[key] = ov
            }
        )
    }
}
