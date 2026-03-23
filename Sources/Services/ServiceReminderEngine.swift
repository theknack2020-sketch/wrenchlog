import Foundation

// MARK: - Reminder Urgency

enum ReminderUrgency: String, Comparable {
    case overdue
    case due
    case dueSoon
    case ok

    private var sortOrder: Int {
        switch self {
        case .overdue: 0
        case .due: 1
        case .dueSoon: 2
        case .ok: 3
        }
    }

    static func < (lhs: ReminderUrgency, rhs: ReminderUrgency) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Driving Pace

struct DrivingPace {
    let milesPerMonth: Double
    let dataPoints: Int
}

// MARK: - Service Reminder

struct ServiceReminder: Identifiable {
    let id: String               // serviceType.rawValue
    let serviceType: ServiceType
    let urgency: ReminderUrgency
    let displayDue: String
    let nextDueDate: Date?
    let nextDueMileage: Int?
    let lastServiceDate: Date?
}

// MARK: - Service Reminder Engine

struct ServiceReminderEngine {

    @MainActor
    static func reminders(for vehicle: Vehicle) -> [ServiceReminder] {
        let calendar = Calendar.current
        var items: [ServiceReminder] = []

        for serviceType in ServiceType.allCases {
            let vehicleId = vehicle.id
            let mileageInterval = ReminderStore.effectiveMileageInterval(for: serviceType, vehicleId: vehicleId)
            let monthInterval = ReminderStore.effectiveMonthInterval(for: serviceType, vehicleId: vehicleId)
            let isEnabled = ReminderStore.isEnabled(for: serviceType, vehicleId: vehicleId)

            guard isEnabled else { continue }
            guard monthInterval > 0 || mileageInterval > 0 else { continue }

            let lastRecord = vehicle.serviceRecords
                .filter { $0.serviceTypeRaw == serviceType.rawValue }
                .sorted { $0.date > $1.date }
                .first

            var urgency: ReminderUrgency = .ok
            var displayDue = ""
            var nextDueDate: Date? = nil
            var nextDueMileage: Int? = nil

            // Time-based check
            if monthInterval > 0, let last = lastRecord {
                let due = calendar.date(byAdding: .month, value: monthInterval, to: last.date) ?? Date()
                nextDueDate = due
                let daysUntil = calendar.dateComponents([.day], from: Date(), to: due).day ?? 0

                if daysUntil < 0 {
                    urgency = .overdue
                    displayDue = "\(abs(daysUntil)) days overdue"
                } else if daysUntil == 0 {
                    urgency = .due
                    displayDue = "Due today"
                } else if daysUntil <= 30 {
                    urgency = .dueSoon
                    let formatter = RelativeDateTimeFormatter()
                    formatter.unitsStyle = .abbreviated
                    displayDue = formatter.localizedString(for: due, relativeTo: Date())
                } else {
                    let formatter = RelativeDateTimeFormatter()
                    formatter.unitsStyle = .abbreviated
                    displayDue = formatter.localizedString(for: due, relativeTo: Date())
                }
            }

            // Mileage-based check
            if mileageInterval > 0, let last = lastRecord {
                let dueMileage = last.mileage + mileageInterval
                nextDueMileage = dueMileage
                let milesRemaining = dueMileage - vehicle.currentMileage

                if milesRemaining <= 0 && urgency != .overdue {
                    urgency = .overdue
                    displayDue = "\(abs(milesRemaining)) mi overdue"
                } else if milesRemaining <= 500 && urgency == .ok {
                    urgency = .dueSoon
                }
            }

            // Smart pace check — if pace predicts mileage due within 30 days
            if let pace = drivingPace(for: vehicle),
               let dueMileage = nextDueMileage,
               urgency == .ok {
                let milesRemaining = dueMileage - vehicle.currentMileage
                if milesRemaining > 0 {
                    let daysToMileageDue = Double(milesRemaining) / (pace.milesPerMonth / 30.0)
                    if daysToMileageDue <= 30 {
                        urgency = .dueSoon
                    }
                }
            }

            // Skip if no record and no useful default
            if lastRecord == nil && monthInterval > 0 {
                continue
            }

            if urgency != .ok || lastRecord != nil {
                items.append(ServiceReminder(
                    id: serviceType.rawValue,
                    serviceType: serviceType,
                    urgency: urgency,
                    displayDue: displayDue,
                    nextDueDate: nextDueDate,
                    nextDueMileage: nextDueMileage,
                    lastServiceDate: lastRecord?.date
                ))
            }
        }

        return items.sorted { $0.urgency < $1.urgency }
    }

    /// Estimate driving pace (miles per month) based on service records
    @MainActor
    static func drivingPace(for vehicle: Vehicle) -> DrivingPace? {
        let records = vehicle.serviceRecords
            .filter { $0.mileage > 0 }
            .sorted { $0.date < $1.date }

        guard records.count >= 2,
              let first = records.first,
              let last = records.last else {
            return nil
        }

        let calendar = Calendar.current
        let months = calendar.dateComponents([.month], from: first.date, to: last.date).month ?? 1
        let milesDriven = last.mileage - first.mileage

        guard months > 0, milesDriven > 0 else { return nil }
        return DrivingPace(
            milesPerMonth: Double(milesDriven) / Double(months),
            dataPoints: records.count
        )
    }

    /// Calculate when to send notification (some days before due)
    static func notificationDate(
        for reminder: ServiceReminder,
        pace: DrivingPace?,
        vehicleCurrentMileage: Int
    ) -> Date? {
        if let dueDate = reminder.nextDueDate {
            return Calendar.current.date(byAdding: .day, value: -7, to: dueDate)
        }

        if let dueMileage = reminder.nextDueMileage, let pace = pace, pace.milesPerMonth > 0 {
            let milesRemaining = dueMileage - vehicleCurrentMileage
            guard milesRemaining > 0 else { return nil }
            let monthsRemaining = Double(milesRemaining) / pace.milesPerMonth
            let daysRemaining = monthsRemaining * 30.0
            return Calendar.current.date(byAdding: .day, value: Int(daysRemaining) - 7, to: Date())
        }

        return nil
    }

    /// Quick summary of the next service due for a vehicle row display
    @MainActor
    static func nextServiceSummary(for vehicle: Vehicle) -> (type: String, urgency: ReminderUrgency, text: String)? {
        let all = reminders(for: vehicle)
        guard let next = all.first else { return nil }
        return (type: next.serviceType.rawValue, urgency: next.urgency, text: next.displayDue)
    }
}
