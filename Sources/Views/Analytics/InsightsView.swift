import SwiftUI
import SwiftData
import Charts

// MARK: - Insights View (Cross-Vehicle Statistics & Analytics)

struct InsightsView: View {
    @Query(filter: #Predicate<Vehicle> { !$0.isArchived },
           sort: \Vehicle.dateAdded, order: .reverse)
    private var vehicles: [Vehicle]

    @Environment(\.appTheme) private var theme
    private let settings = UserSettings.shared

    // MARK: - Aggregated Data

    private var allRecords: [ServiceRecord] {
        vehicles.flatMap(\.serviceRecords)
    }

    private var allFuelLogs: [FuelLog] {
        vehicles.flatMap(\.fuelLogs)
    }

    private var totalServiceCost: Double {
        allRecords.reduce(0) { $0 + $1.cost }
    }

    private var totalFuelCost: Double {
        allFuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    private var totalCost: Double {
        totalServiceCost + totalFuelCost
    }

    private var averageServiceCost: Double {
        let paid = allRecords.filter { $0.cost > 0 }
        guard !paid.isEmpty else { return 0 }
        return paid.reduce(0) { $0 + $1.cost } / Double(paid.count)
    }

    private var totalServiceCount: Int {
        allRecords.count
    }

    // MARK: - Monthly Spending (last 12 months)

    private var monthlySpending: [MonthlySpend] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).reversed().map { monthsAgo in
            let month = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
            let comps = calendar.dateComponents([.year, .month], from: month)
            let start = calendar.date(from: comps)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!

            let svc = allRecords
                .filter { $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.cost }
            let fuel = allFuelLogs
                .filter { $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.totalCost }

            return MonthlySpend(month: start, services: svc, fuel: fuel)
        }
    }

    // MARK: - Spending by Category

    private var categorySpending: [CategorySpend] {
        var map: [String: Double] = [:]
        for record in allRecords {
            map[record.categoryRaw, default: 0] += record.cost
        }
        return map.compactMap { key, value in
            guard value > 0, let cat = ServiceCategory(rawValue: key) else { return nil }
            return CategorySpend(category: cat, total: value)
        }.sorted { $0.total > $1.total }
    }

    // MARK: - Cost Per Vehicle

    private var vehicleCosts: [VehicleCost] {
        vehicles.map { v in
            let svc = v.serviceRecords.reduce(0) { $0 + $1.cost }
            let fuel = v.fuelLogs.reduce(0) { $0 + $1.totalCost }
            return VehicleCost(name: v.displayName, services: svc, fuel: fuel, vehicle: v)
        }.sorted { ($0.services + $0.fuel) > ($1.services + $1.fuel) }
    }

    // MARK: - Most Expensive Service Types (top 8)

    private var serviceTypeRanking: [ServiceTypeSpend] {
        var map: [String: (total: Double, count: Int, icon: String, color: Color)] = [:]
        for record in allRecords where record.cost > 0 {
            let key = record.displayServiceType
            let existing = map[key, default: (total: 0, count: 0, icon: record.icon, color: record.color)]
            map[key] = (total: existing.total + record.cost, count: existing.count + 1, icon: existing.icon, color: existing.color)
        }
        return map.map { key, value in
            ServiceTypeSpend(
                name: key, total: value.total, count: value.count,
                average: value.total / Double(value.count),
                icon: value.icon, color: value.color
            )
        }
        .sorted { $0.total > $1.total }
        .prefix(8)
        .map { $0 }
    }

    // MARK: - Maintenance Frequency (services per month)

    private var maintenanceFrequency: [FrequencyPoint] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).reversed().map { monthsAgo in
            let month = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
            let comps = calendar.dateComponents([.year, .month], from: month)
            let start = calendar.date(from: comps)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!

            let count = allRecords.filter { $0.date >= start && $0.date < end }.count
            return FrequencyPoint(month: start, count: count)
        }
    }

    // MARK: - Yearly vs Monthly Breakdown

    private var yearlyCosts: [YearlyCost] {
        let calendar = Calendar.current
        var yearMap: [Int: (services: Double, fuel: Double)] = [:]

        for record in allRecords {
            let year = calendar.component(.year, from: record.date)
            let existing = yearMap[year, default: (0, 0)]
            yearMap[year] = (services: existing.services + record.cost, fuel: existing.fuel)
        }
        for log in allFuelLogs {
            let year = calendar.component(.year, from: log.date)
            let existing = yearMap[year, default: (0, 0)]
            yearMap[year] = (services: existing.services, fuel: existing.fuel + log.totalCost)
        }

        return yearMap.map { YearlyCost(year: $0.key, services: $0.value.services, fuel: $0.value.fuel) }
            .sorted { $0.year > $1.year }
    }

    // MARK: - Cost Projection

    private var projectedAnnualCost: Double? {
        let calendar = Calendar.current
        let now = Date()
        let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now))!

        let ytdService = allRecords
            .filter { $0.date >= yearStart }
            .reduce(0) { $0 + $1.cost }
        let ytdFuel = allFuelLogs
            .filter { $0.date >= yearStart }
            .reduce(0) { $0 + $1.totalCost }
        let ytdTotal = ytdService + ytdFuel

        guard ytdTotal > 0 else { return nil }

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let daysInYear = calendar.range(of: .day, in: .year, for: now)?.count ?? 365

        return ytdTotal / Double(dayOfYear) * Double(daysInYear)
    }

    // MARK: - Fuel Efficiency Trend (all vehicles)

    private var fuelEfficiencyData: [EfficiencyPoint] {
        var points: [EfficiencyPoint] = []
        for vehicle in vehicles {
            let results = vehicle.fuelLogs.calculateEfficiency()
            for r in results {
                points.append(EfficiencyPoint(
                    date: r.date,
                    efficiency: r.efficiency(for: settings.efficiencyUnit),
                    vehicleName: vehicle.displayName
                ))
            }
        }
        return points.sorted { $0.date < $1.date }
    }

    // MARK: - Total Cost of Ownership Per Vehicle

    private var ownershipCosts: [OwnershipCost] {
        let calendar = Calendar.current
        return vehicles.map { v in
            let svc = v.serviceRecords.reduce(0) { $0 + $1.cost }
            let fuel = v.fuelLogs.reduce(0) { $0 + $1.totalCost }
            let total = svc + fuel

            let monthsOwned = max(1, calendar.dateComponents([.month], from: v.dateAdded, to: Date()).month ?? 1)

            return OwnershipCost(
                name: v.displayName,
                serviceCost: svc,
                fuelCost: fuel,
                totalCost: total,
                monthsOwned: monthsOwned,
                costPerMonth: total / Double(monthsOwned),
                serviceCount: v.serviceRecords.count
            )
        }.sorted { $0.totalCost > $1.totalCost }
    }

    // MARK: - Service Interval Compliance

    private var complianceRate: (compliant: Int, total: Int, percentage: Double) {
        var compliant = 0
        var total = 0

        for vehicle in vehicles {
            let reminders = ServiceReminderEngine.reminders(for: vehicle)
            for reminder in reminders {
                total += 1
                if reminder.urgency == .ok || reminder.urgency == .dueSoon {
                    compliant += 1
                }
            }
        }

        let pct = total > 0 ? Double(compliant) / Double(total) * 100.0 : 100.0
        return (compliant: compliant, total: total, percentage: pct)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if vehicles.isEmpty || (allRecords.isEmpty && allFuelLogs.isEmpty) {
                emptyState
            } else {
                insightsList
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "chart.bar.xaxis.ascending")
                    .font(.system(size: 40))
                    .foregroundStyle(theme.accent)
            }
            VStack(spacing: 8) {
                Text("No Data Yet")
                    .font(.title3.weight(.bold))
                Text("Log services and fuel to see\ninsights and spending trends.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
    }

    // MARK: - Insights List

    private var insightsList: some View {
        List {
            // Fleet summary cards
            fleetSummarySection

            // Cost projection
            if let projected = projectedAnnualCost {
                costProjectionSection(projected)
            }

            // Monthly spending chart
            monthlySpendingSection

            // Spending by category
            if !categorySpending.isEmpty {
                categorySection
            }

            // Cost per vehicle comparison
            if vehicleCosts.count >= 2 {
                vehicleComparisonSection
            }

            // Most expensive service types
            if !serviceTypeRanking.isEmpty {
                serviceTypeSection
            }

            // Maintenance frequency
            maintenanceFrequencySection

            // Yearly breakdown
            if !yearlyCosts.isEmpty {
                yearlyBreakdownSection
            }

            // Fuel efficiency trend
            if !fuelEfficiencyData.isEmpty {
                fuelEfficiencySection
            }

            // Total cost of ownership
            if !ownershipCosts.isEmpty {
                ownershipSection
            }

            // Service interval compliance
            complianceSection
        }
    }

    // MARK: - Fleet Summary Section

    private var fleetSummarySection: some View {
        Section {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    summaryCard(
                        title: "Total Spent",
                        value: settings.formatCost(totalCost),
                        icon: "dollarsign.circle.fill",
                        color: theme.accent
                    )
                    summaryCard(
                        title: "Services",
                        value: "\(totalServiceCount)",
                        icon: "wrench.fill",
                        color: .catEngine
                    )
                    summaryCard(
                        title: "Vehicles",
                        value: "\(vehicles.count)",
                        icon: "car.2.fill",
                        color: .catTires
                    )
                }

                HStack(spacing: 8) {
                    summaryCard(
                        title: "Avg/Service",
                        value: settings.formatCost(averageServiceCost),
                        icon: "equal.circle.fill",
                        color: .catFilters
                    )
                    summaryCard(
                        title: "Service Cost",
                        value: settings.formatCost(totalServiceCost),
                        icon: "wrench.and.screwdriver.fill",
                        color: .catEngine
                    )
                    summaryCard(
                        title: "Fuel Cost",
                        value: settings.formatCost(totalFuelCost),
                        icon: "fuelpump.fill",
                        color: .catFuel
                    )
                }
            }
        }
    }

    // MARK: - Cost Projection Section

    private func costProjectionSection(_ projected: Double) -> some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.catElectrical.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.catElectrical)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Cost Projection")
                        .font(.subheadline.weight(.semibold))
                    Text("At this rate, you'll spend **\(settings.formatCost(projected))** this year across all vehicles.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let calendar = Calendar.current
                    let yearStart = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
                    let ytdTotal = allRecords.filter { $0.date >= yearStart }.reduce(0) { $0 + $1.cost }
                        + allFuelLogs.filter { $0.date >= yearStart }.reduce(0) { $0 + $1.totalCost }

                    ProgressView(value: min(ytdTotal / projected, 1.0))
                        .tint(Color.catElectrical)

                    Text("\(settings.formatCost(ytdTotal)) spent so far this year")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Label("Projection", systemImage: "sparkles")
        }
    }

    // MARK: - Monthly Spending Section

    private var monthlySpendingSection: some View {
        Section("Monthly Spending (12 Months)") {
            let hasData = monthlySpending.contains { $0.services > 0 || $0.fuel > 0 }
            if hasData {
                Chart {
                    ForEach(monthlySpending) { item in
                        if item.services > 0 {
                            BarMark(
                                x: .value("Month", item.month, unit: .month),
                                y: .value("Cost", item.services)
                            )
                            .foregroundStyle(Color.catEngine)
                            .position(by: .value("Type", "Services"))
                        }
                        if item.fuel > 0 {
                            BarMark(
                                x: .value("Month", item.month, unit: .month),
                                y: .value("Cost", item.fuel)
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
                                Text(formatCompact(cost))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 200)

                // Monthly average
                let nonZero = monthlySpending.filter { $0.services + $0.fuel > 0 }
                if !nonZero.isEmpty {
                    let avg = nonZero.reduce(0) { $0 + $1.services + $1.fuel } / Double(nonZero.count)
                    HStack {
                        Text("Monthly Average")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(settings.formatCost(avg))
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(theme.accent)
                    }
                }
            } else {
                Text("No spending data in the last 12 months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        Section("Spending by Category") {
            Chart(categorySpending) { item in
                SectorMark(
                    angle: .value("Cost", item.total),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(item.category.color)
                .annotation(position: .overlay) {
                    if item.total / totalServiceCost > 0.08 {
                        Text("\(Int(item.total / totalServiceCost * 100))%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 200)

            ForEach(categorySpending) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.category.icon)
                        .font(.caption)
                        .foregroundStyle(item.category.color)
                        .frame(width: 22)
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

    // MARK: - Vehicle Comparison Section

    private var vehicleComparisonSection: some View {
        Section("Cost per Vehicle") {
            Chart(vehicleCosts) { item in
                BarMark(
                    x: .value("Vehicle", item.name),
                    y: .value("Cost", item.services)
                )
                .foregroundStyle(Color.catEngine)
                .position(by: .value("Type", "Services"))

                BarMark(
                    x: .value("Vehicle", item.name),
                    y: .value("Cost", item.fuel)
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
                            Text(formatCompact(cost))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    if let name = value.as(String.self) {
                        AxisValueLabel {
                            Text(abbreviateVehicleName(name))
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(height: 200)

            ForEach(vehicleCosts) { item in
                HStack(spacing: 10) {
                    Image(systemName: "car.fill")
                        .font(.caption)
                        .foregroundStyle(theme.accent)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline)
                        Text("Services: \(settings.formatCost(item.services)) · Fuel: \(settings.formatCost(item.fuel))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Text(settings.formatCost(item.services + item.fuel))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(theme.accent)
                }
            }
        }
    }

    // MARK: - Most Expensive Service Types

    private var serviceTypeSection: some View {
        Section("Most Expensive Service Types") {
            let maxTotal = serviceTypeRanking.first?.total ?? 1

            ForEach(serviceTypeRanking) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.icon)
                        .font(.caption)
                        .foregroundStyle(item.color)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.name)
                                .font(.subheadline)
                            Spacer()
                            Text(settings.formatCost(item.total))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(theme.accent)
                        }

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.color.opacity(0.25))
                                .frame(width: geo.size.width, height: 6)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(item.color)
                                        .frame(width: geo.size.width * (item.total / maxTotal), height: 6)
                                }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("\(item.count) service\(item.count == 1 ? "" : "s")")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Spacer()
                            Text("Avg: \(settings.formatCost(item.average))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Maintenance Frequency

    private var maintenanceFrequencySection: some View {
        Section("Maintenance Frequency") {
            let hasData = maintenanceFrequency.contains { $0.count > 0 }
            if hasData {
                Chart(maintenanceFrequency) { point in
                    LineMark(
                        x: .value("Month", point.month, unit: .month),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(theme.accent)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Month", point.month, unit: .month),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [theme.accent.opacity(0.2), theme.accent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", point.month, unit: .month),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(theme.accent)
                    .symbolSize(point.count > 0 ? 30 : 0)
                }
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
                        if let count = value.as(Int.self) {
                            AxisValueLabel {
                                Text("\(count)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 160)

                let totalCount = maintenanceFrequency.reduce(0) { $0 + $1.count }
                let activeMonths = maintenanceFrequency.filter { $0.count > 0 }.count
                let avgPerMonth = activeMonths > 0 ? Double(totalCount) / Double(activeMonths) : 0

                HStack {
                    Text("Avg Services/Month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", avgPerMonth))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(theme.accent)
                }
            } else {
                Text("No maintenance data in the last 12 months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Yearly Breakdown

    private var yearlyBreakdownSection: some View {
        Section("Yearly Cost Breakdown") {
            if yearlyCosts.count >= 2 {
                Chart(yearlyCosts) { item in
                    BarMark(
                        x: .value("Year", String(item.year)),
                        y: .value("Services", item.services)
                    )
                    .foregroundStyle(Color.catEngine)
                    .position(by: .value("Type", "Services"))

                    BarMark(
                        x: .value("Year", String(item.year)),
                        y: .value("Fuel", item.fuel)
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
                                Text(formatCompact(cost))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }

            ForEach(yearlyCosts) { item in
                HStack {
                    Text("\(String(item.year))")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(settings.formatCost(item.services + item.fuel))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(theme.accent)
                        HStack(spacing: 8) {
                            if item.services > 0 {
                                HStack(spacing: 3) {
                                    Circle().fill(Color.catEngine).frame(width: 6, height: 6)
                                    Text(settings.formatCost(item.services))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if item.fuel > 0 {
                                HStack(spacing: 3) {
                                    Circle().fill(Color.catFuel).frame(width: 6, height: 6)
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

    // MARK: - Fuel Efficiency Section

    private var fuelEfficiencySection: some View {
        Section("Fuel Efficiency Trend") {
            let uniqueVehicles = Set(fuelEfficiencyData.map(\.vehicleName))

            Chart(fuelEfficiencyData) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value(settings.efficiencyUnit.label, point.efficiency)
                )
                .foregroundStyle(by: .value("Vehicle", point.vehicleName))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value(settings.efficiencyUnit.label, point.efficiency)
                )
                .foregroundStyle(by: .value("Vehicle", point.vehicleName))
                .symbolSize(20)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month(.abbreviated).year(.twoDigits))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let v = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.0f", v))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 200)

            // Per-vehicle averages
            ForEach(Array(uniqueVehicles.sorted()), id: \.self) { name in
                let vehiclePoints = fuelEfficiencyData.filter { $0.vehicleName == name }
                let avg = vehiclePoints.reduce(0) { $0 + $1.efficiency } / Double(vehiclePoints.count)
                HStack {
                    Text(name)
                        .font(.caption)
                    Spacer()
                    Text("Avg: \(String(format: "%.1f", avg)) \(settings.efficiencyUnit.label)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Ownership Cost Section

    private var ownershipSection: some View {
        Section("Total Cost of Ownership") {
            ForEach(ownershipCosts) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(settings.formatCost(item.totalCost))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(theme.accent)
                    }

                    HStack(spacing: 16) {
                        ownershipStat(label: "Services", value: settings.formatCost(item.serviceCost), color: .catEngine)
                        ownershipStat(label: "Fuel", value: settings.formatCost(item.fuelCost), color: .catFuel)
                        ownershipStat(label: "Per Month", value: settings.formatCost(item.costPerMonth), color: .catElectrical)
                    }

                    HStack {
                        Text("\(item.serviceCount) services over \(item.monthsOwned) month\(item.monthsOwned == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Compliance Section

    private var complianceSection: some View {
        Section("Service Interval Compliance") {
            let compliance = complianceRate

            if compliance.total > 0 {
                HStack(spacing: 14) {
                    ZStack {
                        ProgressRing(
                            progress: compliance.percentage / 100.0,
                            lineWidth: 6,
                            color: complianceColor(compliance.percentage)
                        )
                        .frame(width: 56, height: 56)

                        Text("\(Int(compliance.percentage))%")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(complianceColor(compliance.percentage))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(complianceLabel(compliance.percentage))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(complianceColor(compliance.percentage))

                        Text("\(compliance.compliant) of \(compliance.total) service intervals on track")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if compliance.percentage < 100 {
                            let overdue = compliance.total - compliance.compliant
                            Text("\(overdue) interval\(overdue == 1 ? "" : "s") overdue or due now")
                                .font(.caption2)
                                .foregroundStyle(Color.wrenchRed)
                        }
                    }
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(Color.wrenchGreen)
                    Text("No tracked service intervals yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.caption2.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func ownershipStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption2.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 1000 {
            return "\(settings.currency.symbol)\(String(format: "%.0f", value / 1000))k"
        }
        return settings.formatCost(value)
    }

    private func abbreviateVehicleName(_ name: String) -> String {
        // "2020 Toyota Camry" → "'20 Camry"
        let parts = name.split(separator: " ")
        if parts.count >= 3, let year = Int(parts[0]) {
            let shortYear = "'\(String(year).suffix(2))"
            return "\(shortYear) \(parts.last ?? "")"
        }
        if name.count > 12 {
            return String(name.prefix(10)) + "…"
        }
        return name
    }

    private func complianceColor(_ pct: Double) -> Color {
        if pct >= 80 { return .wrenchGreen }
        if pct >= 50 { return .wrenchYellow }
        return .wrenchRed
    }

    private func complianceLabel(_ pct: Double) -> String {
        if pct >= 90 { return "Excellent" }
        if pct >= 75 { return "Good" }
        if pct >= 50 { return "Needs Attention" }
        return "Behind Schedule"
    }
}

// MARK: - Data Models

private struct MonthlySpend: Identifiable {
    let id = UUID()
    let month: Date
    let services: Double
    let fuel: Double
}

private struct CategorySpend: Identifiable {
    var id: String { category.rawValue }
    let category: ServiceCategory
    let total: Double
}

private struct VehicleCost: Identifiable {
    var id: String { name }
    let name: String
    let services: Double
    let fuel: Double
    let vehicle: Vehicle
}

private struct ServiceTypeSpend: Identifiable {
    var id: String { name }
    let name: String
    let total: Double
    let count: Int
    let average: Double
    let icon: String
    let color: Color
}

private struct FrequencyPoint: Identifiable {
    let id = UUID()
    let month: Date
    let count: Int
}

private struct YearlyCost: Identifiable {
    var id: Int { year }
    let year: Int
    let services: Double
    let fuel: Double
}

private struct EfficiencyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let efficiency: Double
    let vehicleName: String
}

private struct OwnershipCost: Identifiable {
    var id: String { name }
    let name: String
    let serviceCost: Double
    let fuelCost: Double
    let totalCost: Double
    let monthsOwned: Int
    let costPerMonth: Double
    let serviceCount: Int
}
