import SwiftUI

// MARK: - Color Palette Generation (Programmatic HSB)

extension Color {
    /// Creates a color from HSB values (hue 0-360, saturation 0-100, brightness 0-100).
    static func hsb(_ h: Double, _ s: Double, _ b: Double) -> Color {
        Color(hue: h / 360, saturation: s / 100, brightness: b / 100)
    }

    /// Generates a full 9-shade tonal scale from a base HSB color.
    /// Shade 50 is lightest, 900 is darkest. The base lands near 500.
    /// In dark mode, the scale inverts: 50 is darkest tint, 900 is lightest.
    struct TonalScale {
        let shade50:  Color
        let shade100: Color
        let shade200: Color
        let shade300: Color
        let shade400: Color
        let shade500: Color
        let shade600: Color
        let shade700: Color
        let shade800: Color
        let shade900: Color

        /// Access by index (50, 100, 200 ... 900)
        subscript(shade: Int) -> Color {
            switch shade {
            case 50:  return shade50
            case 100: return shade100
            case 200: return shade200
            case 300: return shade300
            case 400: return shade400
            case 500: return shade500
            case 600: return shade600
            case 700: return shade700
            case 800: return shade800
            case 900: return shade900
            default:  return shade500
            }
        }

        /// Generates a tonal scale from a base hue + saturation.
        /// - Parameters:
        ///   - hue: 0-360
        ///   - saturation: base saturation 0-100 (modulated per shade)
        ///   - brightness: base brightness 0-100 (the 500 value)
        static func generate(hue h: Double, saturation s: Double, brightness b: Double) -> TonalScale {
            // Saturation increases toward darker shades, decreases toward lighter
            // Brightness decreases toward darker shades
            TonalScale(
                shade50:  .hsb(h, max(s - 35, 5),  min(b + 42, 99)),
                shade100: .hsb(h, max(s - 25, 8),  min(b + 33, 97)),
                shade200: .hsb(h, max(s - 15, 12), min(b + 22, 95)),
                shade300: .hsb(h, max(s - 8, 18),  min(b + 12, 92)),
                shade400: .hsb(h, max(s - 3, 25),  min(b + 5, 88)),
                shade500: .hsb(h, s,                b),
                shade600: .hsb(h, min(s + 5, 95),   max(b - 10, 15)),
                shade700: .hsb(h, min(s + 10, 95),  max(b - 22, 12)),
                shade800: .hsb(h, min(s + 12, 90),  max(b - 35, 10)),
                shade900: .hsb(h, min(s + 10, 85),  max(b - 48, 8))
            )
        }
    }
}

// MARK: - Brand Accent Palettes (per theme)

extension Color {
    /// Amber palette — WrenchLog brand primary
    static let amber = TonalScale.generate(hue: 38, saturation: 90, brightness: 92)

    /// Ocean blue palette
    static let ocean = TonalScale.generate(hue: 212, saturation: 76, brightness: 85)

    /// Mono/steel palette (low saturation)
    static let mono = TonalScale.generate(hue: 240, saturation: 6, brightness: 68)

    /// Forest green palette
    static let forest = TonalScale.generate(hue: 152, saturation: 72, brightness: 62)

    /// Sunset rose palette
    static let rose = TonalScale.generate(hue: 352, saturation: 60, brightness: 85)
}

// MARK: - Neutral Palette (warm-tinted grays with amber undertone)

extension Color {
    /// Warm neutral palette — grays with subtle amber undertone for cohesive feel
    struct Neutral {
        static let shade50  = Color.hsb(35, 4, 98)   // near-white warm
        static let shade100 = Color.hsb(35, 5, 95)   // lightest gray
        static let shade200 = Color.hsb(35, 5, 88)
        static let shade300 = Color.hsb(35, 4, 78)
        static let shade400 = Color.hsb(35, 4, 64)
        static let shade500 = Color.hsb(35, 3, 50)
        static let shade600 = Color.hsb(35, 4, 38)
        static let shade700 = Color.hsb(35, 5, 26)
        static let shade800 = Color.hsb(35, 6, 16)   // deep charcoal
        static let shade900 = Color.hsb(35, 7, 10)   // near-black warm

        /// Surface color — adapts to color scheme
        @MainActor static var surface: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(Neutral.shade800)
                    : UIColor(Neutral.shade50)
            })
        }

        /// Card background — slightly elevated from surface
        @MainActor static var card: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(Neutral.shade700)
                    : UIColor.secondarySystemGroupedBackground
            })
        }

        /// Divider / separator
        @MainActor static var divider: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(Neutral.shade600.opacity(0.5))
                    : UIColor(Neutral.shade200)
            })
        }
    }
}

