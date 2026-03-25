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

    /// Unique icon per service type for visual distinction
    var uniqueIcon: String {
        switch self {
        case .oilChange: "drop.fill"
        case .transmissionFluid: "gearshape.fill"
        case .coolantFlush: "thermometer.medium"
        case .brakeFluid: "drop.triangle.fill"
        case .powerSteeringFluid: "steeringwheel"
        case .tireRotation: "arrow.triangle.2.circlepath"
        case .tireReplacement: "tire.fill"
        case .wheelAlignment: "arrow.left.arrow.right"
        case .brakePads: "exclamationmark.octagon.fill"
        case .brakeRotors: "circle.circle.fill"
        case .airFilter: "wind"
        case .cabinAirFilter: "aqi.medium"
        case .fuelFilter: "fuelpump.fill"
        case .serpentineBelt: "link"
        case .timingBelt: "clock.arrow.2.circlepath"
        case .batteryReplacement: "battery.100percent.bolt"
        case .sparkPlugs: "bolt.fill"
        case .alternator: "bolt.circle.fill"
        case .stateInspection: "checkmark.shield.fill"
        case .wiperBlades: "windshield.front.and.wiper"
        case .acService: "snowflake"
        case .generalRepair: "wrench.and.screwdriver.fill"
        }
    }

    /// Default reminder interval in miles (0 = no default / time-only)
    var defaultMileageInterval: Int {
        switch self {
        // Engine & Fluids
        case .oilChange: 5000
        case .transmissionFluid: 30000
        case .coolantFlush: 30000
        case .brakeFluid: 30000
        case .powerSteeringFluid: 30000
        // Tires & Brakes
        case .tireRotation: 7500
        case .tireReplacement: 40000
        case .wheelAlignment: 15000
        case .brakePads: 25000
        case .brakeRotors: 50000
        // Filters & Belts
        case .airFilter: 15000
        case .cabinAirFilter: 15000
        case .fuelFilter: 30000
        case .serpentineBelt: 60000
        case .timingBelt: 60000
        // Electrical
        case .batteryReplacement: 50000
        case .sparkPlugs: 30000
        case .alternator: 100000
        // Inspection & Other — time-only or no mileage default
        case .stateInspection: 0
        case .wiperBlades: 0
        case .acService: 0
        case .generalRepair: 0
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

    /// Common parts/products used for each service type — powers autocomplete suggestions
    var recommendedParts: [String] {
        switch self {
        case .oilChange:
            return ["Oil filter", "Drain plug gasket"]
        case .transmissionFluid:
            return ["Transmission filter", "Pan gasket"]
        case .coolantFlush:
            return ["Thermostat", "Radiator cap", "Coolant hoses"]
        case .brakeFluid:
            return ["Brake fluid reservoir cap"]
        case .powerSteeringFluid:
            return ["Power steering filter"]
        case .tireRotation:
            return ["Lug nuts"]
        case .tireReplacement:
            return ["Tire (x4)", "Tire (x2)", "Valve stems", "TPMS sensors"]
        case .wheelAlignment:
            return ["Tie rod ends", "Control arm bushings"]
        case .brakePads:
            return ["Brake pads (front)", "Brake pads (rear)", "Brake hardware kit", "Brake grease"]
        case .brakeRotors:
            return ["Brake rotors (front)", "Brake rotors (rear)", "Brake pads (front)", "Brake pads (rear)"]
        case .airFilter:
            return ["Engine air filter"]
        case .cabinAirFilter:
            return ["Cabin air filter"]
        case .fuelFilter:
            return ["Fuel filter"]
        case .serpentineBelt:
            return ["Serpentine belt", "Belt tensioner"]
        case .timingBelt:
            return ["Timing belt kit", "Water pump", "Tensioner pulley", "Idler pulley"]
        case .batteryReplacement:
            return ["Battery", "Battery terminals", "Battery hold-down"]
        case .sparkPlugs:
            return ["Spark plugs (x4)", "Spark plugs (x6)", "Ignition coils"]
        case .alternator:
            return ["Alternator", "Serpentine belt"]
        case .stateInspection:
            return []
        case .wiperBlades:
            return ["Wiper blade (driver)", "Wiper blade (passenger)", "Rear wiper blade"]
        case .acService:
            return ["Refrigerant (R-134a)", "Refrigerant (R-1234yf)", "Cabin air filter", "Compressor oil"]
        case .generalRepair:
            return []
        }
    }

    /// Common oil types/specs — shown when service involves oil
    static let commonOilTypes: [String] = [
        "0W-20 Full Synthetic",
        "5W-20 Full Synthetic",
        "5W-30 Full Synthetic",
        "5W-30 Synthetic Blend",
        "5W-30 Conventional",
        "5W-40 Full Synthetic",
        "10W-30 Conventional",
        "10W-40 Conventional",
        "0W-16 Full Synthetic",
        "High Mileage 5W-30",
        "Diesel 5W-40",
        "Diesel 15W-40"
    ]

    /// Whether this service type typically involves an oil change
    var involvesOil: Bool {
        switch self {
        case .oilChange, .transmissionFluid, .powerSteeringFluid:
            return true
        default:
            return false
        }
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
