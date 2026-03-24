import EventKit
import Foundation

/// Manages iOS Calendar integration for service records via EventKit.
/// Events are created in a dedicated "WrenchLog" calendar for clean organization.
@MainActor
final class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private let calendarTitle = "WrenchLog"

    // MARK: - Authorization

    enum AuthStatus {
        case authorized, denied, notDetermined, restricted
    }

    var authorizationStatus: AuthStatus {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        case .writeOnly: return .restricted
        @unknown default: return .notDetermined
        }
    }

    /// Request calendar access. Returns true if granted.
    func requestAccess() async -> Bool {
        do {
            if #available(iOS 17.0, *) {
                return try await eventStore.requestFullAccessToEvents()
            } else {
                return try await eventStore.requestAccess(to: .event)
            }
        } catch {
            print("[WrenchLog] Calendar access request failed: \(error)")
            return false
        }
    }

    // MARK: - WrenchLog Calendar

    /// Find or create a dedicated WrenchLog calendar for service events.
    private func wrenchLogCalendar() -> EKCalendar? {
        // Look for existing WrenchLog calendar
        let calendars = eventStore.calendars(for: .event)
        if let existing = calendars.first(where: { $0.title == calendarTitle }) {
            return existing
        }

        // Create new calendar
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarTitle

        // Use the default calendar source (usually iCloud or Local)
        if let defaultSource = eventStore.defaultCalendarForNewEvents?.source {
            calendar.source = defaultSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            calendar.source = localSource
        } else {
            print("[WrenchLog] No calendar source available")
            return nil
        }

        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return calendar
        } catch {
            print("[WrenchLog] Failed to create WrenchLog calendar: \(error)")
            return nil
        }
    }

    // MARK: - Add Event

    /// Create a calendar event for a service record. Returns the event identifier or nil on failure.
    @discardableResult
    func addServiceEvent(
        serviceType: String,
        vehicleName: String,
        date: Date,
        cost: Double,
        shopName: String,
        notes: String
    ) -> String? {
        guard authorizationStatus == .authorized else { return nil }
        guard let calendar = wrenchLogCalendar() else { return nil }

        let event = EKEvent(eventStore: eventStore)
        event.title = "🔧 \(serviceType) — \(vehicleName)"
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date
        event.isAllDay = true
        event.calendar = calendar

        // Build structured notes
        var eventNotes = "Vehicle: \(vehicleName)"
        if cost > 0 {
            eventNotes += "\nCost: \(String(format: "%.2f", cost))"
        }
        if !shopName.isEmpty {
            eventNotes += "\nShop: \(shopName)"
        }
        if !notes.isEmpty {
            eventNotes += "\n\n\(notes)"
        }
        eventNotes += "\n\nLogged by WrenchLog"
        event.notes = eventNotes

        if !shopName.isEmpty {
            event.location = shopName
        }

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("[WrenchLog] Failed to save calendar event: \(error)")
            return nil
        }
    }

    // MARK: - Remove Event

    /// Remove a previously created calendar event by its identifier.
    func removeEvent(identifier: String) {
        guard !identifier.isEmpty else { return }
        guard authorizationStatus == .authorized else { return }

        guard let event = eventStore.event(withIdentifier: identifier) else { return }
        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            print("[WrenchLog] Failed to remove calendar event: \(error)")
        }
    }

    // MARK: - Update Event

    /// Update an existing calendar event. Returns the (possibly new) event identifier.
    @discardableResult
    func updateServiceEvent(
        identifier: String,
        serviceType: String,
        vehicleName: String,
        date: Date,
        cost: Double,
        shopName: String,
        notes: String
    ) -> String? {
        guard authorizationStatus == .authorized else { return nil }

        // Remove old event first, then create new one
        // (EKEvent updates can be flaky with identifier changes)
        removeEvent(identifier: identifier)
        return addServiceEvent(
            serviceType: serviceType,
            vehicleName: vehicleName,
            date: date,
            cost: cost,
            shopName: shopName,
            notes: notes
        )
    }

    // MARK: - Bulk Sync

    /// Sync all service records for a set of vehicles to the calendar.
    /// Adds events for records that don't have a calendar event yet.
    /// Returns the number of events created.
    @discardableResult
    func syncAllRecords(vehicles: [Vehicle]) -> Int {
        guard authorizationStatus == .authorized else { return 0 }
        var count = 0
        for vehicle in vehicles {
            for record in vehicle.safeServiceRecords {
                if record.calendarEventId.isEmpty {
                    if let eventId = addServiceEvent(
                        serviceType: record.displayServiceType,
                        vehicleName: vehicle.displayName,
                        date: record.date,
                        cost: record.cost,
                        shopName: record.shopName,
                        notes: record.notes
                    ) {
                        record.calendarEventId = eventId
                        count += 1
                    }
                }
            }
        }
        return count
    }

    private init() {}
}
