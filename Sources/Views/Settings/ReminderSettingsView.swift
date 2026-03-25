import SwiftUI

struct ReminderSettingsView: View {
    let vehicle: Vehicle
    @State private var overrides: [String: ReminderOverride] = [:]
    @State private var remindersEnabled = ReminderStore.remindersEnabled
    @State private var mileageNudge = ReminderStore.mileageNudgeEnabled
    @State private var vehicleRemindersOn = true
    @State private var quietHoursEnabled = ReminderStore.quietHoursEnabled
    @State private var quietStart = ReminderStore.quietHoursStart
    @State private var quietEnd = ReminderStore.quietHoursEnd
    @State private var dueSoonDays = ReminderStore.dueSoonThresholdDays
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private let settings = UserSettings.shared

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Master Toggles
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

                // MARK: - Per-Vehicle Toggle
                Section {
                    Toggle("Reminders for \(vehicle.displayName)", isOn: $vehicleRemindersOn)
                        .onChange(of: vehicleRemindersOn) { _, val in
                            ReminderStore.setVehicleReminderEnabled(val, for: vehicle.id)
                        }
                } footer: {
                    Text("Disable to silence all reminders for this vehicle without affecting others.")
                }

                // MARK: - Next Reminder Preview
                if let preview = ServiceReminderEngine.nextReminderPreview(for: vehicle) {
                    Section("Next Reminder") {
                        nextReminderRow(preview)
                    }
                }

                // MARK: - Driving Pace
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

                // MARK: - Quiet Hours
                Section {
                    Toggle("Quiet Hours", isOn: $quietHoursEnabled)
                        .onChange(of: quietHoursEnabled) { _, val in
                            ReminderStore.quietHoursEnabled = val
                        }

                    if quietHoursEnabled {
                        Picker("From", selection: $quietStart) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .onChange(of: quietStart) { _, val in
                            ReminderStore.quietHoursStart = val
                        }

                        Picker("Until", selection: $quietEnd) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .onChange(of: quietEnd) { _, val in
                            ReminderStore.quietHoursEnd = val
                        }
                    }
                } header: {
                    Text("Quiet Hours")
                } footer: {
                    if quietHoursEnabled {
                        Text("Notifications will be delayed until \(formatHour(quietEnd)) if they fall between \(formatHour(quietStart)) and \(formatHour(quietEnd)).")
                    } else {
                        Text("No notification timing restrictions. Enable to prevent late-night alerts.")
                    }
                }

                // MARK: - Due Soon Threshold
                Section {
                    Picker("Due Soon Threshold", selection: $dueSoonDays) {
                        Text("14 days").tag(14)
                        Text("21 days").tag(21)
                        Text("30 days").tag(30)
                        Text("45 days").tag(45)
                        Text("60 days").tag(60)
                    }
                    .onChange(of: dueSoonDays) { _, val in
                        ReminderStore.dueSoonThresholdDays = val
                    }
                } footer: {
                    Text("Services within this window are flagged as \"Due Soon\" with an orange badge.")
                }

                // MARK: - Service Intervals
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
            .scrollDismissesKeyboard(.interactively)
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
                    .accessibilityIdentifier("reminderSettingsDone")
                    .accessibilityLabel("Save reminder settings")
                }
            }
            .onAppear {
                overrides = ReminderStore.overrides(for: vehicle.id)
                vehicleRemindersOn = ReminderStore.isVehicleReminderEnabled(for: vehicle.id)
            }
        }
    }

    // MARK: - Next Reminder Preview Row

    @ViewBuilder
    private func nextReminderRow(_ preview: String) -> some View {
        let summary = ServiceReminderEngine.nextServiceSummary(for: vehicle)
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(badgeColor(for: summary?.urgency ?? .ok).opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "bell.badge.fill")
                    .font(.body)
                    .foregroundStyle(badgeColor(for: summary?.urgency ?? .ok))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Next reminder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(preview)
                    .font(.subheadline.weight(.medium))
            }

            Spacer()

            if let urgency = summary?.urgency {
                DueSoonBadge(urgency: urgency, compact: true)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next reminder: \(preview)")
    }

    // MARK: - Service Row

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

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    private func badgeColor(for urgency: ReminderUrgency) -> Color {
        switch urgency {
        case .overdue: .wrenchRed
        case .due: .wrenchAmber
        case .dueSoon: .wrenchYellow
        case .ok: .wrenchGreen
        }
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
