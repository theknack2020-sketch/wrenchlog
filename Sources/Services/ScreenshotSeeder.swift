#if DEBUG
    import Foundation
    import SwiftData

    /// Seeds mock data for App Store screenshot capture.
    /// ⚠️ DEBUG-ONLY — never included in Release builds.
    /// Triggered by launching with `-wl_seed_screenshots` launch argument.
    enum ScreenshotSeeder {
        /// Should seed mock data on this launch?
        static var shouldSeed: Bool {
            CommandLine.arguments.contains("-wl_seed_screenshots")
        }

        /// Populate the context with 3 vehicles, services, fuel logs.
        /// Idempotent: if any vehicles already exist, does nothing.
        @MainActor
        static func seed(context: ModelContext) {
            // Guard: only seed if DB is empty
            let descriptor = FetchDescriptor<Vehicle>()
            let existing = (try? context.fetch(descriptor)) ?? []
            guard existing.isEmpty else { return }

            let now = Date.now
            let cal = Calendar.current

            // Suppress "Welcome!" journey banner and set mature-user state
            // by backdating the install date past the 3-day journey window
            let installDate = cal.safeDate(byAdding: .day, value: -30, to: now)
            UserDefaults.standard.set(installDate, forKey: "wl_install_date")
            UserDefaults.standard.set(true, forKey: "wl_onboarding_complete")
            // Also seed a healthy streak for a polished look
            UserDefaults.standard.set(12, forKey: "wl_streak")
            UserDefaults.standard.set(28, forKey: "wl_longest_streak")
            UserDefaults.standard.set(now, forKey: "wl_last_active_date")
            UserDefaults.standard.set(42, forKey: "wl_total_opens")

            // Unlock Pro features for screenshot capture (all views unlocked)
            StoreManager.shared.setProForScreenshots(true)

            // MARK: - Vehicle 1: Toyota Camry 2022 (main hero vehicle)

            let camry = Vehicle(make: "Toyota", model: "Camry", year: 2022, mileage: 45280)
            camry.licensePlate = "ABC 1234"
            camry.vin = "4T1G11AK5NU123456"
            camry.colorRaw = VehicleColor.blue.rawValue
            camry.dateAdded = cal.safeDate(byAdding: .month, value: -14, to: now)
            camry.purchaseDate = cal.safeDate(byAdding: .year, value: -2, to: now)
            camry.purchasePrice = 28500
            context.insert(camry)

            // Camry services — rich history for Health Score + Timeline
            addService(to: camry, type: .oilChange, daysAgo: 22, mileageOffset: -1200, cost: 79.99, context: context)
            addService(to: camry, type: .tireRotation, daysAgo: 45, mileageOffset: -2300, cost: 45.00, context: context)
            addService(to: camry, type: .airFilter, daysAgo: 85, mileageOffset: -4100, cost: 32.50, context: context)
            addService(to: camry, type: .brakePads, daysAgo: 130, mileageOffset: -6800, cost: 285.00, context: context)
            addService(to: camry, type: .stateInspection, daysAgo: 180, mileageOffset: -9500, cost: 25.00, context: context)
            addService(to: camry, type: .oilChange, daysAgo: 230, mileageOffset: -12000, cost: 74.99, context: context)
            addService(to: camry, type: .transmissionFluid, daysAgo: 300, mileageOffset: -15800, cost: 185.00, context: context)

            // Camry fuel logs — for efficiency chart
            addFuel(to: camry, daysAgo: 3, mileageOffset: -280, gallons: 12.5, pricePerGal: 3.89, context: context)
            addFuel(to: camry, daysAgo: 14, mileageOffset: -520, gallons: 11.8, pricePerGal: 3.79, context: context)
            addFuel(to: camry, daysAgo: 26, mileageOffset: -810, gallons: 12.2, pricePerGal: 3.85, context: context)
            addFuel(to: camry, daysAgo: 38, mileageOffset: -1080, gallons: 12.0, pricePerGal: 3.75, context: context)
            addFuel(to: camry, daysAgo: 51, mileageOffset: -1350, gallons: 11.6, pricePerGal: 3.92, context: context)

            // MARK: - Vehicle 2: Honda Civic 2020 (secondary — daily driver)

            let civic = Vehicle(make: "Honda", model: "Civic", year: 2020, mileage: 68450)
            civic.licensePlate = "XYZ 5678"
            civic.vin = "2HGFC2F59LH123456"
            civic.colorRaw = VehicleColor.red.rawValue
            civic.dateAdded = cal.safeDate(byAdding: .month, value: -9, to: now)
            civic.purchaseDate = cal.safeDate(byAdding: .year, value: -4, to: now)
            civic.purchasePrice = 22800
            context.insert(civic)

            addService(to: civic, type: .oilChange, daysAgo: 18, mileageOffset: -850, cost: 65.99, context: context)
            addService(to: civic, type: .tireRotation, daysAgo: 60, mileageOffset: -2800, cost: 40.00, context: context)
            addService(to: civic, type: .cabinAirFilter, daysAgo: 95, mileageOffset: -4500, cost: 28.50, context: context)

            addFuel(to: civic, daysAgo: 5, mileageOffset: -320, gallons: 10.2, pricePerGal: 3.82, context: context)
            addFuel(to: civic, daysAgo: 18, mileageOffset: -620, gallons: 10.5, pricePerGal: 3.89, context: context)
            addFuel(to: civic, daysAgo: 32, mileageOffset: -920, gallons: 10.1, pricePerGal: 3.75, context: context)

            // MARK: - Vehicle 3: BMW X5 2024 (premium — recent purchase)

            let x5 = Vehicle(make: "BMW", model: "X5", year: 2024, mileage: 12150)
            x5.licensePlate = "GR8 CAR"
            x5.vin = "5UXCR6C08P9123456"
            x5.colorRaw = VehicleColor.black.rawValue
            x5.dateAdded = cal.safeDate(byAdding: .month, value: -4, to: now)
            x5.purchaseDate = cal.safeDate(byAdding: .month, value: -5, to: now)
            x5.purchasePrice = 68900
            context.insert(x5)

            addService(to: x5, type: .oilChange, daysAgo: 12, mileageOffset: -380, cost: 145.00, context: context)
            addService(to: x5, type: .tireRotation, daysAgo: 68, mileageOffset: -2400, cost: 95.00, context: context)

            addFuel(to: x5, daysAgo: 4, mileageOffset: -290, gallons: 18.5, pricePerGal: 4.29, context: context)
            addFuel(to: x5, daysAgo: 19, mileageOffset: -680, gallons: 17.8, pricePerGal: 4.15, context: context)

            // Save all
            try? context.save()
        }

        // MARK: - Helpers

        @MainActor
        private static func addService(
            to vehicle: Vehicle,
            type: ServiceType,
            daysAgo: Int,
            mileageOffset: Int,
            cost: Double,
            context: ModelContext
        ) {
            let cal = Calendar.current
            let record = ServiceRecord(
                serviceType: type,
                date: cal.safeDate(byAdding: .day, value: -daysAgo, to: .now),
                mileage: vehicle.currentMileage + mileageOffset,
                cost: cost
            )
            record.vehicle = vehicle
            context.insert(record)
        }

        @MainActor
        private static func addFuel(
            to vehicle: Vehicle,
            daysAgo: Int,
            mileageOffset: Int,
            gallons: Double,
            pricePerGal: Double,
            context: ModelContext
        ) {
            let cal = Calendar.current
            let log = FuelLog(
                date: cal.safeDate(byAdding: .day, value: -daysAgo, to: .now),
                mileage: vehicle.currentMileage + mileageOffset,
                volume: gallons,
                totalCost: gallons * pricePerGal,
                pricePerUnit: pricePerGal,
                fuelType: .regular,
                station: "Shell",
                isFullTank: true
            )
            log.vehicle = vehicle
            context.insert(log)
        }
    }
#endif
