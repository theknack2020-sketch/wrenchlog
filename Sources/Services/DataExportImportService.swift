import Foundation
import SwiftData

struct DataExportImportService {

    // MARK: - Export

    @MainActor
    static func exportCSV(vehicles: [Vehicle], settings: UserSettings) -> (services: String, fuel: String) {
        // Service records CSV
        var serviceLines = ["Vehicle,Make,Model,Year,Service Type,Category,Service Date,Mileage,Cost,Notes"]
        for vehicle in vehicles {
            for record in vehicle.serviceRecords.sorted(by: { $0.date > $1.date }) {
                let dateStr = ISO8601DateFormatter().string(from: record.date)
                let notes = record.notes.replacingOccurrences(of: ",", with: ";")
                    .replacingOccurrences(of: "\n", with: " ")
                serviceLines.append(
                    "\"\(vehicle.displayName)\",\"\(vehicle.make)\",\"\(vehicle.model)\",\(vehicle.year),\"\(record.displayServiceType)\",\"\(record.categoryRaw)\",\(dateStr),\(record.mileage),\(String(format: "%.2f", record.cost)),\"\(notes)\""
                )
            }
        }

        // Fuel logs CSV
        var fuelLines = ["Vehicle,Make,Model,Year,Fuel Type,Date,Mileage,Volume,Volume Unit,Total Cost,Price Per Unit,Station,Full Tank,Notes"]
        for vehicle in vehicles {
            for log in vehicle.fuelLogs.sorted(by: { $0.date > $1.date }) {
                let dateStr = ISO8601DateFormatter().string(from: log.date)
                let station = log.station.replacingOccurrences(of: ",", with: ";")
                let notes = log.notes.replacingOccurrences(of: ",", with: ";")
                    .replacingOccurrences(of: "\n", with: " ")
                fuelLines.append(
                    "\"\(vehicle.displayName)\",\"\(vehicle.make)\",\"\(vehicle.model)\",\(vehicle.year),\"\(log.fuelTypeRaw)\",\(dateStr),\(log.mileage),\(String(format: "%.3f", log.volume)),\(log.volumeUnitRaw),\(String(format: "%.2f", log.totalCost)),\(String(format: "%.3f", log.pricePerUnit)),\"\(station)\",\(log.isFullTank),\"\(notes)\""
                )
            }
        }

        return (services: serviceLines.joined(separator: "\n"), fuel: fuelLines.joined(separator: "\n"))
    }

    static func writeToTempFile(_ content: String, fileName: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("[WrenchLog] Failed to write temp file: \(error)")
            return nil
        }
    }

    // MARK: - Import

    @MainActor
    static func importServiceCSV(data: Data, context: ModelContext) -> (vehicleCount: Int, recordCount: Int)? {
        guard let content = String(data: data, encoding: .utf8) else { return nil }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return nil }

        // Parse header
        let header = parseCSVLine(lines[0]).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        let vehicleIdx = header.firstIndex(of: "vehicle")
        let makeIdx = header.firstIndex(of: "make")
        let modelIdx = header.firstIndex(of: "model")
        let yearIdx = header.firstIndex(of: "year")
        let typeIdx = header.firstIndex(of: "service type")
        let dateIdx = header.firstIndex(of: "service date")
        let mileageIdx = header.firstIndex(of: "mileage")
        let costIdx = header.firstIndex(of: "cost")
        let notesIdx = header.firstIndex(of: "notes")

        guard typeIdx != nil, dateIdx != nil else { return nil }

        var vehicleCache: [String: Vehicle] = [:]
        var recordCount = 0
        let formatter = ISO8601DateFormatter()

        // Fetch existing vehicles
        let existing = (try? context.fetch(FetchDescriptor<Vehicle>())) ?? []
        for v in existing {
            vehicleCache[v.displayName] = v
        }

        for i in 1..<lines.count {
            let fields = parseCSVLine(lines[i])
            guard fields.count > max(typeIdx ?? 0, dateIdx ?? 0) else { continue }

            // Find or create vehicle
            let vehicleName = vehicleIdx.flatMap { $0 < fields.count ? fields[$0] : nil } ?? ""
            let make = makeIdx.flatMap { $0 < fields.count ? fields[$0] : nil } ?? "Unknown"
            let model = modelIdx.flatMap { $0 < fields.count ? fields[$0] : nil } ?? "Unknown"
            let year = yearIdx.flatMap { $0 < fields.count ? Int(fields[$0]) : nil } ?? 2024

            let cacheKey = vehicleName.isEmpty ? "\(year) \(make) \(model)" : vehicleName
            let vehicle: Vehicle
            if let cached = vehicleCache[cacheKey] {
                vehicle = cached
            } else {
                vehicle = Vehicle(make: make, model: model, year: year)
                context.insert(vehicle)
                vehicleCache[cacheKey] = vehicle
            }

            // Create service record
            let typeName = typeIdx.map { fields[$0] } ?? "General Repair"
            let dateStr = dateIdx.map { fields[$0] } ?? ""
            let date = formatter.date(from: dateStr) ?? Date()
            let mileage = mileageIdx.flatMap { $0 < fields.count ? Int(fields[$0]) : nil } ?? 0
            let cost = costIdx.flatMap { $0 < fields.count ? Double(fields[$0]) : nil } ?? 0
            let notes = notesIdx.flatMap { $0 < fields.count ? fields[$0] : nil } ?? ""

            let serviceType = ServiceType(rawValue: typeName)
            let record: ServiceRecord
            if let st = serviceType {
                record = ServiceRecord(serviceType: st, date: date, mileage: mileage, cost: cost, notes: notes)
            } else {
                record = ServiceRecord(customType: typeName, date: date, mileage: mileage, cost: cost, notes: notes)
            }
            record.vehicle = vehicle
            context.insert(record)
            recordCount += 1
        }

        try? DataManager.save(context)
        let vehicleCount = vehicleCache.count
        return (vehicleCount: vehicleCount, recordCount: recordCount)
    }

    // MARK: - CSV Parser

    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }
}
