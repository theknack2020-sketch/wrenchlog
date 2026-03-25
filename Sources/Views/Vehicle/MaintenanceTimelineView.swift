import SwiftUI

// MARK: - Timeline Entry

struct TimelineEntry: Identifiable {
    let id: UUID
    let date: Date
    let title: String
    let detail: String
    let icon: String
    let color: Color
    let cost: Double
    let mileage: Int
    let kind: TimelineEntryKind
}

enum TimelineEntryKind {
    case service, fuel, vehicleAdded
}

// MARK: - Maintenance Timeline View

struct MaintenanceTimelineView: View {
    let vehicle: Vehicle
    private let settings = UserSettings.shared
    @Environment(\.appTheme) private var theme

    var entries: [TimelineEntry] {
        var items: [TimelineEntry] = []

        // Service records
        for record in vehicle.safeServiceRecords {
            items.append(TimelineEntry(
                id: record.id,
                date: record.date,
                title: record.displayServiceType,
                detail: record.notes,
                icon: record.icon,
                color: record.color,
                cost: record.cost,
                mileage: record.mileage,
                kind: .service
            ))
        }

        // Fuel logs
        for log in vehicle.safeFuelLogs {
            items.append(TimelineEntry(
                id: log.id,
                date: log.date,
                title: log.fuelType.isElectric ? "EV Charge" : "\(log.fuelType.rawValue) Fill-Up",
                detail: log.station.isEmpty ? "\(settings.formatVolume(log.volume, fuelType: log.fuelType))" : "\(log.station) · \(settings.formatVolume(log.volume, fuelType: log.fuelType))",
                icon: log.fuelType.icon,
                color: log.fuelType.color,
                cost: log.totalCost,
                mileage: log.mileage,
                kind: .fuel
            ))
        }

        // Vehicle added event
        items.append(TimelineEntry(
            id: vehicle.id,
            date: vehicle.dateAdded,
            title: "Vehicle Added",
            detail: vehicle.displayName,
            icon: "car.fill",
            color: .wrenchAmber,
            cost: 0,
            mileage: 0,
            kind: .vehicleAdded
        ))

        return items.sorted { $0.date > $1.date }
    }

    // Group entries by month-year
    var groupedEntries: [(key: String, entries: [TimelineEntry])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: entries) { entry in
            formatter.string(from: entry.date)
        }

        return grouped.map { (key: $0.key, entries: $0.value) }
            .sorted { first, second in
                guard let d1 = first.entries.first?.date, let d2 = second.entries.first?.date else { return false }
                return d1 > d2
            }
    }

    var body: some View {
        List {
            if entries.isEmpty {
                Section {
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.1))
                                .frame(width: 100, height: 100)
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 40))
                                .foregroundStyle(theme.accent)
                                .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5))
                        }
                        .accessibilityHidden(true)
                        VStack(spacing: 8) {
                            Text("No Timeline Yet")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                            Text("Service records and fuel logs will appear here as a timeline.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ForEach(groupedEntries, id: \.key) { group in
                    Section(group.key) {
                        ForEach(group.entries) { entry in
                            timelineRow(entry)
                        }
                    }
                }
            }
        }
        .navigationTitle("Timeline")
    }

    private func timelineRow(_ entry: TimelineEntry) -> some View {
        HStack(spacing: 12) {
            // Timeline connector
            VStack(spacing: 0) {
                Circle()
                    .fill(entry.color)
                    .frame(width: 10, height: 10)
            }

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                    .shadow(color: entry.color.opacity(0.15), radius: 3, y: 1)
                Image(systemName: entry.icon)
                    .font(.caption)
                    .foregroundStyle(entry.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 6) {
                    Text(entry.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if entry.mileage > 0 {
                        Text("· \(settings.formatMileage(entry.mileage))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !entry.detail.isEmpty {
                    Text(entry.detail)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Cost
            if entry.cost > 0 {
                Text(settings.formatCost(entry.cost))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(entry.color)
            }

            // Kind badge
            kindBadge(entry.kind)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(entry.date, format: .dateTime.month(.abbreviated).day())\(entry.cost > 0 ? ", \(settings.formatCost(entry.cost))" : "")")
    }

    @ViewBuilder
    private func kindBadge(_ kind: TimelineEntryKind) -> some View {
        switch kind {
        case .service:
            Image(systemName: "wrench.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .fuel:
            Image(systemName: "fuelpump.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .vehicleAdded:
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(Color.wrenchAmber)
        }
    }
}
