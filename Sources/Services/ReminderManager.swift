import Foundation
import UserNotifications

@MainActor
final class ReminderManager {
    static let shared = ReminderManager()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("[WrenchLog] Notification auth failed: \(error)")
            return false
        }
    }

    /// Schedule reminders for all vehicles' upcoming services
    func scheduleReminders(for vehicles: [Vehicle]) async {
        center.removeAllPendingNotificationRequests()

        let authorized = await requestAuthorization()
        guard authorized else { return }

        for vehicle in vehicles where !vehicle.isArchived {
            scheduleVehicleReminders(vehicle)
        }
    }

    private func scheduleVehicleReminders(_ vehicle: Vehicle) {
        // Find last service of each type and schedule next
        let settings = UserSettings.shared

        for serviceType in ServiceType.allCases {
            guard serviceType.defaultMonthInterval > 0 else { continue }

            // Find the most recent record of this type
            let lastRecord = vehicle.serviceRecords
                .filter { $0.serviceTypeRaw == serviceType.rawValue }
                .sorted { $0.date > $1.date }
                .first

            // Calculate next due date
            let nextDueDate: Date
            if let last = lastRecord {
                nextDueDate = Calendar.current.date(
                    byAdding: .month,
                    value: serviceType.defaultMonthInterval,
                    to: last.date
                ) ?? Date()
            } else {
                // No record — remind in 1 month
                nextDueDate = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? Date()
            }

            // Only schedule future reminders
            guard nextDueDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(vehicle.displayName)"
            content.body = "\(serviceType.rawValue) is due. Tap to log it."
            content.sound = .default
            content.threadIdentifier = "vehicle-\(vehicle.id.uuidString)"

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour],
                from: nextDueDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let id = "reminder-\(vehicle.id.uuidString)-\(serviceType.rawValue)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
        }

        // Mileage-based reminder nudge — weekly "update your odometer"
        let nudgeContent = UNMutableNotificationContent()
        nudgeContent.title = "Update Mileage"
        nudgeContent.body = "How many \(settings.distanceUnit.label) on your \(vehicle.displayName)? Keep it current for accurate reminders."
        nudgeContent.sound = .default
        nudgeContent.threadIdentifier = "vehicle-\(vehicle.id.uuidString)"

        var weeklyComponents = DateComponents()
        weeklyComponents.weekday = 1 // Sunday
        weeklyComponents.hour = 10
        let weeklyTrigger = UNCalendarNotificationTrigger(dateMatching: weeklyComponents, repeats: true)
        let nudgeId = "mileage-nudge-\(vehicle.id.uuidString)"
        center.add(UNNotificationRequest(identifier: nudgeId, content: nudgeContent, trigger: weeklyTrigger))
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
