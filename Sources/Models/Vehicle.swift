import Foundation
import SwiftData
import SwiftUI

@Model
final class Vehicle {
    var id: UUID
    var make: String
    var model: String
    var year: Int
    var currentMileage: Int
    var licensePlate: String
    var vin: String
    var photoData: Data?
    var vehiclePhotoFileName: String
    var dateAdded: Date
    var lastUpdated: Date
    var isArchived: Bool
    var colorRaw: String

    var purchaseDate: Date?
    var purchasePrice: Double

    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.vehicle)
    var serviceRecords: [ServiceRecord]

    @Relationship(deleteRule: .cascade, inverse: \FuelLog.vehicle)
    var fuelLogs: [FuelLog]

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceChecklistItem.vehicle)
    var checklistItems: [MaintenanceChecklistItem]

    @Relationship(deleteRule: .cascade, inverse: \VehicleDocument.vehicle)
    var documents: [VehicleDocument]

    var soldDate: Date?

    var displayName: String {
        "\(year) \(make) \(model)"
    }

    var vehicleColor: VehicleColor? {
        VehicleColor(rawValue: colorRaw)
    }

    var isSold: Bool {
        soldDate != nil
    }

    /// Years since purchase (or since dateAdded if no purchase date)
    var yearsOwned: Int {
        let from = purchaseDate ?? dateAdded
        return max(0, Calendar.current.dateComponents([.year], from: from, to: .now).year ?? 0)
    }

    /// Simple straight-line depreciation estimate.
    /// First year: 20%, years 2-5: 15%/yr, years 6+: 10%/yr.
    var estimatedDepreciation: Double? {
        guard purchasePrice > 0 else { return nil }
        let from = purchaseDate ?? dateAdded
        let months = max(1, Calendar.current.dateComponents([.month], from: from, to: .now).month ?? 1)
        let yearsFractional = Double(months) / 12.0

        var remaining = purchasePrice
        // Year 1: 20%
        let y1Factor = min(yearsFractional, 1.0)
        remaining -= purchasePrice * 0.20 * y1Factor

        // Years 2-5: 15% of original per year
        if yearsFractional > 1 {
            let y2to5 = min(yearsFractional - 1.0, 4.0)
            remaining -= purchasePrice * 0.15 * y2to5
        }

        // Years 6+: 10% of original per year
        if yearsFractional > 5 {
            let y6plus = yearsFractional - 5.0
            remaining -= purchasePrice * 0.10 * y6plus
        }

        // Floor at 10% of purchase price
        remaining = max(purchasePrice * 0.10, remaining)
        return purchasePrice - remaining
    }

    /// Estimated current value after depreciation
    var estimatedCurrentValue: Double? {
        guard let dep = estimatedDepreciation else { return nil }
        return purchasePrice - dep
    }

    init(make: String, model: String, year: Int, mileage: Int = 0) {
        self.id = UUID()
        self.make = make
        self.model = model
        self.year = year
        self.currentMileage = mileage
        self.licensePlate = ""
        self.vin = ""
        self.vehiclePhotoFileName = ""
        self.colorRaw = ""
        self.dateAdded = .now
        self.lastUpdated = .now
        self.isArchived = false
        self.purchasePrice = 0
        self.serviceRecords = []
        self.fuelLogs = []
        self.checklistItems = []
        self.documents = []
    }
}

extension Vehicle: Hashable {
    static func == (lhs: Vehicle, rhs: Vehicle) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

@Model
final class ServiceRecord {
    var id: UUID
    var date: Date
    var mileage: Int
    var cost: Double
    var serviceTypeRaw: String       // ServiceType.rawValue or custom string
    var categoryRaw: String          // ServiceCategory.rawValue
    var notes: String
    var photoFileNames: [String]     // filenames in app's documents directory
    var vehicle: Vehicle?

    var serviceType: ServiceType? {
        ServiceType(rawValue: serviceTypeRaw)
    }

    var category: ServiceCategory {
        ServiceCategory(rawValue: categoryRaw) ?? .custom
    }

    var displayServiceType: String {
        serviceType?.rawValue ?? serviceTypeRaw
    }

    var icon: String {
        serviceType?.uniqueIcon ?? "wrench.and.screwdriver.fill"
    }

    var color: Color {
        serviceType?.color ?? .catCustom
    }

    init(
        serviceType: ServiceType,
        date: Date = .now,
        mileage: Int = 0,
        cost: Double = 0,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.mileage = mileage
        self.cost = cost
        self.serviceTypeRaw = serviceType.rawValue
        self.categoryRaw = serviceType.category.rawValue
        self.notes = notes
        self.photoFileNames = []
    }

    init(
        customType: String,
        category: ServiceCategory = .custom,
        date: Date = .now,
        mileage: Int = 0,
        cost: Double = 0,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.mileage = mileage
        self.cost = cost
        self.serviceTypeRaw = customType
        self.categoryRaw = category.rawValue
        self.notes = notes
        self.photoFileNames = []
    }
}
