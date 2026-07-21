import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case defaultAmber = "Default Amber"
    case oceanBlue = "Ocean Blue"
    case darkMono = "Dark Mono"
    case forestGreen = "Forest Green"
    case sunsetRose = "Sunset Rose"

    var id: String { rawValue }

    /// Short label for tight UI (theme picker chips) — raw values are persisted
    /// in UserDefaults and must not change, so display naming lives here.
    var displayName: String {
        switch self {
        case .defaultAmber: "Amber"
        case .oceanBlue:    "Ocean"
        case .darkMono:     "Mono"
        case .forestGreen:  "Forest"
        case .sunsetRose:   "Rose"
        }
    }

    // MARK: - Accent Palette Access

    /// Full 9-shade tonal scale for this theme's accent.
    var accentPalette: Color.TonalScale {
        switch self {
        case .defaultAmber: Color.amber
        case .oceanBlue:    Color.ocean
        case .darkMono:     Color.mono
        case .forestGreen:  Color.forest
        case .sunsetRose:   Color.rose
        }
    }

    var accent: Color { accentPalette.shade500 }
    var accentLight: Color { accentPalette.shade400 }

    /// Foreground for text/glyphs ON the accent color. Every palette's bright
    /// shade500 fails WCAG-AA with white (2.2–4.0:1 measured); these hue-tinted
    /// near-black inks clear ≥5:1 on all five accents.
    var onAccent: Color {
        switch self {
        case .defaultAmber: Color.amberInk
        case .oceanBlue:    Color(red: 0.063, green: 0.099, blue: 0.140)
        case .darkMono:     Color(red: 0.063, green: 0.063, blue: 0.140)
        case .forestGreen:  Color(red: 0.063, green: 0.140, blue: 0.104)
        case .sunsetRose:   Color(red: 0.140, green: 0.063, blue: 0.073)
        }
    }

    var icon: String {
        switch self {
        case .defaultAmber: "sun.max.fill"
        case .oceanBlue:    "water.waves"
        case .darkMono:     "moon.fill"
        case .forestGreen:  "leaf.fill"
        case .sunsetRose:   "sunrise.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .darkMono: .dark
        default: nil
        }
    }

    // MARK: - Gradients

    /// Primary gradient for headers, banners, and CTA buttons
    var headerGradient: [Color] {
        [accentPalette.shade500, accentPalette.shade700]
    }

    /// Softer gradient for section backgrounds and cards
    var sectionGradient: [Color] {
        switch self {
        case .darkMono:
            [Color.Neutral.shade700, Color.Neutral.shade800]
        default:
            [accentPalette.shade500.opacity(0.15), accentPalette.shade500.opacity(0.05)]
        }
    }

    /// Card-specific gradient — subtle shimmer for elevated surfaces
    var cardGradient: [Color] {
        switch self {
        case .darkMono:
            [Color.Neutral.shade700.opacity(0.8), Color.Neutral.shade800.opacity(0.6)]
        default:
            [accentPalette.shade50.opacity(0.6), accentPalette.shade100.opacity(0.3)]
        }
    }

    // MARK: - Surface & Text Colors (programmatic dark mode)

    /// Main background surface — light in light mode, dark in dark mode
    var surfaceColor: Color {
        Color(UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(Color.Neutral.shade900)
            }
            return UIColor(Color.Neutral.shade50)
        })
    }

    /// Primary text — high contrast
    var textPrimary: Color {
        Color(UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(Color.Neutral.shade100)
            }
            return UIColor(Color.Neutral.shade900)
        })
    }

    /// Secondary text — medium contrast for descriptions, timestamps
    var textSecondary: Color {
        Color(UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(Color.Neutral.shade400)
            }
            return UIColor(Color.Neutral.shade600)
        })
    }

    /// Tertiary text — low contrast for hints, captions, disabled states
    var textTertiary: Color {
        Color(UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(Color.Neutral.shade500)
            }
            return UIColor(Color.Neutral.shade400)
        })
    }
}

// MARK: - Theme Manager

@Observable @MainActor
final class ThemeManager {
    static let shared = ThemeManager()

    var current: AppTheme {
        get {
            AppTheme(rawValue: UserDefaults.standard.string(forKey: "wl_theme") ?? "") ?? .defaultAmber
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "wl_theme")
        }
    }

    private init() {}
}

// MARK: - Theme Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .defaultAmber
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
