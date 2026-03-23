import SwiftUI

extension Color {
    // MARK: - Theme-aware accent

    /// Primary accent — resolves to the current theme's accent color.
    @MainActor static var wrenchAccent: Color {
        ThemeManager.shared.current.accent
    }

    /// Lighter variant of accent.
    @MainActor static var wrenchAccentLight: Color {
        ThemeManager.shared.current.accentLight
    }

    // MARK: - Legacy amber (kept for backwards compat in theme-unaware code paths)

    static let wrenchAmber = Color(red: 0.91, green: 0.64, blue: 0.09)
    static let wrenchAmberLight = Color(red: 1.0, green: 0.71, blue: 0.15)

    // MARK: - Neutrals

    static let wrenchCharcoal = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let wrenchSurface = Color(red: 0.17, green: 0.17, blue: 0.19)
    static let wrenchCardBg = Color(.secondarySystemGroupedBackground)

    // MARK: - Status colors (high contrast)

    static let wrenchGreen = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let wrenchYellow = Color(red: 0.85, green: 0.65, blue: 0.0)  // darkened for contrast
    static let wrenchRed = Color(red: 0.90, green: 0.22, blue: 0.21)

    // MARK: - Category colors for charts

    static let catEngine = Color(red: 0.35, green: 0.55, blue: 0.85)
    static let catTires = Color(red: 0.30, green: 0.75, blue: 0.45)
    static let catFilters = Color(red: 0.85, green: 0.55, blue: 0.25)
    static let catElectrical = Color(red: 0.70, green: 0.40, blue: 0.80)
    static let catInspection = Color(red: 0.50, green: 0.50, blue: 0.55)
    static let catCustom = Color(red: 0.60, green: 0.60, blue: 0.65)

    // MARK: - Fuel type colors

    static let catFuel = Color(red: 0.20, green: 0.65, blue: 0.55)
    static let catFuelRegular = Color(red: 0.30, green: 0.70, blue: 0.50)
    static let catFuelMidgrade = Color(red: 0.40, green: 0.65, blue: 0.45)
    static let catFuelPremium = Color(red: 0.85, green: 0.60, blue: 0.15)
    static let catFuelDiesel = Color(red: 0.50, green: 0.45, blue: 0.40)
    static let catFuelE85 = Color(red: 0.35, green: 0.75, blue: 0.30)
    static let catFuelEV = Color(red: 0.30, green: 0.55, blue: 0.85)

    // MARK: - Vehicle colors (for indicator)

    static let vehicleBlack = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let vehicleWhite = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let vehicleSilver = Color(red: 0.75, green: 0.75, blue: 0.78)
    static let vehicleGray = Color(red: 0.55, green: 0.55, blue: 0.58)
    static let vehicleRed = Color(red: 0.85, green: 0.18, blue: 0.15)
    static let vehicleBlue = Color(red: 0.20, green: 0.40, blue: 0.80)
    static let vehicleGreen = Color(red: 0.18, green: 0.60, blue: 0.30)
    static let vehicleNavy = Color(red: 0.10, green: 0.15, blue: 0.40)
    static let vehicleBrown = Color(red: 0.45, green: 0.30, blue: 0.18)
    static let vehicleGold = Color(red: 0.78, green: 0.65, blue: 0.20)
    static let vehicleOrange = Color(red: 0.90, green: 0.50, blue: 0.10)
    static let vehicleYellow = Color(red: 0.92, green: 0.80, blue: 0.15)
}

// MARK: - Vehicle Color Enum

enum VehicleColor: String, CaseIterable, Identifiable {
    case black = "Black"
    case white = "White"
    case silver = "Silver"
    case gray = "Gray"
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case navy = "Navy"
    case brown = "Brown"
    case gold = "Gold"
    case orange = "Orange"
    case yellow = "Yellow"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .black: .vehicleBlack
        case .white: .vehicleWhite
        case .silver: .vehicleSilver
        case .gray: .vehicleGray
        case .red: .vehicleRed
        case .blue: .vehicleBlue
        case .green: .vehicleGreen
        case .navy: .vehicleNavy
        case .brown: .vehicleBrown
        case .gold: .vehicleGold
        case .orange: .vehicleOrange
        case .yellow: .vehicleYellow
        }
    }

    var needsBorder: Bool {
        self == .white || self == .yellow
    }
}
