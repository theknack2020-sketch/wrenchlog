import SwiftUI
import Charts

struct FuelEfficiencyChartView: View {
    let vehicle: Vehicle
    private let settings = UserSettings.shared

    var efficiencyResults: [FuelEfficiencyResult] {
        vehicle.fuelLogs.calculateEfficiency()
    }

    var averageEfficiency: Double? {
        let results = efficiencyResults
        guard !results.isEmpty else { return nil }
        let sum = results.reduce(0.0) { $0 + $1.efficiency(for: settings.efficiencyUnit) }
        return sum / Double(results.count)
    }

    var bestEfficiency: FuelEfficiencyResult? {
        switch settings.efficiencyUnit {
        case .mpg: efficiencyResults.max(by: { $0.mpg < $1.mpg })
        case .l100km: efficiencyResults.min(by: { $0.l100km < $1.l100km }) // lower is better
        }
    }

    var worstEfficiency: FuelEfficiencyResult? {
        switch settings.efficiencyUnit {
        case .mpg: efficiencyResults.min(by: { $0.mpg < $1.mpg })
        case .l100km: efficiencyResults.max(by: { $0.l100km < $1.l100km })
        }
    }

    // Monthly fuel cost
    var monthlyFuelCost: [(month: Date, total: Double)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).reversed().map { monthsAgo in
            let month = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            let total = vehicle.fuelLogs
                .filter { $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.totalCost }
            return (month: start, total: total)
        }
    }

    // Cost per mile/km trend
    var costPerDistanceTrend: [(date: Date, cost: Double)] {
        efficiencyResults.map { result in
            (date: result.date, cost: result.costPerDistance(for: settings.distanceUnit))
        }
    }

    var body: some View {
        List {
            // Summary cards
            if let avg = averageEfficiency {
                Section {
                    HStack(spacing: 8) {
                        statCard(
                            title: "Average",
                            value: settings.formatEfficiency(avg),
                            color: .catFuel
                        )
                        if let best = bestEfficiency {
                            statCard(
                                title: "Best",
                                value: settings.formatEfficiency(best.efficiency(for: settings.efficiencyUnit)),
                                color: .wrenchGreen
                            )
                        }
                        if let worst = worstEfficiency {
                            statCard(
                                title: "Worst",
                                value: settings.formatEfficiency(worst.efficiency(for: settings.efficiencyUnit)),
                                color: .wrenchRed
                            )
                        }
                    }
                }
            }

            // Efficiency trend chart
            if efficiencyResults.count >= 2 {
                Section("Fuel Efficiency Trend") {
                    Chart(efficiencyResults) { result in
                        LineMark(
                            x: .value("Date", result.date),
                            y: .value(settings.efficiencyUnit.label, result.efficiency(for: settings.efficiencyUnit))
                        )
                        .foregroundStyle(Color.catFuel.gradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        PointMark(
                            x: .value("Date", result.date),
                            y: .value(settings.efficiencyUnit.label, result.efficiency(for: settings.efficiencyUnit))
                        )
                        .foregroundStyle(Color.catFuel)
                        .symbolSize(30)

                        if let avg = averageEfficiency {
                            RuleMark(y: .value("Average", avg))
                                .foregroundStyle(.secondary.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Avg: \(String(format: "%.1f", avg))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
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
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.month(.abbreviated).day())
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                }
            } else if !efficiencyResults.isEmpty {
                Section("Fuel Efficiency Trend") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Need at least 2 full-tank fill-ups for trend chart")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Monthly fuel cost chart
            if monthlyFuelCost.contains(where: { $0.total > 0 }) {
                Section("Monthly Fuel Cost") {
                    Chart(monthlyFuelCost, id: \.month) { item in
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Cost", item.total)
                        )
                        .foregroundStyle(Color.catFuel.gradient)
                        .cornerRadius(4)
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
            }

            // Cost per mile/km trend
            if costPerDistanceTrend.count >= 2 {
                Section("Cost per \(settings.distanceUnit == .miles ? "Mile" : "Kilometer")") {
                    Chart(costPerDistanceTrend, id: \.date) { item in
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Cost", item.cost)
                        )
                        .foregroundStyle(Color.wrenchAmber.opacity(0.2).gradient)
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Cost", item.cost)
                        )
                        .foregroundStyle(Color.wrenchAmber)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            if let cost = value.as(Double.self) {
                                AxisValueLabel {
                                    Text(settings.formatCostPerDistance(cost))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.month(.abbreviated))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                }
            }

            // Fuel type breakdown
            let typeBreakdown = fuelTypeBreakdown()
            if typeBreakdown.count > 1 {
                Section("Fuel Type Breakdown") {
                    Chart(typeBreakdown, id: \.type) { item in
                        SectorMark(
                            angle: .value("Volume", item.volume),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(item.type.color)
                    }
                    .frame(height: 160)

                    ForEach(typeBreakdown, id: \.type) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(item.type.color)
                                .frame(width: 10, height: 10)
                            Text(item.type.rawValue)
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(item.count)) fills · \(settings.formatVolume(item.volume))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Fuel Efficiency")
    }

    private func fuelTypeBreakdown() -> [(type: FuelType, volume: Double, count: Int)] {
        var map: [String: (volume: Double, count: Int)] = [:]
        for log in vehicle.fuelLogs {
            let key = log.fuelTypeRaw
            let existing = map[key, default: (volume: 0, count: 0)]
            map[key] = (volume: existing.volume + log.volume, count: existing.count + 1)
        }
        return map.compactMap { key, value in
            guard let type = FuelType(rawValue: key) else { return nil }
            return (type: type, volume: value.volume, count: value.count)
        }.sorted { $0.volume > $1.volume }
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
