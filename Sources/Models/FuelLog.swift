import Foundation
import SwiftData
import SwiftUI

// MARK: - Fuel Type

enum FuelType: String, Codable, CaseIterable, Identifiable {
    case regular = "Regular"
    case midgrade = "Mid-Grade"
    case premium = "Premium"
    case diesel = "Diesel"
    case e85 = "E85"
    case ev = "EV (Electric)"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .regular: "fuelpump.fill"
        case .midgrade: "fuelpump.fill"
        case .premium: "fuelpump.circle.fill"
        case .diesel: "fuelpump.arrowtriangle.right.fill"
        case .e85: "leaf.fill"
        case .ev: "bolt.car.fill"
        }
    }

    var color: Color {
        switch self {
        case .regular: .catFuelRegular
        case .midgrade: .catFuelMidgrade
        case .premium: .catFuelPremium
        case .diesel: .catFuelDiesel
        case .e85: .catFuelE85
        case .ev: .catFuelEV
        }
    }

    var shortLabel: String {
        switch self {
        case .regular: "REG"
        case .midgrade: "MID"
        case .premium: "PREM"
        case .diesel: "DSL"
        case .e85: "E85"
        case .ev: "EV"
        }
    }

    /// Unit label for the volume field — "kWh" for EV, otherwise the user's volume unit label.
    func volumeLabel(fallback: VolumeUnit) -> String {
        self == .ev ? "kWh" : fallback.label
    }

    /// Whether this fuel type represents electric charging (kWh-based).
    var isElectric: Bool { self == .ev }
}

// MARK: - Efficiency Unit

enum EfficiencyUnit: String, Codable, CaseIterable {
    case mpg       // Miles per gallon
    case l100km    // Liters per 100 km

    var label: String {
        switch self {
        case .mpg: "MPG"
        case .l100km: "L/100km"
        }
    }

    var description: String {
        switch self {
        case .mpg: "Miles per gallon"
        case .l100km: "Liters per 100 km"
        }
    }
}

// MARK: - Fuel Log Model

@Model
final class FuelLog {
    var id: UUID = UUID()
    var date: Date = Date.now
    var mileage: Int = 0
    var volume: Double = 0          // gallons or liters (stored in user's preferred unit)
    var totalCost: Double = 0       // total cost for this fill-up
    var pricePerUnit: Double = 0    // price per gallon/liter
    var fuelTypeRaw: String = "Regular"     // FuelType.rawValue
    var station: String = ""
    var isFullTank: Bool = true        // needed for accurate MPG calculation
    var notes: String = ""
    var volumeUnitRaw: String = "gallons"   // "gallons" or "liters" — unit at time of entry

    var vehicle: Vehicle?

    var fuelType: FuelType {
        FuelType(rawValue: fuelTypeRaw) ?? .regular
    }

    var volumeUnit: VolumeUnit {
        VolumeUnit(rawValue: volumeUnitRaw) ?? .gallons
    }

    /// Volume converted to gallons for consistent MPG calculation
    var volumeInGallons: Double {
        if volumeUnit == .liters {
            return volume / 3.78541
        }
        return volume
    }

    /// Volume converted to liters for consistent L/100km calculation
    var volumeInLiters: Double {
        if volumeUnit == .gallons {
            return volume * 3.78541
        }
        return volume
    }

    init(
        date: Date = .now,
        mileage: Int = 0,
        volume: Double = 0,
        totalCost: Double = 0,
        pricePerUnit: Double = 0,
        fuelType: FuelType = .regular,
        station: String = "",
        isFullTank: Bool = true,
        notes: String = "",
        volumeUnit: VolumeUnit = .gallons
    ) {
        self.id = UUID()
        self.date = date
        self.mileage = mileage
        self.volume = volume
        self.totalCost = totalCost
        self.pricePerUnit = pricePerUnit
        self.fuelTypeRaw = fuelType.rawValue
        self.station = station
        self.isFullTank = isFullTank
        self.notes = notes
        self.volumeUnitRaw = volumeUnit.rawValue
    }
}

// MARK: - Fuel Efficiency Calculation

struct FuelEfficiencyResult: Identifiable {
    let id = UUID()
    let date: Date
    let mileage: Int
    let distance: Int
    let volume: Double          // in gallons
    let mpg: Double
    let l100km: Double
    let costPerMile: Double
    let costPerKm: Double
    let totalCost: Double

    func efficiency(for unit: EfficiencyUnit) -> Double {
        switch unit {
        case .mpg: mpg
        case .l100km: l100km
        }
    }

    func costPerDistance(for unit: DistanceUnit) -> Double {
        switch unit {
        case .miles: costPerMile
        case .km: costPerKm
        }
    }
}

extension Array where Element == FuelLog {

    /// Calculate efficiency between consecutive full-tank fill-ups.
    /// Only full-tank fills produce valid MPG/L100km readings.
    func calculateEfficiency() -> [FuelEfficiencyResult] {
        let sorted = self
            .filter { $0.isFullTank && $0.mileage > 0 && $0.volume > 0 }
            .sorted { $0.mileage < $1.mileage }

        guard sorted.count >= 2 else { return [] }

        var results: [FuelEfficiencyResult] = []
        for i in 1..<sorted.count {
            let current = sorted[i]
            let previous = sorted[i - 1]
            let distanceMiles = current.mileage - previous.mileage

            guard distanceMiles > 0 else { continue }

            let gallons = current.volumeInGallons
            guard gallons > 0 else { continue }

            let mpg = Double(distanceMiles) / gallons
            let distanceKm = Double(distanceMiles) * 1.60934
            let liters = current.volumeInLiters
            let l100km = distanceKm > 0 ? (liters / distanceKm) * 100.0 : 0

            let costPerMile = current.totalCost > 0 ? current.totalCost / Double(distanceMiles) : 0
            let costPerKm = distanceKm > 0 ? current.totalCost / distanceKm : 0

            results.append(FuelEfficiencyResult(
                date: current.date,
                mileage: current.mileage,
                distance: distanceMiles,
                volume: gallons,
                mpg: mpg,
                l100km: l100km,
                costPerMile: costPerMile,
                costPerKm: costPerKm,
                totalCost: current.totalCost
            ))
        }
        return results
    }
}
