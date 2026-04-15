import Foundation
import SwiftUI
import Testing
@testable import WrenchLog

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
    func totalCount() {
        #expect(ServiceType.allCases.count == 22)
    }

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
    func allIcons() {
        ServiceType.allCases.forEach { #expect(!$0.icon.isEmpty) }
    }

    @Test("Engine fluids: 5 types")
    func engineFluids() {
        #expect(ServiceType.types(for: .engineFluids).count == 5)
    }

    @Test("Tires & brakes: 5 types")
    func tiresBrakes() {
        #expect(ServiceType.types(for: .tiresBrakes).count == 5)
    }

    @Test("Filters & belts: 5 types")
    func filtersBelts() {
        #expect(ServiceType.types(for: .filtersBelts).count == 5)
    }

    @Test("Electrical: 3 types")
    func electrical() {
        #expect(ServiceType.types(for: .electrical).count == 3)
    }

    @Test("Inspection: 4 types")
    func inspection() {
        #expect(ServiceType.types(for: .inspection).count == 4)
    }

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
    func symbols() {
        Currency.allCases.forEach { #expect(!$0.symbol.isEmpty) }
    }

    @Test("All distance units have labels")
    func labels() {
        DistanceUnit.allCases.forEach { #expect(!$0.label.isEmpty) }
    }
}

struct CategoryTests {
    @Test("All have icons") func icons() {
        ServiceCategory.allCases.forEach { #expect(!$0.icon.isEmpty) }
    }

    @Test("6 categories") func count() {
        #expect(ServiceCategory.allCases.count == 6)
    }

    @Test("Custom exists") func custom() {
        #expect(ServiceCategory.custom.rawValue == "Custom")
    }

    @Test("All have colors") func colors() {
        for cat in ServiceCategory.allCases {
            // Just accessing .color shouldn't crash
            _ = cat.color
        }
    }
}

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
        #expect(v.serviceRecords?.isEmpty ?? true)
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
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let r = ServiceRecord(serviceType: .brakePads, date: date, mileage: 75000, cost: 350.0, notes: "Front and rear")
        #expect(r.date == date)
        #expect(r.mileage == 75000)
        #expect(r.cost == 350.0)
        #expect(r.notes == "Front and rear")
        #expect(r.category == .tiresBrakes)
    }
}

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

// MARK: - Retention Engine Tests

@MainActor
struct RetentionEngineTests {
    /// Clean UserDefaults keys used by RetentionEngine before each test
    private func cleanDefaults() {
        let keys = [
            "wl_streak", "wl_longest_streak", "wl_last_active",
            "wl_total_opens", "wl_install_date", "wl_grace_used_date",
            "wl_journey_notifs_scheduled",
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    @Test("Streak starts at 0 for fresh defaults")
    func streakStartsAtZero() {
        cleanDefaults()
        let streak = UserDefaults.standard.integer(forKey: "wl_streak")
        #expect(streak == 0)
    }

    @Test("recordActivity sets streak to 1 on first call")
    func recordActivityIncrementsStreak() {
        cleanDefaults()
        let engine = RetentionEngine.shared
        engine.recordActivity()
        #expect(engine.currentStreak == 1)
        cleanDefaults()
    }

    @Test("dailyTip returns a non-empty string")
    func dailyTipNonEmpty() {
        let tip = RetentionEngine.shared.dailyTip
        #expect(!tip.isEmpty)
        #expect(tip.count > 10) // should be a real tip, not a stub
    }

    @Test("journeyDay returns 1 for fresh install")
    func journeyDayFreshInstall() {
        cleanDefaults()
        // Set install date to now — journeyDay should be 1
        UserDefaults.standard.set(Date(), forKey: "wl_install_date")
        let day = RetentionEngine.shared.journeyDay
        #expect(day == 1)
        cleanDefaults()
    }

    @Test("journeyMessage returns non-nil for day 1")
    func journeyMessageDay1() throws {
        cleanDefaults()
        UserDefaults.standard.set(Date(), forKey: "wl_install_date")
        let message = RetentionEngine.shared.journeyMessage
        #expect(message != nil)
        #expect(try #require(message?.contains("Welcome")))
        cleanDefaults()
    }

    @Test("streakMessage returns nil for streak < 2")
    func streakMessageNilForLowStreak() {
        cleanDefaults()
        // Streak is 0
        #expect(RetentionEngine.shared.streakMessage == nil)
        // Set streak to 1
        UserDefaults.standard.set(1, forKey: "wl_streak")
        #expect(RetentionEngine.shared.streakMessage == nil)
        cleanDefaults()
    }

    @Test("streakMessage returns message for streak of 2")
    func streakMessageForTwo() throws {
        cleanDefaults()
        UserDefaults.standard.set(2, forKey: "wl_streak")
        let msg = RetentionEngine.shared.streakMessage
        #expect(msg != nil)
        #expect(try #require(msg?.contains("2-day")))
        cleanDefaults()
    }

    @Test("isActiveToday returns false initially")
    func isActiveTodayFalse() {
        cleanDefaults()
        #expect(RetentionEngine.shared.isActiveToday == false)
        cleanDefaults()
    }

    @Test("isActiveToday returns true after recordActivity")
    func isActiveTodayAfterRecord() {
        cleanDefaults()
        RetentionEngine.shared.recordActivity()
        #expect(RetentionEngine.shared.isActiveToday == true)
        cleanDefaults()
    }

    @Test("totalOpens increments with recordActivity")
    func totalOpensIncrements() {
        cleanDefaults()
        let engine = RetentionEngine.shared
        let before = engine.totalOpens
        engine.recordActivity()
        #expect(engine.totalOpens == before + 1)
        cleanDefaults()
    }
}

// MARK: - Soft Paywall Tests

@MainActor
struct SoftPaywallTests {
    /// Reset UserDefaults keys used by SoftPaywallTracker
    private func cleanDefaults() {
        UserDefaults.standard.removeObject(forKey: "wl_lifetime_actions")
        UserDefaults.standard.removeObject(forKey: "wl_paywall_dismissed")
    }

    @Test("Initial sessionActionCount is 0")
    func initialSessionCount() {
        // SoftPaywallTracker is a singleton; sessionActionCount resets per app launch.
        // Since tests run in one process, we verify the property is accessible and non-negative.
        let tracker = SoftPaywallTracker.shared
        #expect(tracker.sessionActionCount >= 0)
    }

    @Test("recordAction increments sessionActionCount")
    func recordActionIncrements() {
        let tracker = SoftPaywallTracker.shared
        let before = tracker.sessionActionCount
        tracker.recordAction()
        #expect(tracker.sessionActionCount == before + 1)
    }

    @Test("recordAction increments lifetimeActionCount")
    func recordActionLifetime() {
        cleanDefaults()
        let tracker = SoftPaywallTracker.shared
        let before = tracker.lifetimeActionCount
        tracker.recordAction()
        #expect(tracker.lifetimeActionCount == before + 1)
        cleanDefaults()
    }

    @Test("markDismissed sets hasDismissedBefore to true")
    func markDismissedSetsFlag() {
        cleanDefaults()
        let tracker = SoftPaywallTracker.shared
        tracker.markDismissed()
        #expect(tracker.hasDismissedBefore == true)
        cleanDefaults()
    }

    @Test("hasDismissedBefore persists in UserDefaults")
    func dismissedPersists() {
        cleanDefaults()
        SoftPaywallTracker.shared.markDismissed()
        // Read directly from UserDefaults to verify persistence
        let persisted = UserDefaults.standard.bool(forKey: "wl_paywall_dismissed")
        #expect(persisted == true)
        cleanDefaults()
    }
}

// MARK: - Maintenance Score Tests

@MainActor
struct MaintenanceScoreTests {
    @Test("Score for new vehicle with no records is 50")
    func scoreNewVehicle() {
        let v = Vehicle(make: "Test", model: "Car", year: 2024)
        v.serviceRecords = []
        let score = MaintenanceScoreEngine.score(for: v)
        #expect(score == 50)
    }

    @Test("Score is always between 0 and 100")
    func scoreBounds() {
        let v = Vehicle(make: "Test", model: "Car", year: 2024)
        v.serviceRecords = []
        let score = MaintenanceScoreEngine.score(for: v)
        #expect(score >= 0)
        #expect(score <= 100)
    }

    @Test("Vehicle with records but no reminders scores 85")
    func scoreWithRecordsNoReminders() {
        let v = Vehicle(make: "Test", model: "Car", year: 2024, mileage: 10000)
        let r = ServiceRecord(serviceType: .generalRepair, cost: 50)
        r.vehicle = v
        v.serviceRecords = [r]
        // generalRepair has 0 default intervals, so no reminders — score should be 85
        let score = MaintenanceScoreEngine.score(for: v)
        #expect(score == 85)
    }

    @Test("color returns a Color for all score ranges")
    func colorForScores() {
        // Test representative scores from each bucket
        let scores = [0, 20, 39, 40, 59, 60, 79, 80, 100]
        for s in scores {
            _ = MaintenanceScoreEngine.color(for: s)
            // No crash = Color returned successfully
        }
    }

    @Test("color maps high score to success green")
    func colorHighScore() {
        let c = MaintenanceScoreEngine.color(for: 90)
        #expect(c == Color.Status.success.shade500)
    }

    @Test("color maps low score to error red")
    func colorLowScore() {
        let c = MaintenanceScoreEngine.color(for: 20)
        #expect(c == Color.Status.error.shade500)
    }

    @Test("label returns correct string for score ranges")
    func labelForScores() {
        #expect(MaintenanceScoreEngine.label(for: 95) == "Excellent")
        #expect(MaintenanceScoreEngine.label(for: 80) == "Good")
        #expect(MaintenanceScoreEngine.label(for: 65) == "Fair")
        #expect(MaintenanceScoreEngine.label(for: 50) == "Needs Attention")
        #expect(MaintenanceScoreEngine.label(for: 20) == "Critical")
    }

    @Test("icon returns valid SF Symbol names")
    func iconForScores() {
        #expect(MaintenanceScoreEngine.icon(for: 90) == "heart.fill")
        #expect(MaintenanceScoreEngine.icon(for: 70) == "heart")
        #expect(MaintenanceScoreEngine.icon(for: 50) == "heart.slash")
        #expect(MaintenanceScoreEngine.icon(for: 20) == "heart.slash.fill")
    }
}

// MARK: - Theme Tests

@MainActor
struct ThemeTests {
    @Test("5 themes exist")
    func themeCount() {
        #expect(AppTheme.allCases.count == 5)
    }

    @Test("Each theme has an accent color")
    func accentColors() {
        for theme in AppTheme.allCases {
            _ = theme.accent
            _ = theme.accentLight
            // No crash = colors exist
        }
    }

    @Test("Each theme has headerGradient with 2 colors")
    func headerGradientSize() {
        for theme in AppTheme.allCases {
            #expect(theme.headerGradient.count == 2)
        }
    }

    @Test("Each theme has sectionGradient with 2 colors")
    func sectionGradientSize() {
        for theme in AppTheme.allCases {
            #expect(theme.sectionGradient.count == 2)
        }
    }

    @Test("Default theme is defaultAmber")
    func defaultTheme() {
        // ThemeManager defaults to .defaultAmber when no UserDefaults key is set
        UserDefaults.standard.removeObject(forKey: "wl_theme")
        #expect(ThemeManager.shared.current == .defaultAmber)
    }

    @Test("darkMono has dark color scheme")
    func darkMonoScheme() {
        #expect(AppTheme.darkMono.preferredColorScheme == .dark)
    }

    @Test("Non-dark themes have nil color scheme")
    func nonDarkSchemes() {
        #expect(AppTheme.defaultAmber.preferredColorScheme == nil)
        #expect(AppTheme.oceanBlue.preferredColorScheme == nil)
        #expect(AppTheme.forestGreen.preferredColorScheme == nil)
        #expect(AppTheme.sunsetRose.preferredColorScheme == nil)
    }

    @Test("Each theme has an icon")
    func themeIcons() {
        for theme in AppTheme.allCases {
            #expect(!theme.icon.isEmpty)
        }
    }

    @Test("Theme rawValues are unique")
    func uniqueRawValues() {
        let rawValues = AppTheme.allCases.map(\.rawValue)
        #expect(Set(rawValues).count == rawValues.count)
    }

    @Test("Theme IDs match rawValues")
    func idsMatchRaw() {
        for theme in AppTheme.allCases {
            #expect(theme.id == theme.rawValue)
        }
    }
}

// MARK: - Fuel Efficiency Tests

struct FuelEfficiencyTests {
    @Test("FuelType has EV case")
    func fuelTypeHasEV() {
        #expect(FuelType.allCases.contains(.ev))
    }

    @Test("FuelType.ev.isElectric is true")
    func evIsElectric() {
        #expect(FuelType.ev.isElectric == true)
    }

    @Test("Non-EV fuel types are not electric")
    func nonEvNotElectric() {
        let nonEV: [FuelType] = [.regular, .midgrade, .premium, .diesel, .e85]
        for fuel in nonEV {
            #expect(fuel.isElectric == false)
        }
    }

    @Test("volumeLabel returns kWh for EV")
    func volumeLabelEV() {
        #expect(FuelType.ev.volumeLabel(fallback: .gallons) == "kWh")
        #expect(FuelType.ev.volumeLabel(fallback: .liters) == "kWh")
    }

    @Test("volumeLabel returns user unit for non-EV")
    func volumeLabelNonEV() {
        #expect(FuelType.regular.volumeLabel(fallback: .gallons) == "gal")
        #expect(FuelType.regular.volumeLabel(fallback: .liters) == "L")
        #expect(FuelType.diesel.volumeLabel(fallback: .gallons) == "gal")
        #expect(FuelType.premium.volumeLabel(fallback: .liters) == "L")
    }

    @Test("All fuel types have icons")
    func allFuelIcons() {
        for fuel in FuelType.allCases {
            #expect(!fuel.icon.isEmpty)
        }
    }

    @Test("All fuel types have short labels")
    func allFuelShortLabels() {
        for fuel in FuelType.allCases {
            #expect(!fuel.shortLabel.isEmpty)
        }
    }

    @Test("FuelType count is 6")
    func fuelTypeCount() {
        #expect(FuelType.allCases.count == 6)
    }

    @Test("EfficiencyUnit has MPG and L/100km")
    func efficiencyUnits() {
        #expect(EfficiencyUnit.allCases.count == 2)
        #expect(EfficiencyUnit.mpg.label == "MPG")
        #expect(EfficiencyUnit.l100km.label == "L/100km")
    }

    @Test("Empty fuel logs produce no efficiency results")
    func emptyEfficiency() {
        let logs: [FuelLog] = []
        #expect(logs.calculateEfficiency().isEmpty)
    }

    @Test("Single fuel log produces no efficiency results")
    func singleLogEfficiency() {
        let log = FuelLog(mileage: 10000, volume: 12.0, totalCost: 45.0)
        #expect([log].calculateEfficiency().isEmpty)
    }

    @Test("Two full-tank logs produce one efficiency result")
    func twoLogsEfficiency() {
        let log1 = FuelLog(mileage: 10000, volume: 12.0, totalCost: 40.0, isFullTank: true)
        let log2 = FuelLog(mileage: 10300, volume: 10.0, totalCost: 35.0, isFullTank: true)
        let results = [log1, log2].calculateEfficiency()
        #expect(results.count == 1)
        #expect(results[0].distance == 300)
        #expect(results[0].mpg > 0)
        #expect(results[0].l100km > 0)
    }

    @Test("Non-full-tank logs are excluded from efficiency calculation")
    func partialTankExcluded() {
        let log1 = FuelLog(mileage: 10000, volume: 12.0, isFullTank: true)
        let log2 = FuelLog(mileage: 10200, volume: 5.0, isFullTank: false)
        let log3 = FuelLog(mileage: 10500, volume: 14.0, isFullTank: true)
        let results = [log1, log2, log3].calculateEfficiency()
        // Only full-tank logs (log1 and log3) produce a result
        #expect(results.count == 1)
        #expect(results[0].distance == 500)
    }
}