// MARK: - Status Colors (full shade sets)

extension Color {
    struct Status {
        /// Success green — H:145
        static let success = TonalScale.generate(hue: 145, saturation: 72, brightness: 78)

        /// Warning amber — H:42
        static let warning = TonalScale.generate(hue: 42, saturation: 85, brightness: 85)

        /// Error red — H:4
        static let error = TonalScale.generate(hue: 4, saturation: 78, brightness: 90)

        /// Info blue — H:210
        static let info = TonalScale.generate(hue: 210, saturation: 70, brightness: 88)

        // Convenience adaptive colors (dark mode aware)
        @MainActor static var successAdaptive: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(success.shade300) : UIColor(success.shade600)
            })
        }
        @MainActor static var warningAdaptive: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(warning.shade300) : UIColor(warning.shade600)
            })
        }
        @MainActor static var errorAdaptive: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(error.shade300) : UIColor(error.shade600)
            })
        }
        @MainActor static var infoAdaptive: Color {
            Color(UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(info.shade300) : UIColor(info.shade600)
            })
        }
    }
}

// MARK: - Theme-aware accent (using new palettes)

extension Color {
    /// Primary accent — resolves to the current theme's accent color.
    @MainActor static var wrenchAccent: Color {
        ThemeManager.shared.current.accent
    }

    /// Lighter variant of accent.
    @MainActor static var wrenchAccentLight: Color {
        ThemeManager.shared.current.accentLight
    }
}

// MARK: - Legacy Colors (deprecated — migrate to palettes)

extension Color {
    @available(*, deprecated, message: "Use Color.amber.shade500 or theme accent instead")
    static let wrenchAmber = Color(red: 0.91, green: 0.64, blue: 0.09)

    @available(*, deprecated, message: "Use Color.amber.shade400 or theme accentLight instead")
    static let wrenchAmberLight = Color(red: 1.0, green: 0.71, blue: 0.15)

    @available(*, deprecated, message: "Use Color.Neutral.shade800 instead")
    static let wrenchCharcoal = Color(red: 0.12, green: 0.12, blue: 0.14)

    @available(*, deprecated, message: "Use Color.Neutral.surface instead")
    static let wrenchSurface = Color(red: 0.17, green: 0.17, blue: 0.19)

    @available(*, deprecated, message: "Use Color.Neutral.card instead")
    static let wrenchCardBg = Color(.secondarySystemGroupedBackground)

    @available(*, deprecated, message: "Use Color.Status.success.shade500 instead")
    static let wrenchGreen = Color(red: 0.20, green: 0.78, blue: 0.35)

    @available(*, deprecated, message: "Use Color.Status.warning.shade500 instead")
    static let wrenchYellow = Color(red: 0.85, green: 0.65, blue: 0.0)

    @available(*, deprecated, message: "Use Color.Status.error.shade500 instead")
    static let wrenchRed = Color(red: 0.90, green: 0.22, blue: 0.21)
}

// MARK: - Category colors for charts (unchanged — domain-specific)

extension Color {
    static let catEngine = Color(red: 0.35, green: 0.55, blue: 0.85)
    static let catTires = Color(red: 0.30, green: 0.75, blue: 0.45)
    static let catFilters = Color(red: 0.85, green: 0.55, blue: 0.25)
    static let catElectrical = Color(red: 0.70, green: 0.40, blue: 0.80)
    static let catInspection = Color(red: 0.50, green: 0.50, blue: 0.55)
    static let catCustom = Color(red: 0.60, green: 0.60, blue: 0.65)
}

// MARK: - Fuel type colors (unchanged)

extension Color {
    static let catFuel = Color(red: 0.20, green: 0.65, blue: 0.55)
    static let catFuelRegular = Color(red: 0.30, green: 0.70, blue: 0.50)
    static let catFuelMidgrade = Color(red: 0.40, green: 0.65, blue: 0.45)
    static let catFuelPremium = Color(red: 0.85, green: 0.60, blue: 0.15)
    static let catFuelDiesel = Color(red: 0.50, green: 0.45, blue: 0.40)
    static let catFuelE85 = Color(red: 0.35, green: 0.75, blue: 0.30)
    static let catFuelEV = Color(red: 0.30, green: 0.55, blue: 0.85)
}

// MARK: - Vehicle colors (unchanged)

extension Color {
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
