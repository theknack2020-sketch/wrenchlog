import SwiftUI
import Charts

struct CostAnalyticsView: View {
    let vehicle: Vehicle
    private let settings = UserSettings.shared

    var records: [ServiceRecord] {
        vehicle.serviceRecords.sorted { $0.date > $1.date }
    }

    var fuelLogs: [FuelLog] {
        vehicle.fuelLogs.sorted { $0.date > $1.date }
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

    // Fuel efficiency summary
    var efficiencyResults: [FuelEfficiencyResult] {
        vehicle.fuelLogs.calculateEfficiency()
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
        List {
            // Summary
            Section {
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

                    statCard(title: "Total Cost", value: settings.formatCost(totalCost), color: .wrenchAmber)
                    statCard(title: "Services", value: settings.formatCost(totalServiceCost), color: .catEngine)
                    statCard(title: "Fuel", value: settings.formatCost(totalFuelCost), color: .catFuel)
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

            // Service vs Fuel split
            if costSplit.count == 2 {
                Section("Services vs Fuel") {
                    Chart(costSplit, id: \.label) { item in
                        SectorMark(
                            angle: .value("Cost", item.total),
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
                            angle: .value("Cost", item.total),
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
                                progress: totalServiceCost > 0 ? item.total / totalServiceCost : 0,
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

            // Yearly total cost of ownership
            if !yearlyCosts.isEmpty {
                Section("Yearly Cost of Ownership") {
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
        .navigationTitle("Cost Analytics")
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
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}
