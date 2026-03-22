import Testing
import Foundation
@testable import WrenchLog

@Suite("Service Type Tests")
struct ServiceTypeTests {

    @Test("All 22 service types have a category")
    func allTypesHaveCategory() {
        for type in ServiceType.allCases {
            #expect(ServiceCategory.allCases.contains(type.category))
        }
    }

    @Test("Service types are distributed across all non-custom categories")
    func typeDistribution() {
        let nonCustomCategories = ServiceCategory.allCases.filter { $0 != .custom }
        for category in nonCustomCategories {
            let types = ServiceType.types(for: category)
            #expect(!types.isEmpty, "Category \(category.rawValue) has no types")
        }
    }

    @Test("Total service types count is 22")
    func totalCount() {
        #expect(ServiceType.allCases.count == 22)
    }

    @Test("Oil change has correct default intervals")
    func oilChangeDefaults() {
        #expect(ServiceType.oilChange.defaultMileageInterval == 5000)
        #expect(ServiceType.oilChange.defaultMonthInterval == 6)
    }

    @Test("General repair has no default interval")
    func generalRepairNoDefaults() {
        #expect(ServiceType.generalRepair.defaultMileageInterval == 0)
        #expect(ServiceType.generalRepair.defaultMonthInterval == 0)
    }

    @Test("Each type has an icon")
    func allTypesHaveIcons() {
        for type in ServiceType.allCases {
            #expect(!type.icon.isEmpty)
        }
    }

    @Test("Engine fluids category has 5 types")
    func engineFluidsCount() {
        let types = ServiceType.types(for: .engineFluids)
        #expect(types.count == 5)
    }

    @Test("Tires and brakes category has 5 types")
    func tiresBrakesCount() {
        let types = ServiceType.types(for: .tiresBrakes)
        #expect(types.count == 5)
    }
}

@MainActor
@Suite("Unit Formatting Tests")
struct UnitTests {

    @Test("Mileage formatting - miles with value")
    func formatMilesWithValue() {
        let settings = UserSettings.shared
        settings.distanceUnit = .miles
        let result = settings.formatMileage(50000)
        #expect(result.contains("mi"))
        #expect(result.contains("50"))
        #expect(!result.contains("No mileage"))
    }

    @Test("Mileage formatting - zero shows 'No mileage set'")
    func formatMilesZero() {
        let settings = UserSettings.shared
        settings.distanceUnit = .miles
        #expect(settings.formatMileage(0) == "No mileage set")
    }

    @Test("Mileage formatting - km")
    func formatKm() {
        let settings = UserSettings.shared
        settings.distanceUnit = .km
        let result = settings.formatMileage(80000)
        #expect(result.contains("km"))
        settings.distanceUnit = .miles // reset
    }

    @Test("Cost formatting - USD")
    func formatCostUSD() {
        let settings = UserSettings.shared
        settings.currency = .usd
        #expect(settings.formatCost(45.99) == "$45.99")
    }

    @Test("Cost formatting - EUR")
    func formatCostEUR() {
        let settings = UserSettings.shared
        settings.currency = .eur
        #expect(settings.formatCost(45.99) == "€45.99")
        settings.currency = .usd // reset
    }

    @Test("Cost formatting - zero")
    func formatCostZero() {
        let settings = UserSettings.shared
        settings.currency = .usd
        #expect(settings.formatCost(0) == "$0.00")
    }

    @Test("All currencies have symbols")
    func currencySymbols() {
        for currency in Currency.allCases {
            #expect(!currency.symbol.isEmpty)
        }
    }

    @Test("All distance units have labels")
    func distanceLabels() {
        for unit in DistanceUnit.allCases {
            #expect(!unit.label.isEmpty)
        }
    }
}

@Suite("Service Category Tests")
struct CategoryTests {

    @Test("All categories have icons")
    func allHaveIcons() {
        for cat in ServiceCategory.allCases {
            #expect(!cat.icon.isEmpty)
        }
    }

    @Test("Category count is 6")
    func categoryCount() {
        #expect(ServiceCategory.allCases.count == 6)
    }

    @Test("Custom category exists")
    func customExists() {
        #expect(ServiceCategory.custom.rawValue == "Custom")
    }
}

@Suite("Vehicle Model Tests")
struct VehicleTests {

    @Test("Vehicle display name format")
    func displayName() {
        let vehicle = Vehicle(make: "Toyota", model: "Camry", year: 2022, mileage: 45000)
        #expect(vehicle.displayName == "2022 Toyota Camry")
    }

    @Test("Vehicle initializes with correct defaults")
    func vehicleDefaults() {
        let vehicle = Vehicle(make: "Honda", model: "Civic", year: 2023)
        #expect(vehicle.currentMileage == 0)
        #expect(vehicle.licensePlate == "")
        #expect(vehicle.vin == "")
        #expect(vehicle.isArchived == false)
        #expect(vehicle.serviceRecords.isEmpty)
        #expect(vehicle.photoData == nil)
    }

    @Test("Vehicle is Hashable")
    func vehicleHashable() {
        let v1 = Vehicle(make: "BMW", model: "X3", year: 2024)
        let v2 = Vehicle(make: "BMW", model: "X3", year: 2024)
        #expect(v1 != v2) // different UUIDs
        #expect(v1 == v1) // same instance
    }
}

@Suite("Service Record Tests")
struct ServiceRecordTests {

    @Test("Preset service record")
    func presetRecord() {
        let record = ServiceRecord(
            serviceType: .oilChange,
            mileage: 50000,
            cost: 89.99,
            notes: "Synthetic 5W-30"
        )
        #expect(record.serviceType == .oilChange)
        #expect(record.category == .engineFluids)
        #expect(record.displayServiceType == "Oil Change")
        #expect(record.mileage == 50000)
        #expect(record.cost == 89.99)
        #expect(record.notes == "Synthetic 5W-30")
    }

    @Test("Custom service record")
    func customRecord() {
        let record = ServiceRecord(
            customType: "Headlight Bulb",
            category: .electrical,
            cost: 25.00
        )
        #expect(record.serviceType == nil)
        #expect(record.category == .electrical)
        #expect(record.displayServiceType == "Headlight Bulb")
        #expect(record.cost == 25.00)
    }

    @Test("Record with zero cost")
    func zeroCost() {
        let record = ServiceRecord(serviceType: .stateInspection, cost: 0)
        #expect(record.cost == 0)
    }

    @Test("Photo filenames start empty")
    func emptyPhotos() {
        let record = ServiceRecord(serviceType: .tireRotation)
        #expect(record.photoFileNames.isEmpty)
    }
}
