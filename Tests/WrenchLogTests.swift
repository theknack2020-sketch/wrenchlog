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

    @Test("Service types distributed across all non-custom categories")
    func typeDistribution() {
        for category in ServiceCategory.allCases where category != .custom {
            #expect(!ServiceType.types(for: category).isEmpty)
        }
    }

    @Test("Total service types count is 22")
    func totalCount() { #expect(ServiceType.allCases.count == 22) }

    @Test("Oil change has correct defaults")
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
    func allIcons() { ServiceType.allCases.forEach { #expect(!$0.icon.isEmpty) } }

    @Test("Engine fluids: 5 types")
    func engineFluids() { #expect(ServiceType.types(for: .engineFluids).count == 5) }

    @Test("Tires & brakes: 5 types")
    func tiresBrakes() { #expect(ServiceType.types(for: .tiresBrakes).count == 5) }

    @Test("Filters & belts: 5 types")
    func filtersBelts() { #expect(ServiceType.types(for: .filtersBelts).count == 5) }

    @Test("Electrical: 3 types")
    func electrical() { #expect(ServiceType.types(for: .electrical).count == 3) }

    @Test("Inspection: 4 types")
    func inspection() { #expect(ServiceType.types(for: .inspection).count == 4) }

    @Test("All types with mileage intervals are positive")
    func mileageIntervals() {
        for type in ServiceType.allCases {
            #expect(type.defaultMileageInterval >= 0)
        }
    }

    @Test("All types with month intervals are positive")
    func monthIntervals() {
        for type in ServiceType.allCases {
            #expect(type.defaultMonthInterval >= 0)
        }
    }
}

@MainActor
@Suite("Unit Formatting Tests")
struct UnitTests {
    @Test("Mileage with value contains unit label")
    func formatMilesWithValue() {
        let s = UserSettings.shared
        s.distanceUnit = .miles
        let r = s.formatMileage(50000)
        #expect(r.contains("mi") && r.contains("50") && !r.contains("No mileage"))
    }

    @Test("Zero mileage shows placeholder")
    func formatZero() {
        let s = UserSettings.shared
        s.distanceUnit = .miles
        #expect(s.formatMileage(0) == "No mileage set")
    }

    @Test("Km formatting")
    func formatKm() {
        let s = UserSettings.shared
        s.distanceUnit = .km
        #expect(s.formatMileage(80000).contains("km"))
        s.distanceUnit = .miles
    }

    @Test("USD cost")
    func usd() {
        let s = UserSettings.shared; s.currency = .usd
        #expect(s.formatCost(45.99) == "$45.99")
    }

    @Test("EUR cost")
    func eur() {
        let s = UserSettings.shared; s.currency = .eur
        #expect(s.formatCost(45.99) == "€45.99"); s.currency = .usd
    }

    @Test("GBP cost")
    func gbp() {
        let s = UserSettings.shared; s.currency = .gbp
        #expect(s.formatCost(10.00) == "£10.00"); s.currency = .usd
    }

    @Test("TRY cost")
    func tryy() {
        let s = UserSettings.shared; s.currency = .try_
        #expect(s.formatCost(100.50) == "₺100.50"); s.currency = .usd
    }

    @Test("Zero cost")
    func zeroCost() {
        let s = UserSettings.shared; s.currency = .usd
        #expect(s.formatCost(0) == "$0.00")
    }

    @Test("All currencies have symbols")
    func symbols() { Currency.allCases.forEach { #expect(!$0.symbol.isEmpty) } }

    @Test("All distance units have labels")
    func labels() { DistanceUnit.allCases.forEach { #expect(!$0.label.isEmpty) } }
}

@Suite("Category Tests")
struct CategoryTests {
    @Test("All have icons") func icons() { ServiceCategory.allCases.forEach { #expect(!$0.icon.isEmpty) } }
    @Test("6 categories") func count() { #expect(ServiceCategory.allCases.count == 6) }
    @Test("Custom exists") func custom() { #expect(ServiceCategory.custom.rawValue == "Custom") }
    @Test("All have colors") func colors() {
        for cat in ServiceCategory.allCases {
            // Just accessing .color shouldn't crash
            _ = cat.color
        }
    }
}

@Suite("Vehicle Model Tests")
struct VehicleTests {
    @Test("Display name format")
    func displayName() {
        let v = Vehicle(make: "Toyota", model: "Camry", year: 2022, mileage: 45000)
        #expect(v.displayName == "2022 Toyota Camry")
    }

    @Test("Defaults")
    func defaults() {
        let v = Vehicle(make: "Honda", model: "Civic", year: 2023)
        #expect(v.currentMileage == 0)
        #expect(v.licensePlate == "")
        #expect(v.vin == "")
        #expect(!v.isArchived)
        #expect(v.serviceRecords.isEmpty)
        #expect(v.photoData == nil)
    }

    @Test("Hashable")
    func hashable() {
        let v1 = Vehicle(make: "BMW", model: "X3", year: 2024)
        let v2 = Vehicle(make: "BMW", model: "X3", year: 2024)
        #expect(v1 != v2)
        #expect(v1 == v1)
    }

    @Test("Display name with different data")
    func displayNames() {
        let v = Vehicle(make: "Mercedes-Benz", model: "E 350", year: 2020)
        #expect(v.displayName == "2020 Mercedes-Benz E 350")
    }
}

@Suite("Service Record Tests")
struct ServiceRecordTests {
    @Test("Preset record")
    func preset() {
        let r = ServiceRecord(serviceType: .oilChange, mileage: 50000, cost: 89.99, notes: "Synthetic 5W-30")
        #expect(r.serviceType == .oilChange)
        #expect(r.category == .engineFluids)
        #expect(r.displayServiceType == "Oil Change")
        #expect(r.mileage == 50000)
        #expect(r.cost == 89.99)
    }

    @Test("Custom record")
    func custom() {
        let r = ServiceRecord(customType: "Headlight Bulb", category: .electrical, cost: 25.00)
        #expect(r.serviceType == nil)
        #expect(r.category == .electrical)
        #expect(r.displayServiceType == "Headlight Bulb")
    }

    @Test("Default category for custom is .custom")
    func defaultCustomCategory() {
        let r = ServiceRecord(customType: "Random Fix")
        #expect(r.category == .custom)
    }

    @Test("Zero cost")
    func zeroCost() {
        let r = ServiceRecord(serviceType: .stateInspection, cost: 0)
        #expect(r.cost == 0)
    }

    @Test("Empty photos")
    func emptyPhotos() {
        let r = ServiceRecord(serviceType: .tireRotation)
        #expect(r.photoFileNames.isEmpty)
    }

    @Test("Icon fallback for custom")
    func iconFallback() {
        let r = ServiceRecord(customType: "Something")
        #expect(r.icon == "wrench.and.screwdriver.fill")
    }

    @Test("Color fallback for custom")
    func colorFallback() {
        let r = ServiceRecord(customType: "Something")
        #expect(r.color == .catCustom)
    }

    @Test("Record with all fields")
    func fullRecord() {
        let date = Date(timeIntervalSince1970: 1700000000)
        let r = ServiceRecord(serviceType: .brakePads, date: date, mileage: 75000, cost: 350.0, notes: "Front and rear")
        #expect(r.date == date)
        #expect(r.mileage == 75000)
        #expect(r.cost == 350.0)
        #expect(r.notes == "Front and rear")
        #expect(r.category == .tiresBrakes)
    }
}

@Suite("PDF Export Tests")
struct PDFTests {
    @MainActor
    @Test("PDF generates non-nil data for vehicle with records")
    func pdfGeneration() {
        let v = Vehicle(make: "Test", model: "Car", year: 2024, mileage: 10000)
        let r = ServiceRecord(serviceType: .oilChange, cost: 50)
        r.vehicle = v
        v.serviceRecords = [r]

        let data = PDFExportService.generatePDF(for: v, settings: UserSettings.shared)
        #expect(data != nil)
        #expect((data?.count ?? 0) > 100) // has real content
    }

    @MainActor
    @Test("PDF generates for vehicle with no records")
    func pdfEmpty() {
        let v = Vehicle(make: "Empty", model: "Car", year: 2023)
        v.serviceRecords = []
        let data = PDFExportService.generatePDF(for: v, settings: UserSettings.shared)
        #expect(data != nil)
    }
}
