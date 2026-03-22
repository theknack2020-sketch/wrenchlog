import Foundation

@Observable @MainActor
final class UserSettings {
    static let shared = UserSettings()
    private let defaults = UserDefaults.standard

    var distanceUnit: DistanceUnit {
        get { DistanceUnit(rawValue: defaults.string(forKey: "wl_distance") ?? "miles") ?? .miles }
        set { defaults.set(newValue.rawValue, forKey: "wl_distance") }
    }

    var currency: Currency {
        get { Currency(rawValue: defaults.string(forKey: "wl_currency") ?? "usd") ?? .usd }
        set { defaults.set(newValue.rawValue, forKey: "wl_currency") }
    }

    var isPro: Bool {
        StoreManager.shared.isPro
    }

    func formatCost(_ amount: Double) -> String {
        "\(currency.symbol)\(String(format: "%.2f", amount))"
    }

    func formatMileage(_ miles: Int) -> String {
        if miles == 0 { return "No mileage set" }
        return "\(miles.formatted()) \(distanceUnit.label)"
    }

    private init() {}
}
