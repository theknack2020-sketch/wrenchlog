import SwiftData
import SwiftUI

// MARK: - Weekly Summary View

struct WeeklySummaryView: View {
    @Query(filter: #Predicate<Vehicle> { !$0.isArchived },
           sort: \Vehicle.dateAdded, order: .reverse)
    private var vehicles: [Vehicle]

    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private let settings = UserSettings.shared
    @State private var isLoaded = false

    // MARK: - Week Boundaries (Mon–Sun)

    private var weekStart: Date {
        let calendar = Calendar.current
        let now = Date()
        var comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        comps.weekday = 2 // Monday
        return calendar.date(from: comps) ?? now
    }

    private var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    private var dateRangeText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let startStr = fmt.string(from: weekStart)
        let endStr = fmt.string(from: weekEnd)
        return "\(startStr) – \(endStr)"
    }

    // MARK: - This Week's Data

    private var weekServices: [ServiceRecord] {
        let start = weekStart
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
        return vehicles.flatMap(\.safeServiceRecords)
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date > $1.date }
    }

    private var weekFuelLogs: [FuelLog] {
        let start = weekStart
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
        return vehicles.flatMap(\.safeFuelLogs)
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date > $1.date }
    }

    private var totalSpent: Double {
        let svc = weekServices.reduce(0) { $0 + $1.cost }
        let fuel = weekFuelLogs.reduce(0) { $0 + $1.totalCost }
        return svc + fuel
    }

    /// Streak: consecutive days (ending today or yesterday) that had at least one action
    private var streakDays: Int {
        let calendar = Calendar.current
        let allDates: [Date] = (vehicles.flatMap(\.safeServiceRecords).map(\.date)
            + vehicles.flatMap(\.safeFuelLogs).map(\.date))
            .map { calendar.startOfDay(for: $0) }
        let uniqueDays = Set(allDates).sorted(by: >)
        guard !uniqueDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.safeDate(byAdding: .day, value: -1, to: today)

        // Streak must start from today or yesterday
        guard let first = uniqueDays.first,
              first == today || first == yesterday else { return 0 }

        var streak = 1
        var expected = calendar.safeDate(byAdding: .day, value: -1, to: first)
        for day in uniqueDays.dropFirst() {
            if day == expected {
                streak += 1
                expected = calendar.safeDate(byAdding: .day, value: -1, to: day)
            } else {
                break
            }
        }
        return streak
    }

    private var totalActions: Int {
        weekServices.count + weekFuelLogs.count
    }

    // MARK: - Activity Timeline

    private var timelineItems: [TimelineItem] {
        var items: [TimelineItem] = []

        for record in weekServices {
            items.append(TimelineItem(
                date: record.date,
                icon: record.icon,
                color: record.color,
                title: record.displayServiceType,
                subtitle: record.vehicle?.displayName ?? "Unknown",
                cost: record.cost
            ))
        }

        for log in weekFuelLogs {
            items.append(TimelineItem(
                date: log.date,
                icon: log.fuelType.icon,
                color: log.fuelType.color,
                title: "\(log.fuelType.rawValue) Fill-Up",
                subtitle: log.vehicle?.displayName ?? "Unknown",
                cost: log.totalCost
            ))
        }

        return items.sorted { $0.date > $1.date }
    }

    // MARK: - Upcoming Reminders (next 7 days)

    private var upcomingReminders: [(vehicle: Vehicle, type: String, urgency: ReminderUrgency, text: String)] {
        vehicles.compactMap { vehicle in
            guard let summary = ServiceReminderEngine.nextServiceSummary(for: vehicle) else { return nil }
            guard summary.urgency == .due || summary.urgency == .dueSoon || summary.urgency == .overdue else { return nil }
            return (vehicle: vehicle, type: summary.type, urgency: summary.urgency, text: summary.text)
        }
    }

    // MARK: - Motivational Message

    private var motivationalMessage: String {
        switch totalActions {
        case 0:
            "Quiet week! Check if any services are due."
        case 1 ... 2:
            "Staying on track! Your vehicles appreciate it."
        default:
            "Amazing week! You're a maintenance pro. 🏆"
        }
    }

    // MARK: - Body

    var body: some View {
        List {
            // Header
            Section {
                headerBanner
            }

            // Quick Stats
            Section {
                quickStatsGrid
            } header: {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accent)
                        .frame(width: 3, height: 16)
                    Label("Quick Stats", systemImage: "chart.bar.fill")
                        .font(.system(.headline, design: .rounded))
                }
            }

            // Activity Timeline
            Section {
                if timelineItems.isEmpty {
                    emptyTimelineRow
                } else {
                    ForEach(Array(timelineItems.enumerated()), id: \.element.id) { index, item in
                        timelineRow(item, index: index)
                    }
                }
            } header: {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.catEngine)
                        .frame(width: 3, height: 16)
                    Label("Activity", systemImage: "clock.fill")
                        .font(.system(.headline, design: .rounded))
                }
            }

            // Maintenance Health
            if !vehicles.isEmpty {
                Section {
                    ForEach(Array(vehicles.enumerated()), id: \.element.id) { index, vehicle in
                        healthRow(vehicle, index: index)
                    }
                } header: {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.Status.success.shade500)
                            .frame(width: 3, height: 16)
                        Label("Maintenance Health", systemImage: "heart.fill")
                            .font(.system(.headline, design: .rounded))
                    }
                }
            }

            // Next Up
            if !upcomingReminders.isEmpty {
                Section {
                    ForEach(Array(upcomingReminders.enumerated()), id: \.offset) { index, reminder in
                        reminderRow(reminder, index: index)
                    }
                } header: {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.accent)
                            .frame(width: 3, height: 16)
                        Label("Next Up", systemImage: "bell.badge.fill")
                            .font(.system(.headline, design: .rounded))
                    }
                }
            }

            // Motivational message
            Section {
                HStack(spacing: 12) {
                    Image(systemName: totalActions >= 3 ? "trophy.fill" : totalActions > 0 ? "hand.thumbsup.fill" : "zzz")
                        .font(.title3)
                        .foregroundStyle(theme.accent)
                        .accessibilityHidden(true)

                    Text(motivationalMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .floatIn(delay: 0.4)
            }
        }
        .navigationTitle("This Week")
        .accessibilityIdentifier("weeklySummaryView")
        .redacted(reason: isLoaded ? [] : .placeholder)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { isLoaded = true }
            }
        }
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("This Week")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text(dateRangeText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Text("\(totalActions) action\(totalActions == 1 ? "" : "s")")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2), in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: theme.headerGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: theme.accent.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .floatIn(delay: 0.05)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("This week, \(dateRangeText), \(totalActions) actions")
    }

    // MARK: - Quick Stats Grid (2x2)

    private var quickStatsGrid: some View {
        let columns = sizeClass == .regular
            ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 8) {
            quickStatCard(
                title: "Services",
                value: "\(weekServices.count)",
                icon: "wrench.fill",
                color: .catEngine,
                index: 0
            )
            quickStatCard(
                title: "Fuel Logs",
                value: "\(weekFuelLogs.count)",
                icon: "fuelpump.fill",
                color: .catFuel,
                index: 1
            )
            quickStatCard(
                title: "Spent",
                value: settings.formatCost(totalSpent),
                icon: "dollarsign.circle.fill",
                color: theme.accent,
                index: 2
            )
            quickStatCard(
                title: "Streak",
                value: "\(streakDays) day\(streakDays == 1 ? "" : "s")",
                icon: "flame.fill",
                color: streakDays >= 3 ? Color.Status.success.shade500 : Color.Status.warning.shade500,
                index: 3
            )
        }
    }

    private func quickStatCard(title: String, value: String, icon: String, color: Color, index: Int) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.1), lineWidth: 0.5)
                )
        )
        .shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .statPop(index: index)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Activity Timeline

    private var emptyTimelineRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.body)
                .foregroundStyle(.tertiary)
            Text("No activity this week")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func timelineRow(_ item: TimelineItem, index: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: item.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(item.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if item.cost > 0 {
                Text(settings.formatCost(item.cost))
                    .font(.system(.caption, design: .rounded, weight: .bold).monospacedDigit())
                    .foregroundStyle(item.color)
            }
        }
        .padding(.vertical, 2)
        .staggeredAppear(index: index)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.subtitle), \(item.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())\(item.cost > 0 ? ", \(settings.formatCost(item.cost))" : "")")
    }

    // MARK: - Maintenance Health

    private func healthRow(_ vehicle: Vehicle, index: Int) -> some View {
        let score = MaintenanceScoreEngine.score(for: vehicle)
        let color = MaintenanceScoreEngine.color(for: score)
        let label = MaintenanceScoreEngine.label(for: score)
        let icon = MaintenanceScoreEngine.icon(for: score)

        return HStack(spacing: 12) {
            ProgressRing(
                progress: Double(score) / 100.0,
                lineWidth: 4,
                color: color
            )
            .frame(width: 40, height: 40)
            .overlay {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(vehicle.displayName)
                    .font(.subheadline.weight(.medium))
                Text(label)
                    .font(.caption)
                    .foregroundStyle(color)
            }

            Spacer()

            Text("\(score)%")
                .font(.system(.subheadline, design: .rounded, weight: .bold).monospacedDigit())
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
        .staggeredAppear(index: index)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vehicle.displayName), health \(score) percent, \(label)")
    }

    // MARK: - Reminder Row

    private func reminderRow(_ reminder: (vehicle: Vehicle, type: String, urgency: ReminderUrgency, text: String), index: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(colorForUrgency(reminder.urgency).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: reminder.urgency == .overdue ? "exclamationmark.triangle.fill" : "bell.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(colorForUrgency(reminder.urgency))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.type)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    Text(reminder.vehicle.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !reminder.text.isEmpty {
                        Text("· \(reminder.text)")
                            .font(.caption)
                            .foregroundStyle(colorForUrgency(reminder.urgency))
                    }
                }
            }

            Spacer()

            DueSoonBadge(urgency: reminder.urgency, compact: true)
        }
        .padding(.vertical, 2)
        .staggeredAppear(index: index)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reminder.type), \(reminder.vehicle.displayName), \(reminder.urgency.label)")
    }

    // MARK: - Helpers

    private func colorForUrgency(_ urgency: ReminderUrgency) -> Color {
        switch urgency {
        case .ok: Color.Status.success.shade500
        case .dueSoon: Color.Status.warning.shade500
        case .due: theme.accent
        case .overdue: Color.Status.error.shade500
        }
    }
}

// MARK: - Timeline Item Model

private struct TimelineItem: Identifiable {
    let id = UUID()
    let date: Date
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let cost: Double
}
