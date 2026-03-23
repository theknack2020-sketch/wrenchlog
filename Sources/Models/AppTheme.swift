import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case defaultAmber = "Default Amber"
    case oceanBlue = "Ocean Blue"
    case darkMono = "Dark Mono"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .defaultAmber: Color(red: 0.91, green: 0.64, blue: 0.09)
        case .oceanBlue: Color(red: 0.20, green: 0.55, blue: 0.85)
        case .darkMono: Color(red: 0.65, green: 0.65, blue: 0.68)
        }
    }

    var accentLight: Color {
        switch self {
        case .defaultAmber: Color(red: 1.0, green: 0.71, blue: 0.15)
        case .oceanBlue: Color(red: 0.35, green: 0.68, blue: 0.95)
        case .darkMono: Color(red: 0.78, green: 0.78, blue: 0.80)
        }
    }

    var icon: String {
        switch self {
        case .defaultAmber: "sun.max.fill"
        case .oceanBlue: "water.waves"
        case .darkMono: "moon.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .defaultAmber: nil
        case .oceanBlue: nil
        case .darkMono: .dark
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
