import Foundation
import UserNotifications

// MARK: - Notification Action Identifiers

enum ReminderAction {
    static let categoryId = "SERVICE_REMINDER"
    static let markDone = "MARK_DONE"
    static let snooze = "SNOOZE"
}

// MARK: - Reminder Manager

@MainActor
final class ReminderManager: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    static let shared = ReminderManager()

    private let center = UNUserNotificationCenter.current()
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private override init() {
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
            print("[WrenchLog] Notification auth failed: \(error)")
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
        let category = UNNotificationCategory(
            identifier: ReminderAction.categoryId,
            actions: [markDone, snooze],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Schedule Reminders

    func scheduleReminders(for vehicles: [Vehicle]) async {
        center.removeAllPendingNotificationRequests()

        guard ReminderStore.remindersEnabled else { return }

        let authorized = await requestAuthorization()
        guard authorized else { return }

        for vehicle in vehicles where !vehicle.isArchived {
            scheduleVehicleReminders(vehicle)
        }
    }

    private func scheduleVehicleReminders(_ vehicle: Vehicle) {
        let reminders = ServiceReminderEngine.reminders(for: vehicle)
        let pace = ServiceReminderEngine.drivingPace(for: vehicle)
        let appSettings = UserSettings.shared

        for reminder in reminders {
            // Skip snoozed items — reschedule at snooze-end
            if let snoozeEnd = ReminderStore.snoozeDate(for: vehicle.id, serviceType: reminder.id),
               snoozeEnd > Date() {
                scheduleNotification(
                    vehicleId: vehicle.id,
                    vehicleName: vehicle.displayName,
                    serviceType: reminder.serviceType,
                    triggerDate: snoozeEnd,
                    urgency: reminder.urgency,
                    displayDue: reminder.displayDue,
                    suffix: "snoozed"
                )
                continue
            }

            // Already overdue or due — notify tomorrow at 9am
            if reminder.urgency == .overdue || reminder.urgency == .due {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                var trigger = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
                trigger.hour = 9

                let content = makeContent(
                    vehicleName: vehicle.displayName,
                    serviceType: reminder.serviceType,
                    vehicleId: vehicle.id,
                    urgency: reminder.urgency,
                    displayDue: reminder.displayDue
                )
                let id = "reminder-\(vehicle.id.uuidString)-\(reminder.id)"
                let req = UNNotificationRequest(
                    identifier: id,
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: false)
                )
                center.add(req)
                continue
            }

            // Due soon / OK — use engine-calculated notification date (pace-aware)
            if let notifyDate = ServiceReminderEngine.notificationDate(
                for: reminder,
                pace: pace,
                vehicleCurrentMileage: vehicle.currentMileage
            ) {
                scheduleNotification(
                    vehicleId: vehicle.id,
                    vehicleName: vehicle.displayName,
                    serviceType: reminder.serviceType,
                    triggerDate: notifyDate,
                    urgency: reminder.urgency,
                    displayDue: reminder.displayDue,
                    suffix: nil
                )
            }
        }

        // Mileage update nudge
        if ReminderStore.mileageNudgeEnabled {
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
            center.add(UNNotificationRequest(identifier: id, content: nudgeContent, trigger: trigger))
        }
    }

    // MARK: - Notification Content

    private func makeContent(
        vehicleName: String,
        serviceType: ServiceType,
        vehicleId: UUID,
        urgency: ReminderUrgency,
        displayDue: String
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = ReminderAction.categoryId

        switch urgency {
        case .overdue:
            content.title = "⚠️ \(vehicleName)"
            content.body = "\(serviceType.rawValue) is overdue (\(displayDue)). Tap to log it."
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

        content.sound = .default
        content.threadIdentifier = "vehicle-service-\(serviceType.rawValue)"
        content.userInfo = [
            "serviceType": serviceType.rawValue,
            "vehicleName": vehicleName,
            "vehicleId": vehicleId.uuidString
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
        suffix: String?
    ) {
        guard triggerDate > Date() else { return }

        let content = makeContent(
            vehicleName: vehicleName,
            serviceType: serviceType,
            vehicleId: vehicleId,
            urgency: urgency,
            displayDue: displayDue
        )

        var components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour],
            from: triggerDate
        )
        if components.hour == nil || components.hour! < 8 {
            components.hour = 9
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let idSuffix = suffix.map { "-\($0)" } ?? ""
        let id = "reminder-\(vehicleId.uuidString)-\(serviceType.rawValue)\(idSuffix)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
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
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
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
            let oneWeek = Calendar.current.date(byAdding: .day, value: 7, to: .now)!
            ReminderStore.setSnooze(for: vehicleId, serviceType: serviceType, until: oneWeek)

        default:
            break
        }
    }
}
