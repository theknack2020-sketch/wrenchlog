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

        let records = vehicle.serviceRecords.sorted { $0.date > $1.date }
        let totalCost = records.reduce(0) { $0 + $1.cost }

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let title = "Service History Report"
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
            y += 36

            // Vehicle info
            let infoAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let boldAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.label
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

            "Total Spent: \(settings.formatCost(totalCost))".draw(at: CGPoint(x: margin, y: y), withAttributes: infoAttrs)
            y += 20

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            "Generated: \(dateFormatter.string(from: Date()))".draw(at: CGPoint(x: margin, y: y), withAttributes: infoAttrs)
            y += 30

            // Divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: y))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            UIColor.separator.setStroke()
            dividerPath.lineWidth = 0.5
            dividerPath.stroke()
            y += 16

            // Column headers
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: UIColor.secondaryLabel
            ]
            "DATE".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttrs)
            "SERVICE".draw(at: CGPoint(x: margin + 100, y: y), withAttributes: headerAttrs)
            "MILEAGE".draw(at: CGPoint(x: margin + 300, y: y), withAttributes: headerAttrs)
            "COST".draw(at: CGPoint(x: margin + 420, y: y), withAttributes: headerAttrs)
            y += 20

            // Records
            let rowAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.label
            ]
            let rowLightAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
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
                        .foregroundColor: UIColor.tertiaryLabel
                    ]
                    notesStr.draw(
                        in: CGRect(x: margin + 100, y: y, width: contentWidth - 100, height: 30),
                        withAttributes: noteAttrs
                    )
                }

                y += 22
            }

            // Footer
            if y > pageHeight - margin - 60 {
                context.beginPage()
                y = margin
            }
            y += 20
            let footerPath = UIBezierPath()
            footerPath.move(to: CGPoint(x: margin, y: y))
            footerPath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            UIColor.separator.setStroke()
            footerPath.lineWidth = 0.5
            footerPath.stroke()
            y += 12

            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            "Generated by WrenchLog — wrenchlog.app".draw(at: CGPoint(x: margin, y: y), withAttributes: footerAttrs)
        }

        return data
    }
}
