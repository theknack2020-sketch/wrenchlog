import Foundation

@Observable @MainActor
final class UserSettings {
    static let shared = UserSettings()
    private let defaults = UserDefaults.standard

    var distanceUnit: DistanceUnit {
        get { DistanceUnit(rawValue: defaults.string(forKey: "wl_distance") ?? "miles") ?? .miles }
        set { defaults.set(newValue.rawValue, forKey: "wl_distance") }
    }

    var volumeUnit: VolumeUnit {
        get { VolumeUnit(rawValue: defaults.string(forKey: "wl_volume") ?? "gallons") ?? .gallons }
        set { defaults.set(newValue.rawValue, forKey: "wl_volume") }
    }

    var efficiencyUnit: EfficiencyUnit {
        get { EfficiencyUnit(rawValue: defaults.string(forKey: "wl_efficiency") ?? "mpg") ?? .mpg }
        set { defaults.set(newValue.rawValue, forKey: "wl_efficiency") }
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

    func formatVolume(_ volume: Double) -> String {
        "\(String(format: "%.2f", volume)) \(volumeUnit.label)"
    }

    func formatEfficiency(_ value: Double) -> String {
        "\(String(format: "%.1f", value)) \(efficiencyUnit.label)"
    }

    func formatCostPerDistance(_ value: Double) -> String {
        "\(currency.symbol)\(String(format: "%.2f", value))/\(distanceUnit.label)"
    }

    private init() {}
}
