import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case defaultAmber = "Default Amber"
    case oceanBlue = "Ocean Blue"
    case darkMono = "Dark Mono"
    case forestGreen = "Forest Green"
    case sunsetRose = "Sunset Rose"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .defaultAmber: Color(red: 0.91, green: 0.64, blue: 0.09)
        case .oceanBlue: Color(red: 0.20, green: 0.55, blue: 0.85)
        case .darkMono: Color(red: 0.65, green: 0.65, blue: 0.68)
        case .forestGreen: Color(red: 0.18, green: 0.62, blue: 0.38)
        case .sunsetRose: Color(red: 0.85, green: 0.35, blue: 0.42)
        }
    }

    var accentLight: Color {
        switch self {
        case .defaultAmber: Color(red: 1.0, green: 0.71, blue: 0.15)
        case .oceanBlue: Color(red: 0.35, green: 0.68, blue: 0.95)
        case .darkMono: Color(red: 0.78, green: 0.78, blue: 0.80)
        case .forestGreen: Color(red: 0.30, green: 0.75, blue: 0.50)
        case .sunsetRose: Color(red: 0.95, green: 0.50, blue: 0.55)
        }
    }

    var icon: String {
        switch self {
        case .defaultAmber: "sun.max.fill"
        case .oceanBlue: "water.waves"
        case .darkMono: "moon.fill"
        case .forestGreen: "leaf.fill"
        case .sunsetRose: "sunrise.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .defaultAmber: nil
        case .oceanBlue: nil
        case .darkMono: .dark
        case .forestGreen: nil
        case .sunsetRose: nil
        }
    }

    /// Primary gradient for headers, banners, and CTA buttons
    var headerGradient: [Color] {
        switch self {
        case .defaultAmber: [Color(red: 0.91, green: 0.64, blue: 0.09), Color(red: 0.85, green: 0.55, blue: 0.05)]
        case .oceanBlue: [Color(red: 0.15, green: 0.45, blue: 0.80), Color(red: 0.25, green: 0.60, blue: 0.90)]
        case .darkMono: [Color(red: 0.30, green: 0.30, blue: 0.34), Color(red: 0.20, green: 0.20, blue: 0.24)]
        case .forestGreen: [Color(red: 0.12, green: 0.55, blue: 0.32), Color(red: 0.22, green: 0.70, blue: 0.42)]
        case .sunsetRose: [Color(red: 0.85, green: 0.30, blue: 0.38), Color(red: 0.92, green: 0.50, blue: 0.45)]
        }
    }

    /// Softer gradient for section backgrounds and cards
    var sectionGradient: [Color] {
        switch self {
        case .defaultAmber: [accent.opacity(0.15), accent.opacity(0.05)]
        case .oceanBlue: [accent.opacity(0.15), accent.opacity(0.05)]
        case .darkMono: [Color(red: 0.22, green: 0.22, blue: 0.25), Color(red: 0.16, green: 0.16, blue: 0.18)]
        case .forestGreen: [accent.opacity(0.15), accent.opacity(0.05)]
        case .sunsetRose: [accent.opacity(0.15), accent.opacity(0.05)]
        }
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
