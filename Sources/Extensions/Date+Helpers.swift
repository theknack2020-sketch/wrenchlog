import Foundation

extension Date {
    /// Returns the date normalized to start-of-day in the current calendar.
    /// Use this for service/fuel dates to avoid timezone drift.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns a relative description like "2 days ago", "today", etc.
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}

// MARK: - Safe Calendar Helpers

extension Calendar {
    /// Safe alternative to `calendar.date(byAdding:value:to:)!`.
    /// Returns the original date if the operation fails (instead of crashing).
    func safeDate(byAdding component: Component, value: Int, to date: Date) -> Date {
        self.date(byAdding: component, value: value, to: date) ?? date
    }

    /// Safe alternative to `calendar.date(from:)!`.
    /// Returns `.now` if the operation fails (instead of crashing).
    func safeDate(from components: DateComponents) -> Date {
        date(from: components) ?? .now
    }
}
