import SwiftUI

// MARK: - Maintenance Score Engine

/// Calculates a health score (0–100) for a vehicle based on how many services are up to date.
struct MaintenanceScoreEngine {

    @MainActor
    static func score(for vehicle: Vehicle) -> Int {
        let reminders = ServiceReminderEngine.reminders(for: vehicle)
        guard !reminders.isEmpty else {
            // No trackable services — score based on whether any services exist at all
            return vehicle.serviceRecords.isEmpty ? 50 : 85
        }

        var totalPoints = 0
        var maxPoints = 0

        for reminder in reminders {
            let weight: Int
            switch reminder.serviceType.category {
            case .engineFluids: weight = 3 // critical
            case .tiresBrakes: weight = 3
            case .filtersBelts: weight = 2
            case .electrical: weight = 2
            case .inspection: weight = 1
            case .custom: weight = 1
            }

            maxPoints += weight * 10

            switch reminder.urgency {
            case .ok:
                totalPoints += weight * 10
            case .dueSoon:
                totalPoints += weight * 7
            case .due:
                totalPoints += weight * 3
            case .overdue:
                totalPoints += 0
            }
        }

        guard maxPoints > 0 else { return 75 }
        return min(100, max(0, (totalPoints * 100) / maxPoints))
    }

    static func color(for score: Int) -> Color {
        switch score {
        case 80...100: .wrenchGreen
        case 60..<80: .wrenchYellow
        case 40..<60: .wrenchAmber
        default: .wrenchRed
        }
    }

    static func label(for score: Int) -> String {
        switch score {
        case 90...100: "Excellent"
        case 75..<90: "Good"
        case 60..<75: "Fair"
        case 40..<60: "Needs Attention"
        default: "Critical"
        }
    }

    static func icon(for score: Int) -> String {
        switch score {
        case 80...100: "heart.fill"
        case 60..<80: "heart"
        case 40..<60: "heart.slash"
        default: "heart.slash.fill"
        }
    }
}
