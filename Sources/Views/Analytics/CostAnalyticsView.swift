import SwiftUI
import Charts

struct CostAnalyticsView: View {
    let vehicle: Vehicle
    private let settings = UserSettings.shared
    private let store = StoreManager.shared

    @Environment(\.appTheme) private var theme
    @State private var chartAnimationProgress: Double = 0
    @State private var selectedMonthIndex: Int?
    @State private var showProPrompt = false

    var records: [ServiceRecord] {
        vehicle.safeServiceRecords.sorted { $0.date > $1.date }
    }

    var fuelLogs: [FuelLog] {
        vehicle.safeFuelLogs.sorted { $0.date > $1.date }
    }

    var totalServiceCost: Double {
        records.reduce(0) { $0 + $1.cost }
    }

    var totalFuelCost: Double {
        fuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    var totalCost: Double {
        totalServiceCost + totalFuelCost
    }

    // Cost by category (services only)
    var categoryBreakdown: [(category: ServiceCategory, total: Double, color: Color)] {
        var map: [String: Double] = [:]
        for record in records {
            map[record.categoryRaw, default: 0] += record.cost
        }
        return map.compactMap { key, value in
            guard value > 0, let cat = ServiceCategory(rawValue: key) else { return nil }
            return (category: cat, total: value, color: cat.color)
        }.sorted { $0.total > $1.total }
    }

    // Service vs Fuel split for donut
    var costSplit: [(label: String, total: Double, color: Color)] {
        var result: [(String, Double, Color)] = []
        if totalServiceCost > 0 { result.append(("Services", totalServiceCost, .catEngine)) }
        if totalFuelCost > 0 { result.append(("Fuel", totalFuelCost, .catFuel)) }
        return result
    }

    // Monthly spending (services + fuel, last 12 months)
    var monthlySpending: [(month: Date, services: Double, fuel: Double)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).reversed().map { monthsAgo in
            let month = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            let svcTotal = records.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.cost }
            let fuelTotal = fuelLogs.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.totalCost }
            return (month: start, services: svcTotal, fuel: fuelTotal)
        }
    }

    // Yearly cost of ownership
    var yearlyCosts: [(year: Int, services: Double, fuel: Double)] {
        let calendar = Calendar.current
        var yearMap: [Int: (services: Double, fuel: Double)] = [:]

        for record in records {
            let year = calendar.component(.year, from: record.date)
            let existing = yearMap[year, default: (services: 0, fuel: 0)]
            yearMap[year] = (services: existing.services + record.cost, fuel: existing.fuel)
        }
        for log in fuelLogs {
            let year = calendar.component(.year, from: log.date)
            let existing = yearMap[year, default: (services: 0, fuel: 0)]
            yearMap[year] = (services: existing.services, fuel: existing.fuel + log.totalCost)
        }

        return yearMap.map { (year: $0.key, services: $0.value.services, fuel: $0.value.fuel) }
            .sorted { $0.year > $1.year }
    }

    // Year-over-year comparison
    var yearOverYear: (currentYear: Int, currentTotal: Double, previousTotal: Double, changePercent: Double)? {
        guard yearlyCosts.count >= 2 else { return nil }
        let sorted = yearlyCosts.sorted { $0.year > $1.year }
        let current = sorted[0]
        let previous = sorted[1]
        let currentTotal = current.services + current.fuel
        let previousTotal = previous.services + previous.fuel
        guard previousTotal > 0 else { return nil }
        let change = ((currentTotal - previousTotal) / previousTotal) * 100.0
        return (currentYear: current.year, currentTotal: currentTotal, previousTotal: previousTotal, changePercent: change)
    }

    // Fuel efficiency summary
    var efficiencyResults: [FuelEfficiencyResult] {
        vehicle.safeFuelLogs.calculateEfficiency()
    }

    var averageEfficiency: Double? {
        let results = efficiencyResults
        guard !results.isEmpty else { return nil }
        let sum = results.reduce(0.0) { $0 + $1.efficiency(for: settings.efficiencyUnit) }
        return sum / Double(results.count)
    }

    var averageCostPerDistance: Double? {
        let results = efficiencyResults
        guard !results.isEmpty else { return nil }
        let sum = results.reduce(0.0) { $0 + $1.costPerDistance(for: settings.distanceUnit) }
        return sum / Double(results.count)
    }

    var body: some View {
        Group {
            if records.isEmpty && fuelLogs.isEmpty {
                costAnalyticsEmptyState
            } else {
                costAnalyticsList
            }
        }
        .navigationTitle("Cost Analytics")
        .onAppear {
            HapticManager.shared.light()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.1)) {
                chartAnimationProgress = 1.0
            }
        }
    }

    // MARK: - Empty State

    private var costAnalyticsEmptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.bar.xaxis.ascending")
                    .font(.system(size: 40))
                    .foregroundStyle(theme.accent)
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5))
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("No Cost Data Yet")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("Add services and fuel logs to see spending analysis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    // MARK: - Cost Analytics List

    private var costAnalyticsList: some View {
        List {
            // Summary with gradient header
            Section {
                VStack(spacing: 8) {
                    // Gradient header banner
                    HStack(spacing: 8) {
                        Image(systemName: "chart.pie.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Cost Overview")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(settings.formatCost(totalCost))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: theme.headerGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .shadow(color: theme.accent.opacity(0.2), radius: 6, x: 0, y: 3)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Cost overview: total \(settings.formatCost(totalCost))")

                    HStack(spacing: 8) {
                    ProgressRing(
                        progress: min(totalCost / max(totalCost * 1.2, 1), 1.0),
                        lineWidth: 6,
                        color: .wrenchAmber
                    )
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "dollarsign")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.wrenchAmber)
                    }
                    .shadow(color: Color.wrenchAmber.opacity(0.2), radius: 6, x: 0, y: 0)

                    statCard(title: "Total Cost", value: settings.formatCost(totalCost), color: .wrenchAmber)
                        .statPop(index: 0)
                    statCard(title: "Services", value: settings.formatCost(totalServiceCost), color: .catEngine)
                        .statPop(index: 1)
                    statCard(title: "Fuel", value: settings.formatCost(totalFuelCost), color: .catFuel)
                        .statPop(index: 2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total cost \(settings.formatCost(totalCost)), services \(settings.formatCost(totalServiceCost)), fuel \(settings.formatCost(totalFuelCost))")

                }

                if averageEfficiency != nil || averageCostPerDistance != nil {
                    HStack(spacing: 8) {
                        if let avg = averageEfficiency {
                            statCard(title: "Avg \(settings.efficiencyUnit.label)", value: String(format: "%.1f", avg), color: .catTires)
                        }
                        if let cpd = averageCostPerDistance {
                            statCard(title: "Cost/\(settings.distanceUnit.label)", value: settings.formatCostPerDistance(cpd), color: .wrenchYellow)
                        }
                        if let avgSvc = averageServiceCost {
                            statCard(title: "Avg/Service", value: settings.formatCost(avgSvc), color: .catFilters)
                        }
                    }
                }
            }

            // Year-over-year comparison
            if let yoy = yearOverYear {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(yoy.changePercent >= 0
                                      ? Color.wrenchRed.opacity(0.12)
                                      : Color.wrenchGreen.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: yoy.changePercent >= 0
                                  ? "arrow.up.right"
                                  : "arrow.down.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(yoy.changePercent >= 0 ? Color.wrenchRed : Color.wrenchGreen)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Year-over-Year")
                                    .font(.subheadline.weight(.semibold))
                                Text(String(format: "%+.1f%%", yoy.changePercent))
                                    .font(.caption.weight(.bold).monospacedDigit())
                                    .foregroundStyle(yoy.changePercent >= 0 ? Color.wrenchRed : Color.wrenchGreen)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        (yoy.changePercent >= 0 ? Color.wrenchRed : Color.wrenchGreen).opacity(0.12),
                                        in: Capsule()
                                    )
                            }
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(String(yoy.currentYear))")
                                        .font(.caption2).foregroundStyle(.tertiary)
                                    Text(settings.formatCost(yoy.currentTotal))
                                        .font(.caption.weight(.semibold).monospacedDigit())
                                }
                                Image(systemName: "arrow.left")
                                    .font(.caption2).foregroundStyle(.tertiary)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(String(yoy.currentYear - 1))")
                                        .font(.caption2).foregroundStyle(.tertiary)
                                    Text(settings.formatCost(yoy.previousTotal))
                                        .font(.caption.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Label("Comparison", systemImage: "arrow.left.arrow.right")
                }
            }

            // Service vs Fuel split
            if costSplit.count == 2 {
                Section("Services vs Fuel") {
                    Chart(costSplit, id: \.label) { item in
                        SectorMark(
                            angle: .value("Cost", item.total * chartAnimationProgress),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(item.color)
                        .annotation(position: .overlay) {
                            if item.total / totalCost > 0.05 {
                                Text("\(Int(item.total / totalCost * 100))%")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(height: 180)
                    .chartReveal()

                    ForEach(costSplit, id: \.label) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
                            Text(item.label)
                                .font(.subheadline)
                            Spacer()
                            Text(settings.formatCost(item.total))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Category breakdown donut (services)
            if !categoryBreakdown.isEmpty {
                Section("Service Spending by Category") {
                    Chart(categoryBreakdown, id: \.category) { item in
                        SectorMark(
                            angle: .value("Cost", item.total * chartAnimationProgress),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(item.color)
                        .annotation(position: .overlay) {
                            if item.total / totalServiceCost > 0.1 {
                                Text("\(Int(item.total / totalServiceCost * 100))%")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(height: 200)

                    ForEach(categoryBreakdown, id: \.category) { item in
                        HStack(spacing: 10) {
                            ProgressRing(
                                progress: totalServiceCost > 0 ? (item.total / totalServiceCost) * chartAnimationProgress : 0,
                                lineWidth: 3,
                                color: item.color
                            )
                            .frame(width: 22, height: 22)
                            Text(item.category.rawValue)
                                .font(.subheadline)
                            Spacer()
                            Text(settings.formatCost(item.total))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Monthly spending (stacked bar chart: services + fuel)
            Section("Monthly Spending") {
                let hasData = monthlySpending.contains { $0.services > 0 || $0.fuel > 0 }
                if hasData {
                    Chart {
                        ForEach(monthlySpending, id: \.month) { item in
                            if item.services > 0 {
                                BarMark(
                                    x: .value("Month", item.month, unit: .month),
                                    y: .value("Cost", item.services * chartAnimationProgress)
                                )
                                .foregroundStyle(Color.catEngine)
                                .position(by: .value("Type", "Services"))
                            }
                            if item.fuel > 0 {
                                BarMark(
                                    x: .value("Month", item.month, unit: .month),
                                    y: .value("Cost", item.fuel * chartAnimationProgress)
                                )
                                .foregroundStyle(Color.catFuel)
                                .position(by: .value("Type", "Fuel"))
                            }
                        }
                    }
                    .chartForegroundStyleScale([
                        "Services": Color.catEngine,
                        "Fuel": Color.catFuel
                    ])
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month, count: 2)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.month(.abbreviated))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            if let cost = value.as(Double.self) {
                                AxisValueLabel {
                                    Text(settings.formatCost(cost))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                } else {
                    Text("No spending data yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Yearly total cost of ownership with chart
            if !yearlyCosts.isEmpty {
                Section("Yearly Cost of Ownership") {
                    if yearlyCosts.count >= 2 {
                        Chart(yearlyCosts, id: \.year) { item in
                            BarMark(
                                x: .value("Year", String(item.year)),
                                y: .value("Services", item.services * chartAnimationProgress)
                            )
                            .foregroundStyle(Color.catEngine)
                            .position(by: .value("Type", "Services"))

                            BarMark(
                                x: .value("Year", String(item.year)),
                                y: .value("Fuel", item.fuel * chartAnimationProgress)
                            )
                            .foregroundStyle(Color.catFuel)
                            .position(by: .value("Type", "Fuel"))
                        }
                        .chartForegroundStyleScale([
                            "Services": Color.catEngine,
                            "Fuel": Color.catFuel
                        ])
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                if let cost = value.as(Double.self) {
                                    AxisValueLabel {
                                        Text(settings.formatCost(cost))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .frame(height: 180)
                    }

                    ForEach(yearlyCosts, id: \.year) { item in
                        HStack {
                            Text("\(String(item.year))")
                                .font(.subheadline.weight(.semibold).monospacedDigit())

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(settings.formatCost(item.services + item.fuel))
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Color.wrenchAmber)

                                HStack(spacing: 8) {
                                    if item.services > 0 {
                                        HStack(spacing: 3) {
                                            Circle()
                                                .fill(Color.catEngine)
                                                .frame(width: 6, height: 6)
                                            Text(settings.formatCost(item.services))
                                                .font(.caption2.monospacedDigit())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    if item.fuel > 0 {
                                        HStack(spacing: 3) {
                                            Circle()
                                                .fill(Color.catFuel)
                                                .frame(width: 6, height: 6)
                                            Text(settings.formatCost(item.fuel))
                                                .font(.caption2.monospacedDigit())
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            // Recent services
            if !records.isEmpty {
                Section("Recent Services") {
                    ForEach(records.prefix(10)) { record in
                        ServiceRecordRow(record: record)
                    }
                }
            }
        }
    }

    private var averageServiceCost: Double? {
        let paid = records.filter { $0.cost > 0 }
        guard !paid.isEmpty else { return nil }
        return paid.reduce(0) { $0 + $1.cost } / Double(paid.count)
    }

    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
