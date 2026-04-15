import Charts
import SwiftData
import SwiftUI

// MARK: - Insights View (Cross-Vehicle Statistics & Analytics)

struct InsightsView: View {
    @Query(filter: #Predicate<Vehicle> { !$0.isArchived },
           sort: \Vehicle.dateAdded, order: .reverse)
    private var vehicles: [Vehicle]

    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private let settings = UserSettings.shared
    private let store = StoreManager.shared

    @State private var chartAnimationProgress: Double = 0
    @State private var donutScale: CGFloat = 0.4
    @State private var selectedMonthlySpend: MonthlySpend?
    @State private var selectedComplianceVehicle: Vehicle?
    @State private var showProPrompt = false
    @State private var isLoaded = false

    // MARK: - Aggregated Data

    private var allRecords: [ServiceRecord] {
        vehicles.flatMap(\.safeServiceRecords)
    }

    private var allFuelLogs: [FuelLog] {
        vehicles.flatMap(\.safeFuelLogs)
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
        return (0 ..< 12).reversed().map { monthsAgo in
            let month = calendar.safeDate(byAdding: .month, value: -monthsAgo, to: now)
            let comps = calendar.dateComponents([.year, .month], from: month)
            let start = calendar.safeDate(from: comps)
            let end = calendar.safeDate(byAdding: .month, value: 1, to: start)

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
            let svc = v.safeServiceRecords.reduce(0) { $0 + $1.cost }
            let fuel = v.safeFuelLogs.reduce(0) { $0 + $1.totalCost }
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
        .map(\.self)
    }

    // MARK: - Maintenance Frequency (services per month)

    private var maintenanceFrequency: [FrequencyPoint] {
        let calendar = Calendar.current
        let now = Date()
        return (0 ..< 12).reversed().map { monthsAgo in
            let month = calendar.safeDate(byAdding: .month, value: -monthsAgo, to: now)
            let comps = calendar.dateComponents([.year, .month], from: month)
            let start = calendar.safeDate(from: comps)
            let end = calendar.safeDate(byAdding: .month, value: 1, to: start)

            let count = allRecords.count(where: { $0.date >= start && $0.date < end })
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
        let yearStart = calendar.safeDate(from: calendar.dateComponents([.year], from: now))

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
            let results = vehicle.safeFuelLogs.calculateEfficiency()
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

    // MARK: - Per-Vehicle Fuel Efficiency Averages

    private var vehicleEfficiencyComparison: [VehicleEfficiency] {
        vehicles.compactMap { v in
            let results = v.safeFuelLogs.calculateEfficiency()
            guard !results.isEmpty else { return nil }
            let effValues = results.map { $0.efficiency(for: settings.efficiencyUnit) }
            let avg = effValues.reduce(0, +) / Double(effValues.count)
            let best: Double
            let worst: Double
            switch settings.efficiencyUnit {
            case .mpg:
                best = effValues.max() ?? avg
                worst = effValues.min() ?? avg
            case .l100km:
                best = effValues.min() ?? avg // lower is better
                worst = effValues.max() ?? avg
            }
            return VehicleEfficiency(
                name: v.displayName,
                average: avg,
                best: best,
                worst: worst,
                fillUps: results.count
            )
        }.sorted { $0.average > $1.average }
    }

    // MARK: - Total Cost of Ownership Per Vehicle

    private var ownershipCosts: [OwnershipCost] {
        let calendar = Calendar.current
        return vehicles.map { v in
            let svc = v.safeServiceRecords.reduce(0) { $0 + $1.cost }
            let fuel = v.safeFuelLogs.reduce(0) { $0 + $1.totalCost }
            let total = svc + fuel

            let monthsOwned = max(1, calendar.dateComponents([.month], from: v.dateAdded, to: Date()).month ?? 1)

            return OwnershipCost(
                name: v.displayName,
                serviceCost: svc,
                fuelCost: fuel,
                totalCost: total,
                monthsOwned: monthsOwned,
                costPerMonth: total / Double(monthsOwned),
                serviceCount: v.safeServiceRecords.count
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

    // MARK: - Per-Vehicle Compliance Scores

    private var vehicleComplianceScores: [VehicleComplianceScore] {
        vehicles.compactMap { v in
            let reminders = ServiceReminderEngine.reminders(for: v)
            guard !reminders.isEmpty else { return nil }
            let compliant = reminders.count(where: { $0.urgency == .ok || $0.urgency == .dueSoon })
            let pct = Double(compliant) / Double(reminders.count) * 100.0
            let healthScore = MaintenanceScoreEngine.score(for: v)
            return VehicleComplianceScore(
                name: v.displayName,
                vehicle: v,
                compliancePercent: pct,
                healthScore: healthScore,
                compliant: compliant,
                total: reminders.count,
                overdue: reminders.count(where: { $0.urgency == .overdue })
            )
        }.sorted { $0.healthScore > $1.healthScore }
    }

    // MARK: - Year-over-Year Change

    private var yearOverYearChange: (currentYear: Int, currentTotal: Double, previousTotal: Double, changePercent: Double)? {
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
        .onAppear {
            HapticManager.shared.light()
            // Shimmer loading effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { isLoaded = true }
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.1)) {
                chartAnimationProgress = 1.0
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.2)) {
                donutScale = 1.0
            }
        }
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
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundStyle(theme.accent)
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5))
            }
            .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text("No Insights Yet")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Text("Add services and fuel logs to unlock\nspending trends, projections, and analysis.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("Insights get smarter as you log more data.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
            Spacer()
        }
    }

