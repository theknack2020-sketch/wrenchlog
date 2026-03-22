import SwiftUI
import Charts

struct CostAnalyticsView: View {
    let vehicle: Vehicle
    private let settings = UserSettings.shared

    var records: [ServiceRecord] {
        vehicle.serviceRecords.sorted { $0.date > $1.date }
    }

    var totalCost: Double {
        records.reduce(0) { $0 + $1.cost }
    }

    // Cost by category
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

    // Monthly spending (last 12 months)
    var monthlySpending: [(month: Date, total: Double)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<12).reversed().map { monthsAgo in
            let month = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            let total = records.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.cost }
            return (month: start, total: total)
        }
    }

    var body: some View {
        List {
            // Summary
            Section {
                HStack {
                    statCard(title: "Total Spent", value: settings.formatCost(totalCost), color: .wrenchAmber)
                    statCard(title: "Services", value: "\(records.count)", color: .catEngine)
                    if let avg = averageCost {
                        statCard(title: "Avg/Service", value: settings.formatCost(avg), color: .catTires)
                    }
                }
            }

            // Category breakdown donut
            if !categoryBreakdown.isEmpty {
                Section("Spending by Category") {
                    Chart(categoryBreakdown, id: \.category) { item in
                        SectorMark(
                            angle: .value("Cost", item.total),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(item.color)
                        .annotation(position: .overlay) {
                            if item.total / totalCost > 0.1 {
                                Text("\(Int(item.total / totalCost * 100))%")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(height: 200)

                    // Legend
                    ForEach(categoryBreakdown, id: \.category) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 10, height: 10)
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

            // Monthly spending bar chart
            Section("Monthly Spending") {
                Chart(monthlySpending, id: \.month) { item in
                    BarMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Cost", item.total)
                    )
                    .foregroundStyle(Color.wrenchAmber.gradient)
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

    private var averageCost: Double? {
        let paid = records.filter { $0.cost > 0 }
        guard !paid.isEmpty else { return nil }
        return paid.reduce(0) { $0 + $1.cost } / Double(paid.count)
    }

    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}
