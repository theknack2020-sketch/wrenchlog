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
