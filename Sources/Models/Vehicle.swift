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
    var dateAdded: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.vehicle)
    var serviceRecords: [ServiceRecord]

    var displayName: String {
        "\(year) \(make) \(model)"
    }

    init(make: String, model: String, year: Int, mileage: Int = 0) {
        self.id = UUID()
        self.make = make
        self.model = model
        self.year = year
        self.currentMileage = mileage
        self.licensePlate = ""
        self.vin = ""
        self.dateAdded = .now
        self.isArchived = false
        self.serviceRecords = []
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
        serviceType?.icon ?? "wrench.and.screwdriver.fill"
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