    // MARK: - Insights List

    private var insightsList: some View {
        List {
            // Fleet summary cards — FREE
            fleetSummarySection

            // Service interval compliance — FREE
            complianceSection

            // Everything below is PRO-only
            if store.isPro {
                // Cost projection
                if let projected = projectedAnnualCost {
                    costProjectionSection(projected)
                }

                // Year-over-year change
                if let yoy = yearOverYearChange {
                    yearOverYearSection(yoy)
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

                // Fuel efficiency comparison across vehicles
                if vehicleEfficiencyComparison.count >= 2 {
                    fuelEfficiencyComparisonSection
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

                // Maintenance compliance score per vehicle
                if !vehicleComplianceScores.isEmpty {
                    complianceScoreSection
                }
            } else {
                // PRO teaser sections for free users
                proLockedChartsSection
            }
        }
        .redacted(reason: isLoaded ? [] : .placeholder)
        .fullScreenCover(isPresented: $showProPrompt) {
            ProUpgradeView()
        }
    }

    // MARK: - Pro Locked Charts Teaser

    private var proLockedChartsSection: some View {
        Section {
            VStack(spacing: 16) {
                proTeaser(title: "Monthly Spending", icon: "chart.bar.fill", description: "See 12-month spending trends")
                proTeaser(title: "Category Breakdown", icon: "chart.pie.fill", description: "Know where your money goes")
                proTeaser(title: "Vehicle Comparison", icon: "car.2.fill", description: "Compare costs across vehicles")
                proTeaser(title: "Fuel Efficiency", icon: "gauge.open.with.needle.33percent", description: "Track efficiency trends")
                proTeaser(title: "Cost of Ownership", icon: "dollarsign.circle.fill", description: "Total ownership costs")

                Button {
                    TelemetryService.paywallShown(source: "insights_pro_button")
                    showProPrompt = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                        Text("Unlock All Charts with Pro")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [theme.accent, Color(red: 0.85, green: 0.55, blue: 0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .shadow(color: theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .pressable()
                .accessibilityIdentifier("insightsUnlockPro")
            }
            .padding(.vertical, 4)
            .glassBackground(cornerRadius: 14)
        } header: {
            Label("Pro Analytics", systemImage: "lock.fill")
        }
    }

    private func proTeaser(title: String, icon: String, description: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(theme.accent.opacity(0.6))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            TelemetryService.paywallShown(source: "insights_locked_card")
            showProPrompt = true
        }
    }

    // MARK: - Fleet Summary Section

    private var fleetSummarySection: some View {
        Section {
            VStack(spacing: 12) {
                // Gradient header banner
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis.ascending")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Fleet Overview")
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
                .accessibilityLabel("Fleet overview: total spent \(settings.formatCost(totalCost))")

                // iPad: 3x2 grid, iPhone: 3+3 stacked
                let columns = sizeClass == .regular
                    ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
                       GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                    : [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

                LazyVGrid(columns: columns, spacing: 8) {
                    summaryCard(
                        title: "Total Spent",
                        value: settings.formatCost(totalCost),
                        icon: "dollarsign.circle.fill",
                        color: theme.accent
                    )
                    .statPop(index: 0)
                    summaryCard(
                        title: "Services",
                        value: "\(totalServiceCount)",
                        icon: "wrench.fill",
                        color: .catEngine
                    )
                    .statPop(index: 1)
                    summaryCard(
                        title: "Vehicles",
                        value: "\(vehicles.count)",
                        icon: "car.2.fill",
                        color: .catTires
                    )
                    .statPop(index: 2)
                    summaryCard(
                        title: "Avg/Service",
                        value: settings.formatCost(averageServiceCost),
                        icon: "equal.circle.fill",
                        color: .catFilters
                    )
                    .statPop(index: 3)
                    summaryCard(
                        title: "Service Cost",
                        value: settings.formatCost(totalServiceCost),
                        icon: "wrench.and.screwdriver.fill",
                        color: .catEngine
                    )
                    .statPop(index: 4)
                    summaryCard(
                        title: "Fuel Cost",
                        value: settings.formatCost(totalFuelCost),
                        icon: "fuelpump.fill",
                        color: .catFuel
                    )
                    .statPop(index: 5)
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
                        .fill(
                            LinearGradient(
                                colors: [Color.catElectrical.opacity(0.2), Color.catElectrical.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.catElectrical.opacity(0.2), radius: 6, x: 0, y: 2)
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
                    let yearStart = calendar.safeDate(from: calendar.dateComponents([.year], from: Date()))
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

    // MARK: - Year-over-Year Section

    private func yearOverYearSection(_ yoy: (currentYear: Int, currentTotal: Double, previousTotal: Double, changePercent: Double)) -> some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(yoy.changePercent >= 0
                            ? Color.Status.error.shade500.opacity(0.12)
                            : Color.Status.success.shade500.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: yoy.changePercent >= 0
                        ? "arrow.up.right"
                        : "arrow.down.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(yoy.changePercent >= 0 ? Color.Status.error.shade500 : Color.Status.success.shade500)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Year-over-Year")
                            .font(.subheadline.weight(.semibold))
                        Text(String(format: "%+.1f%%", yoy.changePercent))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(yoy.changePercent >= 0 ? Color.Status.error.shade500 : Color.Status.success.shade500)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                (yoy.changePercent >= 0 ? Color.Status.error.shade500 : Color.Status.success.shade500).opacity(0.12),
                                in: Capsule()
                            )
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(String(yoy.currentYear))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(settings.formatCost(yoy.currentTotal))
                                .font(.caption.weight(.semibold).monospacedDigit())
                        }
                        Image(systemName: "arrow.left")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(String(yoy.currentYear - 1))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
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

    // MARK: - Monthly Spending Section

    private var monthlySpendingSection: some View {
        Section {
            let hasData = monthlySpending.contains { $0.services > 0 || $0.fuel > 0 }
            if hasData {
                Chart {
                    ForEach(monthlySpending) { item in
                        if item.services > 0 {
                            BarMark(
                                x: .value("Month", item.month, unit: .month),
                                y: .value("Cost", item.services * chartAnimationProgress)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.catEngine, Color.catEngine.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .position(by: .value("Type", "Services"))
                            .cornerRadius(3)
                        }
                        if item.fuel > 0 {
                            BarMark(
                                x: .value("Month", item.month, unit: .month),
                                y: .value("Cost", item.fuel * chartAnimationProgress)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.catFuel, Color.catFuel.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .position(by: .value("Type", "Fuel"))
                            .cornerRadius(3)
                        }
                    }

                    if let selected = selectedMonthlySpend {
                        RuleMark(x: .value("Month", selected.month, unit: .month))
                            .foregroundStyle(.secondary.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                }
                .chartForegroundStyleScale([
                    "Services": Color.catEngine,
                    "Fuel": Color.catFuel,
                ])
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated))
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let cost = value.as(Double.self) {
                            AxisValueLabel {
                                Text(formatCompact(cost))
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                                .foregroundStyle(.secondary.opacity(0.2))
                        }
                    }
                }
                .chartXSelection(value: $selectedMonthlySpend.animation(.easeInOut(duration: 0.15)))
                .frame(height: sizeClass == .regular ? 260 : 200)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.systemBackground).opacity(0.8),
                                    Color(.secondarySystemBackground).opacity(0.4),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
                .chartReveal()

                // Tap detail for selected month
                if let selected = selectedMonthlySpend, (selected.services + selected.fuel) > 0 {
                    monthlySpendDetail(selected)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }

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
                            .font(.system(.caption, design: .rounded, weight: .bold).monospacedDigit())
                            .foregroundStyle(theme.accent)
                    }
                }
            } else {
                Text("No spending data in the last 12 months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.accent)
                    .frame(width: 3, height: 16)
                Text("Monthly Spending (12 Months)")
                    .font(.system(.headline, design: .rounded))
            }
        }
    }

    private func monthlySpendDetail(_ spend: MonthlySpend) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(spend.month, format: .dateTime.month(.wide).year())
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(settings.formatCost(spend.services + spend.fuel))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(theme.accent)
            }

            HStack(spacing: 16) {
                if spend.services > 0 {
                    HStack(spacing: 4) {
                        Circle().fill(Color.catEngine).frame(width: 7, height: 7)
                        Text("Services: \(settings.formatCost(spend.services))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                if spend.fuel > 0 {
                    HStack(spacing: 4) {
                        Circle().fill(Color.catFuel).frame(width: 7, height: 7)
                        Text("Fuel: \(settings.formatCost(spend.fuel))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Category Section

    private var categorySection: some View {
        Section {
            Chart(categorySpending) { item in
                SectorMark(
                    angle: .value("Cost", item.total * chartAnimationProgress),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(item.category.color)
                .annotation(position: .overlay) {
                    if item.total / totalServiceCost > 0.08 {
                        Text("\(Int(item.total / totalServiceCost * 100))%")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: sizeClass == .regular ? 240 : 200)
            .scaleEffect(donutScale)
            .chartReveal()

            // Legend with icon circles + bold values
            ForEach(categorySpending) { item in
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(item.category.color.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: item.category.icon)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(item.category.color)
                    }
                    Text(item.category.rawValue)
                        .font(.subheadline)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(settings.formatCost(item.total))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold).monospacedDigit())
                        Text("\(Int(item.total / totalServiceCost * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } header: {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.catEngine)
                    .frame(width: 3, height: 16)
                Text("Spending by Category")
                    .font(.system(.headline, design: .rounded))
            }
        }
    }

    // MARK: - Vehicle Comparison Section

    private var vehicleComparisonSection: some View {
        Section {
            Chart(vehicleCosts) { item in
                BarMark(
                    x: .value("Vehicle", item.name),
                    y: .value("Cost", item.services * chartAnimationProgress)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.catEngine, Color.catEngine.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .position(by: .value("Type", "Services"))
                .cornerRadius(3)

                BarMark(
                    x: .value("Vehicle", item.name),
                    y: .value("Cost", item.fuel * chartAnimationProgress)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.catFuel, Color.catFuel.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .position(by: .value("Type", "Fuel"))
                .cornerRadius(3)
            }
            .chartForegroundStyleScale([
                "Services": Color.catEngine,
                "Fuel": Color.catFuel,
            ])
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let cost = value.as(Double.self) {
                        AxisValueLabel {
                            Text(formatCompact(cost))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(.secondary.opacity(0.2))
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    if let name = value.as(String.self) {
                        AxisValueLabel {
                            Text(abbreviateVehicleName(name))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(height: sizeClass == .regular ? 260 : 200)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            )
            .chartReveal()

            ForEach(vehicleCosts) { item in
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(theme.accent.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "car.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline)
                        Text("Services: \(settings.formatCost(item.services)) · Fuel: \(settings.formatCost(item.fuel))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Text(settings.formatCost(item.services + item.fuel))
                        .font(.system(.subheadline, design: .rounded, weight: .bold).monospacedDigit())
                        .foregroundStyle(theme.accent)
                }
            }
        } header: {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.catTires)
                    .frame(width: 3, height: 16)
                Text("Cost per Vehicle")
                    .font(.system(.headline, design: .rounded))
            }
        }
    }

    // MARK: - Fuel Efficiency Comparison Section

    private var fuelEfficiencyComparisonSection: some View {
        Section {
            Chart(vehicleEfficiencyComparison) { item in
                BarMark(
                    x: .value(settings.efficiencyUnit.label, item.average * chartAnimationProgress),
                    y: .value("Vehicle", item.name)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.catFuel, Color.catFuel.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(4)
                .annotation(position: .trailing, spacing: 4) {
                    Text(String(format: "%.1f", item.average))
                        .font(.system(.caption2, design: .rounded, weight: .bold).monospacedDigit())
                        .foregroundStyle(Color.catFuel)
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    if let v = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.0f", v))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let name = value.as(String.self) {
                        AxisValueLabel {
                            Text(abbreviateVehicleName(name))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(height: CGFloat(vehicleEfficiencyComparison.count) * 48 + 20)

            ForEach(vehicleEfficiencyComparison) { item in
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.catFuel.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "gauge.medium")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.catFuel)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline)
                        HStack(spacing: 8) {
                            Label("Best: \(settings.formatEfficiency(item.best))", systemImage: "arrow.up")
                                .font(.caption2)
                                .foregroundStyle(Color.Status.success.shade500)
                            Label("Worst: \(settings.formatEfficiency(item.worst))", systemImage: "arrow.down")
                                .font(.caption2)
                                .foregroundStyle(Color.Status.error.shade500)
                        }
                    }
                    Spacer()
                    Text("\(item.fillUps) fills")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.catFuel)
                    .frame(width: 3, height: 16)
                Label("Fuel Efficiency Comparison", systemImage: "gauge.open.with.needle.33percent")
                    .font(.system(.headline, design: .rounded))
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
                                        .frame(width: geo.size.width * (item.total / maxTotal) * chartAnimationProgress, height: 6)
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
        Section {
            let hasData = maintenanceFrequency.contains { $0.count > 0 }
            if hasData {
                Chart(maintenanceFrequency) { point in
                    LineMark(
                        x: .value("Month", point.month, unit: .month),
                        y: .value("Count", Double(point.count) * chartAnimationProgress)
                    )
                    .foregroundStyle(theme.accent)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Month", point.month, unit: .month),
                        y: .value("Count", Double(point.count) * chartAnimationProgress)
                    )
                    .foregroundStyle(
                        .linearGradient(
                            colors: [theme.accent.opacity(0.25), theme.accent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", point.month, unit: .month),
                        y: .value("Count", Double(point.count) * chartAnimationProgress)
                    )
                    .foregroundStyle(theme.accent)
                    .symbolSize(point.count > 0 ? 36 : 0)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated))
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if let count = value.as(Int.self) {
                            AxisValueLabel {
                                Text("\(count)")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                                .foregroundStyle(.secondary.opacity(0.2))
                        }
                    }
                }
                .frame(height: sizeClass == .regular ? 200 : 160)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
                .chartReveal()

                let totalCount = maintenanceFrequency.reduce(0) { $0 + $1.count }
                let activeMonths = maintenanceFrequency.count(where: { $0.count > 0 })
                let avgPerMonth = activeMonths > 0 ? Double(totalCount) / Double(activeMonths) : 0

                HStack {
                    Text("Avg Services/Month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f", avgPerMonth))
                        .font(.system(.caption, design: .rounded, weight: .bold).monospacedDigit())
                        .foregroundStyle(theme.accent)
                }
            } else {
                Text("No maintenance data in the last 12 months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.accent)
                    .frame(width: 3, height: 16)
                Text("Maintenance Frequency")
                    .font(.system(.headline, design: .rounded))
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
                    "Fuel": Color.catFuel,
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
                .chartReveal()
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
            .chartReveal()

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

    // MARK: - Compliance Score Section (per vehicle)

    private var complianceScoreSection: some View {
        Section {
            ForEach(vehicleComplianceScores) { item in
                HStack(spacing: 12) {
                    ZStack {
                        ProgressRing(
                            progress: Double(item.healthScore) / 100.0,
                            lineWidth: 5,
                            color: MaintenanceScoreEngine.color(for: item.healthScore)
                        )
                        .frame(width: 46, height: 46)

                        Text("\(item.healthScore)")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(MaintenanceScoreEngine.color(for: item.healthScore))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(MaintenanceScoreEngine.label(for: item.healthScore))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(MaintenanceScoreEngine.color(for: item.healthScore))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    MaintenanceScoreEngine.color(for: item.healthScore).opacity(0.12),
                                    in: Capsule()
                                )
                        }

                        HStack(spacing: 12) {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.Status.success.shade500)
                                Text("\(item.compliant)/\(item.total) on track")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if item.overdue > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(Color.Status.error.shade500)
                                    Text("\(item.overdue) overdue")
                                        .font(.caption2)
                                        .foregroundStyle(Color.Status.error.shade500)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Label("Maintenance Health by Vehicle", systemImage: "heart.text.clipboard")
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
                                .foregroundStyle(Color.Status.error.shade500)
                        }
                    }
                }
                .padding(.vertical, 4)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(Color.Status.success.shade500)
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private func ownershipStat(label: String, value: String, color _: Color) -> some View {
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
        if pct >= 80 { return Color.Status.success.shade500 }
        if pct >= 50 { return Color.Status.warning.shade500 }
        return Color.Status.error.shade500
    }

    private func complianceLabel(_ pct: Double) -> String {
        if pct >= 90 { return "Excellent" }
        if pct >= 75 { return "Good" }
        if pct >= 50 { return "Needs Attention" }
        return "Behind Schedule"
    }
}

// MARK: - Chart Selection Binding for Monthly Spending

private extension Binding where Value == MonthlySpend? {
    init(chartSelection: Binding<Date?>, monthlySpending: [MonthlySpend]) {
        self.init(
            get: {
                guard let date = chartSelection.wrappedValue else { return nil }
                let calendar = Calendar.current
                return monthlySpending.first { item in
                    calendar.isDate(item.month, equalTo: date, toGranularity: .month)
                }
            },
            set: { newValue in
                chartSelection.wrappedValue = newValue?.month
            }
        )
    }
}

// MARK: - Data Models

private struct MonthlySpend: Identifiable, Plottable {
    let id = UUID()
    let month: Date
    let services: Double
    let fuel: Double

    var primitivePlottable: Date {
        month
    }

    init(month: Date, services: Double, fuel: Double) {
        self.month = month
        self.services = services
        self.fuel = fuel
    }

    init?(primitivePlottable: Date) {
        month = primitivePlottable
        services = 0
        fuel = 0
    }
}

private struct CategorySpend: Identifiable {
    var id: String {
        category.rawValue
    }

    let category: ServiceCategory
    let total: Double
}

private struct VehicleCost: Identifiable {
    var id: String {
        name
    }

    let name: String
    let services: Double
    let fuel: Double
    let vehicle: Vehicle
}

private struct ServiceTypeSpend: Identifiable {
    var id: String {
        name
    }

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
    var id: Int {
        year
    }

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
    var id: String {
        name
    }

    let name: String
    let serviceCost: Double
    let fuelCost: Double
    let totalCost: Double
    let monthsOwned: Int
    let costPerMonth: Double
    let serviceCount: Int
}

private struct VehicleEfficiency: Identifiable {
    var id: String {
        name
    }

    let name: String
    let average: Double
    let best: Double
    let worst: Double
    let fillUps: Int
}

private struct VehicleComplianceScore: Identifiable {
    var id: String {
        name
    }

    let name: String
    let vehicle: Vehicle
    let compliancePercent: Double
    let healthScore: Int
    let compliant: Int
    let total: Int
    let overdue: Int
}
