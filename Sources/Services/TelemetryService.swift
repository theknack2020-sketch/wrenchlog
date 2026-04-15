import TelemetryDeck

/// Centralized TelemetryDeck wrapper for analytics signals.
enum TelemetryService {
    /// Initialize TelemetryDeck with the app ID.
    /// Call once in WrenchLogApp.init().
    static func initialize() {
        // TODO: Replace with actual TelemetryDeck App ID from dashboard
        let config = TelemetryDeck.Config(appID: "REPLACE_WITH_TELEMETRYDECK_APP_ID")
        TelemetryDeck.initialize(config: config)
    }

    /// Send a named analytics signal with optional parameters.
    static func signal(_ name: String, parameters: [String: String] = [:]) {
        TelemetryDeck.signal(name, parameters: parameters)
    }

    // MARK: - Predefined Signals

    static func appLaunched() {
        signal("app_launched")
    }

    static func vehicleAdded() {
        signal("vehicle_added")
    }

    static func serviceLogged() {
        signal("service_logged")
    }

    static func fuelLogged() {
        signal("fuel_logged")
    }

    static func paywallShown(source: String) {
        signal("paywall_shown", parameters: ["source": source])
    }

    static func purchaseCompleted(product: String) {
        signal("purchase_completed", parameters: ["product": product])
    }

    static func themeChanged(theme: String) {
        signal("theme_changed", parameters: ["theme": theme])
    }
}
