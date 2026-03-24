import Foundation

// MARK: - Reminder Override

struct ReminderOverride: Codable {
    var isEnabled: Bool = true
    var mileageInterval: Int? = nil
    var monthInterval: Int? = nil
}

// MARK: - Reminder Store

/// Persists reminder preferences and snooze state via UserDefaults.
struct ReminderStore {
    nonisolated(unsafe) private static let defaults = UserDefaults.standard

    static var remindersEnabled: Bool {
        get { defaults.object(forKey: "wl_reminders_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "wl_reminders_enabled") }
    }

    static var mileageNudgeEnabled: Bool {
        get { defaults.object(forKey: "wl_mileage_nudge") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "wl_mileage_nudge") }
    }

    // MARK: - Quiet Hours

    static var quietHoursEnabled: Bool {
        get { defaults.object(forKey: "wl_quiet_hours_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "wl_quiet_hours_enabled") }
    }

    /// Start of quiet period (hour, 0–23). Default 22 (10 PM).
    static var quietHoursStart: Int {
        get { defaults.object(forKey: "wl_quiet_hours_start") as? Int ?? 22 }
        set { defaults.set(newValue, forKey: "wl_quiet_hours_start") }
    }

    /// End of quiet period (hour, 0–23). Default 8 (8 AM).
    static var quietHoursEnd: Int {
        get { defaults.object(forKey: "wl_quiet_hours_end") as? Int ?? 8 }
        set { defaults.set(newValue, forKey: "wl_quiet_hours_end") }
    }

    // MARK: - Due Soon Threshold

    /// Days before due date to flag as "due soon". Default 30.
    static var dueSoonThresholdDays: Int {
        get { defaults.object(forKey: "wl_due_soon_days") as? Int ?? 30 }
        set { defaults.set(newValue, forKey: "wl_due_soon_days") }
    }

    // MARK: - Overdue Escalation

    /// Days after overdue before escalating to daily urgent reminders. Default 7.
    static var overdueEscalationDays: Int {
        get { defaults.object(forKey: "wl_overdue_escalation_days") as? Int ?? 7 }
        set { defaults.set(newValue, forKey: "wl_overdue_escalation_days") }
    }

    // MARK: - Per-Vehicle Toggle

    static func isVehicleReminderEnabled(for vehicleId: UUID) -> Bool {
        let key = "wl_vehicle_reminder_\(vehicleId.uuidString)"
        return defaults.object(forKey: key) as? Bool ?? true
    }

    static func setVehicleReminderEnabled(_ enabled: Bool, for vehicleId: UUID) {
        let key = "wl_vehicle_reminder_\(vehicleId.uuidString)"
        defaults.set(enabled, forKey: key)
    }

    // MARK: - Snooze

    static func snoozeDate(for vehicleId: UUID, serviceType: String) -> Date? {
        let key = "wl_snooze_\(vehicleId.uuidString)_\(serviceType)"
        return defaults.object(forKey: key) as? Date
    }

    static func setSnooze(for vehicleId: UUID, serviceType: String, until date: Date) {
        let key = "wl_snooze_\(vehicleId.uuidString)_\(serviceType)"
        defaults.set(date, forKey: key)
    }

    static func clearSnooze(for vehicleId: UUID, serviceType: String) {
        let key = "wl_snooze_\(vehicleId.uuidString)_\(serviceType)"
        defaults.removeObject(forKey: key)
    }

    // MARK: - Per-Vehicle Overrides

    static func overrides(for vehicleId: UUID) -> [String: ReminderOverride] {
        let key = "wl_reminder_overrides_\(vehicleId.uuidString)"
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: ReminderOverride].self, from: data) else {
            return [:]
        }
        return decoded
    }

    static func setOverride(_ override: ReminderOverride, for vehicleId: UUID, serviceType: ServiceType) {
        var all = overrides(for: vehicleId)
        all[serviceType.rawValue] = override
        let key = "wl_reminder_overrides_\(vehicleId.uuidString)"
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: key)
        }
    }

    static func resetOverrides(for vehicleId: UUID) {
        let key = "wl_reminder_overrides_\(vehicleId.uuidString)"
        defaults.removeObject(forKey: key)
    }

    // MARK: - Effective Values (override → default fallback)

    static func effectiveMileageInterval(for serviceType: ServiceType, vehicleId: UUID) -> Int {
        let ov = overrides(for: vehicleId)[serviceType.rawValue]
        return ov?.mileageInterval ?? serviceType.defaultMileageInterval
    }

    static func effectiveMonthInterval(for serviceType: ServiceType, vehicleId: UUID) -> Int {
        let ov = overrides(for: vehicleId)[serviceType.rawValue]
        return ov?.monthInterval ?? serviceType.defaultMonthInterval
    }

    static func isEnabled(for serviceType: ServiceType, vehicleId: UUID) -> Bool {
        let ov = overrides(for: vehicleId)[serviceType.rawValue]
        return ov?.isEnabled ?? true
    }
}
