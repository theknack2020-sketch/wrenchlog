import Foundation
import SwiftUI

// MARK: - Service Category & Type

enum ServiceCategory: String, Codable, CaseIterable, Identifiable {
    case engineFluids = "Engine & Fluids"
    case tiresBrakes = "Tires & Brakes"
    case filtersBelts = "Filters & Belts"
    case electrical = "Electrical & Battery"
    case inspection = "Inspection & Other"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .engineFluids: "drop.fill"
        case .tiresBrakes: "tire.fill"
        case .filtersBelts: "wind"
        case .electrical: "bolt.fill"
        case .inspection: "checkmark.shield.fill"
        case .custom: "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch self {
        case .engineFluids: .catEngine
        case .tiresBrakes: .catTires
        case .filtersBelts: .catFilters
        case .electrical: .catElectrical
        case .inspection: .catInspection
        case .custom: .catCustom
        }
    }
}

enum ServiceType: String, Codable, CaseIterable, Identifiable {
    // Engine & Fluids
    case oilChange = "Oil Change"
    case transmissionFluid = "Transmission Fluid"
    case coolantFlush = "Coolant Flush"
    case brakeFluid = "Brake Fluid"
    case powerSteeringFluid = "Power Steering Fluid"

    // Tires & Brakes
    case tireRotation = "Tire Rotation"
    case tireReplacement = "Tire Replacement"
    case wheelAlignment = "Wheel Alignment"
    case brakePads = "Brake Pads"
    case brakeRotors = "Brake Rotors"

    // Filters & Belts
    case airFilter = "Air Filter"
    case cabinAirFilter = "Cabin Air Filter"
    case fuelFilter = "Fuel Filter"
    case serpentineBelt = "Serpentine Belt"
    case timingBelt = "Timing Belt"

    // Electrical & Battery
    case batteryReplacement = "Battery Replacement"
    case sparkPlugs = "Spark Plugs"
    case alternator = "Alternator"

    // Inspection & Other
    case stateInspection = "State Inspection"
    case wiperBlades = "Wiper Blades"
    case acService = "A/C Service"
    case generalRepair = "General Repair"

    var id: String { rawValue }

    var category: ServiceCategory {
        switch self {
        case .oilChange, .transmissionFluid, .coolantFlush, .brakeFluid, .powerSteeringFluid:
            return .engineFluids
        case .tireRotation, .tireReplacement, .wheelAlignment, .brakePads, .brakeRotors:
            return .tiresBrakes
        case .airFilter, .cabinAirFilter, .fuelFilter, .serpentineBelt, .timingBelt:
            return .filtersBelts
        case .batteryReplacement, .sparkPlugs, .alternator:
            return .electrical
        case .stateInspection, .wiperBlades, .acService, .generalRepair:
            return .inspection
        }
    }

    var icon: String { category.icon }
    var color: Color { category.color }

    /// Default reminder interval in miles (0 = no default)
    var defaultMileageInterval: Int {
        switch self {
        case .oilChange: 5000
        case .tireRotation: 7500
        case .airFilter: 15000
        case .cabinAirFilter: 15000
        case .sparkPlugs: 30000
        case .transmissionFluid: 30000
        case .coolantFlush: 30000
        case .brakeFluid: 30000
        case .brakePads: 25000
        case .serpentineBelt: 60000
        case .timingBelt: 60000
        default: 0
        }
    }

    /// Default reminder interval in months (0 = no default)
    var defaultMonthInterval: Int {
        switch self {
        case .oilChange: 6
        case .tireRotation: 6
        case .airFilter: 12
        case .cabinAirFilter: 12
        case .stateInspection: 12
        case .wiperBlades: 12
        case .brakeFluid: 24
        case .coolantFlush: 24
        case .batteryReplacement: 48
        default: 0
        }
    }

    static func types(for category: ServiceCategory) -> [ServiceType] {
        allCases.filter { $0.category == category }
    }
}

// MARK: - Unit System

enum DistanceUnit: String, Codable, CaseIterable {
    case miles, km

    var label: String {
        switch self {
        case .miles: "mi"
        case .km: "km"
        }
    }
}

enum VolumeUnit: String, Codable, CaseIterable {
    case gallons, liters

    var label: String {
        switch self {
        case .gallons: "gal"
        case .liters: "L"
        }
    }
}

enum Currency: String, Codable, CaseIterable {
    case usd, eur, gbp, try_

    var symbol: String {
        switch self {
        case .usd: "$"
        case .eur: "€"
        case .gbp: "£"
        case .try_: "₺"
        }
    }
}
