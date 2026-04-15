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
    @Environment(\.horizontalSizeClass) private var sizeClass

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
            color: Color.amber.shade500,
            cost: 0,
            mileage: 0,
            kind: .vehicleAdded
        ))

        return items.sorted { $0.date > $1.date }
    }

    /// Group entries by month-year
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

    @State private var tappedEntryID: UUID?

    var body: some View {
        List {
            if entries.isEmpty {
                ContentUnavailableView {
                    Label("No Maintenance History", systemImage: "wrench.and.screwdriver")
                } description: {
                    Text("Service records and fuel logs will appear here as a timeline.")
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(groupedEntries, id: \.key) { group in
                    Section(group.key) {
                        ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                            timelineRow(entry)
                                .staggeredAppear(index: index)
                        }
                    }
                }
            }
        }
        .navigationTitle("Timeline")
        .sensoryFeedback(.selection, trigger: tappedEntryID)
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
                    .shadow(color: entry.color.opacity(0.18), radius: 4, y: 2)
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
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.clear)
                .shadow(color: entry.color.opacity(0.08), radius: 6, y: 3)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            tappedEntryID = entry.id
        }
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
                .accessibilityHidden(true)
        case .fuel:
            Image(systemName: "fuelpump.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        case .vehicleAdded:
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(Color.amber.shade500)
                .accessibilityHidden(true)
        }
    }
}
