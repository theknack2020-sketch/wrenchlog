import SwiftUI
import Charts

struct FuelEfficiencyChartView: View {
    let vehicle: Vehicle
    private let settings = UserSettings.shared

    @State private var chartAnimationProgress: Double = 0

    var efficiencyResults: [FuelEfficiencyResult] {
        vehicle.safeFuelLogs.calculateEfficiency()
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

    // Trend line slope (linear regression)
    var trendLine: (start: Double, end: Double)? {
        let results = efficiencyResults
        guard results.count >= 3 else { return nil }

        let values = results.map { $0.efficiency(for: settings.efficiencyUnit) }
        let n = Double(values.count)
        let xs = values.indices.map { Double($0) }
        let sumX = xs.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(xs, values).reduce(0) { $0 + $1.0 * $1.1 }
        let sumX2 = xs.reduce(0) { $0 + $1 * $1 }

        let denom = n * sumX2 - sumX * sumX
        guard denom != 0 else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n

        let startVal = intercept
        let endVal = intercept + slope * (n - 1)
        return (start: startVal, end: endVal)
    }

    var trendDirection: String {
        guard let trend = trendLine else { return "" }
        let diff = trend.end - trend.start
        let threshold = 0.5
        if diff > threshold { return settings.efficiencyUnit == .mpg ? "improving" : "worsening" }
        if diff < -threshold { return settings.efficiencyUnit == .mpg ? "declining" : "improving" }
        return "stable"
    }

    // Monthly fuel cost
    var monthlyFuelCost: [(month: Date, total: Double)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).reversed().map { monthsAgo in
            let month = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            let total = vehicle.safeFuelLogs
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

                    // Trend indicator
                    if let trend = trendLine, efficiencyResults.count >= 3 {
                        let direction = trendDirection
                        let trendColor: Color = direction == "improving" ? .wrenchGreen
                            : direction == "declining" || direction == "worsening" ? .wrenchRed
                            : .secondary
                        let trendIcon = direction == "improving" ? "arrow.up.right"
                            : direction == "declining" || direction == "worsening" ? "arrow.down.right"
                            : "arrow.right"
                        let diff = abs(trend.end - trend.start)

                        HStack(spacing: 8) {
                            Image(systemName: trendIcon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(trendColor)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Efficiency is \(direction)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(trendColor)
                                Text("\(String(format: "%.1f", diff)) \(settings.efficiencyUnit.label) change over \(efficiencyResults.count) fill-ups")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            // Efficiency trend chart with trend line, avg, best/worst markers
            if efficiencyResults.count >= 2 {
                Section("Fuel Efficiency Trend") {
                    Chart {
                        // Area fill under the line
                        ForEach(efficiencyResults) { result in
                            AreaMark(
                                x: .value("Date", result.date),
                                y: .value(settings.efficiencyUnit.label, result.efficiency(for: settings.efficiencyUnit) * chartAnimationProgress)
                            )
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [Color.catFuel.opacity(0.15), Color.catFuel.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        // Main line
                        ForEach(efficiencyResults) { result in
                            LineMark(
                                x: .value("Date", result.date),
                                y: .value(settings.efficiencyUnit.label, result.efficiency(for: settings.efficiencyUnit) * chartAnimationProgress)
                            )
                            .foregroundStyle(Color.catFuel.gradient)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }

                        // Data points
                        ForEach(efficiencyResults) { result in
                            let isBest = bestEfficiency?.id == result.id
                            let isWorst = worstEfficiency?.id == result.id

                            PointMark(
                                x: .value("Date", result.date),
                                y: .value(settings.efficiencyUnit.label, result.efficiency(for: settings.efficiencyUnit) * chartAnimationProgress)
                            )
                            .foregroundStyle(isBest ? Color.wrenchGreen : isWorst ? Color.wrenchRed : Color.catFuel)
                            .symbolSize(isBest || isWorst ? 60 : 30)
                            .symbol(isBest ? .diamond : isWorst ? .triangle : .circle)
                        }

                        // Average line
                        if let avg = averageEfficiency {
                            RuleMark(y: .value("Average", avg * chartAnimationProgress))
                                .foregroundStyle(.secondary.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("Avg: \(String(format: "%.1f", avg))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                        }

                        // Trend line
                        if let trend = trendLine, efficiencyResults.count >= 3 {
                            let firstDate = efficiencyResults.first?.date ?? Date()
                            let lastDate = efficiencyResults.last?.date ?? Date()

                            LineMark(
                                x: .value("Date", firstDate),
                                y: .value(settings.efficiencyUnit.label, trend.start * chartAnimationProgress)
                            )
                            .foregroundStyle(Color.catElectrical.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                            .accessibilityLabel("Trend line start")

                            LineMark(
                                x: .value("Date", lastDate),
                                y: .value(settings.efficiencyUnit.label, trend.end * chartAnimationProgress)
                            )
                            .foregroundStyle(Color.catElectrical.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                            .accessibilityLabel("Trend line end")
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
                    .frame(height: 220)

                    // Best/worst legend
                    if bestEfficiency != nil || worstEfficiency != nil {
                        HStack(spacing: 16) {
                            if let best = bestEfficiency {
                                HStack(spacing: 4) {
                                    Image(systemName: "diamond.fill")
                                        .font(.caption2)
                                        .foregroundStyle(Color.wrenchGreen)
                                    Text("Best: \(settings.formatEfficiency(best.efficiency(for: settings.efficiencyUnit)))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(best.date, format: .dateTime.month(.abbreviated).day())
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            if let worst = worstEfficiency {
                                HStack(spacing: 4) {
                                    Image(systemName: "triangle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(Color.wrenchRed)
                                    Text("Worst: \(settings.formatEfficiency(worst.efficiency(for: settings.efficiencyUnit)))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(worst.date, format: .dateTime.month(.abbreviated).day())
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
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
                            y: .value("Cost", item.total * chartAnimationProgress)
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

                    // Monthly average
                    let nonZero = monthlyFuelCost.filter { $0.total > 0 }
                    if !nonZero.isEmpty {
                        let avg = nonZero.reduce(0) { $0 + $1.total } / Double(nonZero.count)
                        HStack {
                            Text("Monthly Average")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(settings.formatCost(avg))
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundStyle(Color.catFuel)
                        }
                    }
                }
            }

            // Cost per mile/km trend
            if costPerDistanceTrend.count >= 2 {
                Section("Cost per \(settings.distanceUnit == .miles ? "Mile" : "Kilometer")") {
                    Chart(costPerDistanceTrend, id: \.date) { item in
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Cost", item.cost * chartAnimationProgress)
                        )
                        .foregroundStyle(Color.wrenchAmber.opacity(0.2).gradient)
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Cost", item.cost * chartAnimationProgress)
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
                            angle: .value("Volume", item.volume * chartAnimationProgress),
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
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.15)) {
                chartAnimationProgress = 1.0
            }
        }
    }

    private func fuelTypeBreakdown() -> [(type: FuelType, volume: Double, count: Int)] {
        var map: [String: (volume: Double, count: Int)] = [:]
        for log in vehicle.safeFuelLogs {
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
        .shadow(color: color.opacity(0.10), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
