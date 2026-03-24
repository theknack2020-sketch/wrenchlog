import SwiftUI
import PDFKit

struct PDFExportService {
    
    @MainActor
    static func generatePDF(for vehicle: Vehicle, settings: UserSettings) -> Data? {
        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let records = vehicle.safeServiceRecords.sorted { $0.date > $1.date }
        let totalServiceCost = records.reduce(0) { $0 + $1.cost }
        let fuelLogs = vehicle.safeFuelLogs.sorted { $0.date > $1.date }
        let totalFuelCost = fuelLogs.reduce(0) { $0 + $1.totalCost }
        let totalCost = totalServiceCost + totalFuelCost

        // Compute stats
        let paidRecords = records.filter { $0.cost > 0 }
        let averageCost = paidRecords.isEmpty ? 0 : paidRecords.reduce(0) { $0 + $1.cost } / Double(paidRecords.count)
        let highestService = records.max { $0.cost < $1.cost }
        let effResults = vehicle.safeFuelLogs.calculateEfficiency()
        let avgEfficiency: Double? = effResults.isEmpty ? nil : effResults.reduce(0.0) { $0 + $1.efficiency(for: settings.efficiencyUnit) } / Double(effResults.count)
        let healthScore = MaintenanceScoreEngine.score(for: vehicle)

        // Category breakdown
        var categoryMap: [String: Double] = [:]
        for record in records {
            categoryMap[record.categoryRaw, default: 0] += record.cost
        }
        let categoryBreakdown = categoryMap
            .compactMap { key, value -> (String, Double)? in
                guard value > 0 else { return nil }
                return (key, value)
            }
            .sorted { $0.1 > $1.1 }

        // Monthly spending (last 6 months)
        let calendar = Calendar.current
        let now = Date()
        let monthlySpending: [(month: String, total: Double)] = (0..<6).reversed().compactMap { monthsAgo in
            let month = calendar.date(byAdding: .month, value: -monthsAgo, to: now)!
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            let svc = records.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.cost }
            let fuel = fuelLogs.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.totalCost }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return (month: formatter.string(from: month), total: svc + fuel)
        }

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin

            // Force light mode colors for PDF
            let titleColor = UIColor.black
            let bodyColor = UIColor.darkGray
            let lightColor = UIColor.gray
            let sepColor = UIColor.lightGray
            let accentColor = UIColor(red: 0.91, green: 0.64, blue: 0.09, alpha: 1.0)
            let greenColor = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0)
            let redColor = UIColor(red: 0.90, green: 0.22, blue: 0.21, alpha: 1.0)
            let blueColor = UIColor(red: 0.35, green: 0.55, blue: 0.85, alpha: 1.0)
            let fuelColor = UIColor(red: 0.20, green: 0.65, blue: 0.55, alpha: 1.0)

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: titleColor
            ]
            let title = "Vehicle Report"
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
            y += 36

            // Vehicle info
            let infoAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: bodyColor
            ]
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: titleColor
            ]

            let vehicleInfo = vehicle.displayName
            vehicleInfo.draw(at: CGPoint(x: margin, y: y), withAttributes: boldAttrs)
            y += 22

            if !vehicle.licensePlate.isEmpty {
                "License: \(vehicle.licensePlate)".draw(at: CGPoint(x: margin, y: y), withAttributes: infoAttrs)
                y += 20
            }
            if !vehicle.vin.isEmpty {
                "VIN: \(vehicle.vin)".draw(at: CGPoint(x: margin, y: y), withAttributes: infoAttrs)
                y += 20
            }

            "Mileage: \(settings.formatMileage(vehicle.currentMileage))".draw(at: CGPoint(x: margin, y: y), withAttributes: infoAttrs)
            y += 20

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            "Generated: \(dateFormatter.string(from: Date()))".draw(at: CGPoint(x: margin, y: y), withAttributes: infoAttrs)
            y += 28

            // ────────────────────────────────────────
            // STATS SUMMARY SECTION
            // ────────────────────────────────────────

            drawDivider(at: &y, margin: margin, pageWidth: pageWidth, color: sepColor)

            let sectionTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: titleColor
            ]
            "Statistics Summary".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitleAttrs)
            y += 26

            // Stat boxes
            let boxWidth = (contentWidth - 16) / 3
            let boxHeight: CGFloat = 56
            let statBoxAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: titleColor
            ]
            let statLabelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: lightColor
            ]

            // Row 1: Total Cost, Service Cost, Fuel Cost
            drawStatBox(context: context, x: margin, y: y, width: boxWidth, height: boxHeight,
                        value: settings.formatCost(totalCost), label: "TOTAL COST",
                        valueAttrs: statBoxAttrs, labelAttrs: statLabelAttrs, bgColor: accentColor)
            drawStatBox(context: context, x: margin + boxWidth + 8, y: y, width: boxWidth, height: boxHeight,
                        value: settings.formatCost(totalServiceCost), label: "SERVICE COST",
                        valueAttrs: statBoxAttrs, labelAttrs: statLabelAttrs, bgColor: blueColor)
            drawStatBox(context: context, x: margin + (boxWidth + 8) * 2, y: y, width: boxWidth, height: boxHeight,
                        value: settings.formatCost(totalFuelCost), label: "FUEL COST",
                        valueAttrs: statBoxAttrs, labelAttrs: statLabelAttrs, bgColor: fuelColor)
            y += boxHeight + 10

            // Row 2: Services, Avg/Service, Health Score
            drawStatBox(context: context, x: margin, y: y, width: boxWidth, height: boxHeight,
                        value: "\(records.count)", label: "SERVICES",
                        valueAttrs: statBoxAttrs, labelAttrs: statLabelAttrs, bgColor: blueColor)
            drawStatBox(context: context, x: margin + boxWidth + 8, y: y, width: boxWidth, height: boxHeight,
                        value: averageCost > 0 ? settings.formatCost(averageCost) : "—", label: "AVG / SERVICE",
                        valueAttrs: statBoxAttrs, labelAttrs: statLabelAttrs, bgColor: accentColor)

            let healthColor = healthScore >= 80 ? greenColor : healthScore >= 60 ? accentColor : redColor
            drawStatBox(context: context, x: margin + (boxWidth + 8) * 2, y: y, width: boxWidth, height: boxHeight,
                        value: "\(healthScore)/100", label: "HEALTH SCORE",
                        valueAttrs: statBoxAttrs, labelAttrs: statLabelAttrs, bgColor: healthColor)
            y += boxHeight + 10

            // Row 3: Fill-ups, Avg Efficiency, Most Expensive
            if !fuelLogs.isEmpty || highestService != nil {
                drawStatBox(context: context, x: margin, y: y, width: boxWidth, height: boxHeight,
                            value: "\(fuelLogs.count)", label: "FILL-UPS",
                            valueAttrs: statBoxAttrs, labelAttrs: statLabelAttrs, bgColor: fuelColor)
                if let avg = avgEfficiency {
                    drawStatBox(context: context, x: margin + boxWidth + 8, y: y, width: boxWidth, height: boxHeight,
                                value: settings.formatEfficiency(avg), label: "AVG EFFICIENCY",
                                valueAttrs: statBoxAttrs, labelAttrs: statLabelAttrs, bgColor: fuelColor)
                }
                if let highest = highestService, highest.cost > 0 {
                    let highestBoxAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                        .foregroundColor: titleColor
                    ]
                    drawStatBox(context: context, x: margin + (boxWidth + 8) * 2, y: y, width: boxWidth, height: boxHeight,
                                value: settings.formatCost(highest.cost), label: "MOST EXPENSIVE",
                                valueAttrs: highestBoxAttrs, labelAttrs: statLabelAttrs, bgColor: redColor)
                }
                y += boxHeight + 10
            }

            // ────────────────────────────────────────
            // CATEGORY BREAKDOWN
            // ────────────────────────────────────────

            if !categoryBreakdown.isEmpty {
                y += 4
                let catTitleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                    .foregroundColor: titleColor
                ]
                "Spending by Category".draw(at: CGPoint(x: margin, y: y), withAttributes: catTitleAttrs)
                y += 20

                let barMaxWidth: CGFloat = contentWidth * 0.55
                let maxCatValue = categoryBreakdown.first?.1 ?? 1

                let catNameAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                    .foregroundColor: bodyColor
                ]
                let catValueAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold),
                    .foregroundColor: bodyColor
                ]

                for (name, value) in categoryBreakdown.prefix(6) {
                    // Category name
                    name.draw(at: CGPoint(x: margin, y: y + 1), withAttributes: catNameAttrs)

                    // Bar
                    let barX = margin + contentWidth * 0.35
                    let barWidth = barMaxWidth * CGFloat(value / maxCatValue)
                    let barRect = CGRect(x: barX, y: y + 2, width: barWidth, height: 10)
                    let barBgRect = CGRect(x: barX, y: y + 2, width: barMaxWidth, height: 10)

                    UIColor.systemGray5.setFill()
                    UIBezierPath(roundedRect: barBgRect, cornerRadius: 3).fill()
                    accentColor.setFill()
                    UIBezierPath(roundedRect: barRect, cornerRadius: 3).fill()

                    // Value
                    let costStr = settings.formatCost(value)
                    let costSize = costStr.size(withAttributes: catValueAttrs)
                    costStr.draw(at: CGPoint(x: pageWidth - margin - costSize.width, y: y), withAttributes: catValueAttrs)

                    y += 18
                }
                y += 6
            }

            // ────────────────────────────────────────
            // MONTHLY SPENDING MINI CHART
            // ────────────────────────────────────────

            let nonZeroMonths = monthlySpending.filter { $0.total > 0 }
            if !nonZeroMonths.isEmpty {
                if y > pageHeight - margin - 120 {
                    context.beginPage()
                    y = margin
                }

                let chartTitleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .bold),
                    .foregroundColor: titleColor
                ]
                "Monthly Spending (6 Months)".draw(at: CGPoint(x: margin, y: y), withAttributes: chartTitleAttrs)
                y += 20

                let chartHeight: CGFloat = 70
                let barSpacing: CGFloat = 8
                let barCount = CGFloat(monthlySpending.count)
                let barWidth = (contentWidth - barSpacing * (barCount - 1)) / barCount
                let maxMonthly = monthlySpending.map(\.total).max() ?? 1

                let monthLabelAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8, weight: .medium),
                    .foregroundColor: lightColor
                ]
                let monthValueAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 7, weight: .semibold),
                    .foregroundColor: bodyColor
                ]

                for (index, item) in monthlySpending.enumerated() {
                    let barX = margin + CGFloat(index) * (barWidth + barSpacing)
                    let barH = chartHeight * CGFloat(item.total / maxMonthly)
                    let barY = y + chartHeight - barH

                    // Background
                    let bgRect = CGRect(x: barX, y: y, width: barWidth, height: chartHeight)
                    UIColor.systemGray6.setFill()
                    UIBezierPath(roundedRect: bgRect, cornerRadius: 3).fill()

                    // Value bar
                    if item.total > 0 {
                        let valRect = CGRect(x: barX, y: barY, width: barWidth, height: barH)
                        accentColor.withAlphaComponent(0.7).setFill()
                        UIBezierPath(roundedRect: valRect, cornerRadius: 3).fill()
                    }

                    // Month label
                    let shortMonth = String(item.month.prefix(3))
                    let labelSize = shortMonth.size(withAttributes: monthLabelAttrs)
                    shortMonth.draw(at: CGPoint(x: barX + (barWidth - labelSize.width) / 2, y: y + chartHeight + 3), withAttributes: monthLabelAttrs)

                    // Value on top of bar
                    if item.total > 0 {
                        let valStr = formatCompactPDF(item.total, settings: settings)
                        let valSize = valStr.size(withAttributes: monthValueAttrs)
                        valStr.draw(at: CGPoint(x: barX + (barWidth - valSize.width) / 2, y: barY - 12), withAttributes: monthValueAttrs)
                    }
                }
                y += chartHeight + 24
            }

            // ────────────────────────────────────────
            // DIVIDER BEFORE SERVICE RECORDS
            // ────────────────────────────────────────

            if y > pageHeight - margin - 60 {
                context.beginPage()
                y = margin
            }

            drawDivider(at: &y, margin: margin, pageWidth: pageWidth, color: sepColor)

            // Column headers
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: bodyColor
            ]
            "DATE".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttrs)
            "SERVICE".draw(at: CGPoint(x: margin + 100, y: y), withAttributes: headerAttrs)
            "MILEAGE".draw(at: CGPoint(x: margin + 300, y: y), withAttributes: headerAttrs)
            "COST".draw(at: CGPoint(x: margin + 420, y: y), withAttributes: headerAttrs)
            y += 20

            // Records
            let rowAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: titleColor
            ]
            let rowLightAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: bodyColor
            ]

            for record in records {
                if y > pageHeight - margin - 40 {
                    context.beginPage()
                    y = margin
                }

                dateFormatter.string(from: record.date).draw(at: CGPoint(x: margin, y: y), withAttributes: rowAttrs)
                record.displayServiceType.draw(at: CGPoint(x: margin + 100, y: y), withAttributes: rowAttrs)

                if record.mileage > 0 {
                    settings.formatMileage(record.mileage).draw(at: CGPoint(x: margin + 300, y: y), withAttributes: rowLightAttrs)
                }

                if record.cost > 0 {
                    settings.formatCost(record.cost).draw(at: CGPoint(x: margin + 420, y: y), withAttributes: rowAttrs)
                }

                // Notes
                if !record.notes.isEmpty {
                    y += 16
                    let notesStr = "  \(record.notes)"
                    let noteAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.italicSystemFont(ofSize: 10),
                        .foregroundColor: lightColor
                    ]
                    notesStr.draw(
                        in: CGRect(x: margin + 100, y: y, width: contentWidth - 100, height: 30),
                        withAttributes: noteAttrs
                    )
                }

                y += 22
            }

            // ────────────────────────────────────────
            // FUEL LOGS SECTION
            // ────────────────────────────────────────

            if !fuelLogs.isEmpty {
                if y > pageHeight - margin - 60 {
                    context.beginPage()
                    y = margin
                }

                y += 10
                drawDivider(at: &y, margin: margin, pageWidth: pageWidth, color: sepColor)

                "FUEL LOG".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttrs)
                "TYPE".draw(at: CGPoint(x: margin + 100, y: y), withAttributes: headerAttrs)
                "VOLUME".draw(at: CGPoint(x: margin + 220, y: y), withAttributes: headerAttrs)
                "MILEAGE".draw(at: CGPoint(x: margin + 320, y: y), withAttributes: headerAttrs)
                "COST".draw(at: CGPoint(x: margin + 420, y: y), withAttributes: headerAttrs)
                y += 20

                for log in fuelLogs.prefix(30) {
                    if y > pageHeight - margin - 40 {
                        context.beginPage()
                        y = margin
                    }

                    dateFormatter.string(from: log.date).draw(at: CGPoint(x: margin, y: y), withAttributes: rowAttrs)
                    log.fuelType.rawValue.draw(at: CGPoint(x: margin + 100, y: y), withAttributes: rowLightAttrs)
                    settings.formatVolume(log.volume).draw(at: CGPoint(x: margin + 220, y: y), withAttributes: rowLightAttrs)
                    if log.mileage > 0 {
                        settings.formatMileage(log.mileage).draw(at: CGPoint(x: margin + 320, y: y), withAttributes: rowLightAttrs)
                    }
                    if log.totalCost > 0 {
                        settings.formatCost(log.totalCost).draw(at: CGPoint(x: margin + 420, y: y), withAttributes: rowAttrs)
                    }
                    y += 20
                }
            }

            // Footer
            if y > pageHeight - margin - 60 {
                context.beginPage()
                y = margin
            }
            y += 20
            drawDivider(at: &y, margin: margin, pageWidth: pageWidth, color: sepColor)

            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: lightColor
            ]
            "Generated by WrenchLog — wrenchlog.app".draw(at: CGPoint(x: margin, y: y), withAttributes: footerAttrs)
        }

        return data
    }

    // MARK: - PDF Drawing Helpers

    private static func drawDivider(at y: inout CGFloat, margin: CGFloat, pageWidth: CGFloat, color: UIColor) {
        let dividerPath = UIBezierPath()
        dividerPath.move(to: CGPoint(x: margin, y: y))
        dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        color.setStroke()
        dividerPath.lineWidth = 0.5
        dividerPath.stroke()
        y += 16
    }

    private static func drawStatBox(
        context: UIGraphicsPDFRendererContext,
        x: CGFloat, y: CGFloat,
        width: CGFloat, height: CGFloat,
        value: String, label: String,
        valueAttrs: [NSAttributedString.Key: Any],
        labelAttrs: [NSAttributedString.Key: Any],
        bgColor: UIColor
    ) {
        // Background rounded rect with subtle color
        let boxRect = CGRect(x: x, y: y, width: width, height: height)
        bgColor.withAlphaComponent(0.08).setFill()
        UIBezierPath(roundedRect: boxRect, cornerRadius: 6).fill()

        // Color accent bar on left
        let barRect = CGRect(x: x, y: y, width: 3, height: height)
        bgColor.withAlphaComponent(0.6).setFill()
        UIBezierPath(roundedRect: barRect, cornerRadius: 1.5).fill()

        // Value text
        let valueSize = value.size(withAttributes: valueAttrs)
        value.draw(at: CGPoint(x: x + 10, y: y + (height - valueSize.height) / 2 - 6), withAttributes: valueAttrs)

        // Label text
        label.draw(at: CGPoint(x: x + 10, y: y + (height - valueSize.height) / 2 + 14), withAttributes: labelAttrs)
    }

    @MainActor
    private static func formatCompactPDF(_ value: Double, settings: UserSettings) -> String {
        if value >= 1000 {
            return "\(settings.currency.symbol)\(String(format: "%.1f", value / 1000))k"
        }
        return settings.formatCost(value)
    }
}
