import Foundation
import OSLog
import UserNotifications

// MARK: - Notification Action Identifiers

enum ReminderAction {
    static let categoryId = "SERVICE_REMINDER"
    static let urgentCategoryId = "SERVICE_REMINDER_URGENT"
    static let markDone = "MARK_DONE"
    static let snooze = "SNOOZE"
}

// MARK: - Reminder Manager

@MainActor
final class ReminderManager: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    static let shared = ReminderManager()

    private let center = UNUserNotificationCenter.current()
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    override private init() {
        super.init()
        center.delegate = self
        registerCategories()
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            Logger.reminders.error("Notification auth failed: \(error)")
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    // MARK: - Categories & Actions

    private func registerCategories() {
        let markDone = UNNotificationAction(
            identifier: ReminderAction.markDone,
            title: "Mark as Done",
            options: []
        )
        let snooze = UNNotificationAction(
            identifier: ReminderAction.snooze,
            title: "Snooze 1 Week",
            options: []
        )

        // Standard category
        let category = UNNotificationCategory(
            identifier: ReminderAction.categoryId,
            actions: [markDone, snooze],
            intentIdentifiers: [],
            options: []
        )

        // Urgent category — same actions but shows as time-sensitive
        let urgentCategory = UNNotificationCategory(
            identifier: ReminderAction.urgentCategoryId,
            actions: [markDone, snooze],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category, urgentCategory])
    }

    // MARK: - Schedule Reminders (Batch)

    func scheduleReminders(for vehicles: [Vehicle]) async {
        center.removeAllPendingNotificationRequests()

        guard ReminderStore.remindersEnabled else { return }

        let authorized = await requestAuthorization()
        guard authorized else { return }

        // Use batch scheduling from the engine
        let batchItems = ServiceReminderEngine.batchNotificationItems(for: vehicles)

        for item in batchItems {
            let triggerDate = adjustForQuietHours(item.triggerDate)
            await scheduleNotification(
                vehicleId: item.vehicleId,
                vehicleName: item.vehicleName,
                serviceType: item.serviceType,
                triggerDate: triggerDate,
                urgency: item.urgency,
                displayDue: item.displayDue,
                isEscalated: item.isEscalated,
                suffix: item.isEscalated ? "escalated" : nil
            )
        }

        // Mileage update nudge per vehicle
        let appSettings = UserSettings.shared
        if ReminderStore.mileageNudgeEnabled {
            for vehicle in vehicles where !vehicle.isArchived {
                guard ReminderStore.isVehicleReminderEnabled(for: vehicle.id) else { continue }

                let nudgeContent = UNMutableNotificationContent()
                nudgeContent.title = "Update Mileage"
                nudgeContent.body = "How many \(appSettings.distanceUnit.label) on your \(vehicle.displayName)? Keep it current for accurate reminders."
                nudgeContent.sound = .default
                nudgeContent.threadIdentifier = "vehicle-\(vehicle.id.uuidString)"

                var weeklyComponents = DateComponents()
                weeklyComponents.weekday = 1
                weeklyComponents.hour = 10
                let trigger = UNCalendarNotificationTrigger(dateMatching: weeklyComponents, repeats: true)
                let id = "mileage-nudge-\(vehicle.id.uuidString)"
                try? await center.add(UNNotificationRequest(identifier: id, content: nudgeContent, trigger: trigger))
            }
        }
    }

    // MARK: - Quiet Hours

    /// Adjusts a trigger date to respect quiet hours.
    /// If the date falls inside the quiet window, pushes it to the end of quiet hours.
    private func adjustForQuietHours(_ date: Date) -> Date {
        guard ReminderStore.quietHoursEnabled else { return date }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let start = ReminderStore.quietHoursStart
        let end = ReminderStore.quietHoursEnd

        let isQuiet: Bool = if start > end {
            // Wraps midnight: e.g. 22–8
            hour >= start || hour < end
        } else if start < end {
            // Same-day range: e.g. 0–8
            hour >= start && hour < end
        } else {
            false
        }

        if isQuiet {
            // Push to quiet hours end on the same or next day
            var adjusted = calendar.dateComponents([.year, .month, .day], from: date)
            adjusted.hour = end
            adjusted.minute = 0
            adjusted.second = 0

            if let result = calendar.date(from: adjusted) {
                // If we'd go backward (quiet start is before midnight, hour is after midnight),
                // the date is already past quiet-end today — use end time as-is
                if result <= date {
                    // We're in the post-midnight portion; today's end time hasn't passed
                    // Actually if result <= date, quiet end already passed today → push to tomorrow
                    return calendar.date(byAdding: .day, value: 1, to: result) ?? date
                }
                return result
            }
        }

        return date
    }

    // MARK: - Notification Content

    private func makeContent(
        vehicleName: String,
        serviceType: ServiceType,
        vehicleId: UUID,
        urgency: ReminderUrgency,
        displayDue: String,
        isEscalated: Bool
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        if isEscalated {
            content.categoryIdentifier = ReminderAction.urgentCategoryId
            content.interruptionLevel = .timeSensitive
        } else {
            content.categoryIdentifier = ReminderAction.categoryId
        }

        switch urgency {
        case .overdue:
            if isEscalated {
                content.title = "🚨 \(vehicleName)"
                content.body = "\(serviceType.rawValue) is overdue (\(displayDue)). This needs attention now."
            } else {
                content.title = "⚠️ \(vehicleName)"
                content.body = "\(serviceType.rawValue) is overdue (\(displayDue)). Tap to log it."
            }
        case .due:
            content.title = "🔧 \(vehicleName)"
            content.body = "\(serviceType.rawValue) is due now. Time to schedule service."
        case .dueSoon:
            content.title = "\(vehicleName)"
            content.body = "\(serviceType.rawValue) coming up \(displayDue). Plan ahead."
        case .ok:
            content.title = "\(vehicleName)"
            content.body = "\(serviceType.rawValue) reminder."
        }

        content.sound = isEscalated ? .defaultCritical : .default
        content.threadIdentifier = "vehicle-service-\(serviceType.rawValue)"
        content.userInfo = [
            "serviceType": serviceType.rawValue,
            "vehicleName": vehicleName,
            "vehicleId": vehicleId.uuidString,
            "isEscalated": isEscalated,
        ]

        return content
    }

    private func scheduleNotification(
        vehicleId: UUID,
        vehicleName: String,
        serviceType: ServiceType,
        triggerDate: Date,
        urgency: ReminderUrgency,
        displayDue: String,
        isEscalated: Bool,
        suffix: String?
    ) async {
        guard triggerDate > Date() else { return }

        let content = makeContent(
            vehicleName: vehicleName,
            serviceType: serviceType,
            vehicleId: vehicleId,
            urgency: urgency,
            displayDue: displayDue,
            isEscalated: isEscalated
        )

        var components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: triggerDate
        )
        // Ensure we don't schedule in deep night if quiet hours somehow missed
        if (components.hour ?? 0) < 8 {
            components.hour = 9
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let idSuffix = suffix.map { "-\($0)" } ?? ""
        let id = "reminder-\(vehicleId.uuidString)-\(serviceType.rawValue)\(idSuffix)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func pendingCount() async -> Int {
        let pending = await center.pendingNotificationRequests()
        return pending.count
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let serviceType = userInfo["serviceType"] as? String ?? ""
        let vehicleIdStr = userInfo["vehicleId"] as? String ?? ""

        guard let vehicleId = UUID(uuidString: vehicleIdStr) else { return }

        switch response.actionIdentifier {
        case ReminderAction.markDone:
            ReminderStore.clearSnooze(for: vehicleId, serviceType: serviceType)

        case ReminderAction.snooze:
            let oneWeek = Calendar.current.safeDate(byAdding: .day, value: 7, to: .now)
            ReminderStore.setSnooze(for: vehicleId, serviceType: serviceType, until: oneWeek)

        default:
            break
        }
    }
}
