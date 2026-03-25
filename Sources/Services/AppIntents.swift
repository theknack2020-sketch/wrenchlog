import AppIntents

struct LogServiceIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Service"
    static let description: IntentDescription = "Log a maintenance service for your vehicle"
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        // Opens app — the quick action handler will take it from there
        return .result()
    }
}

struct LogFuelIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Fuel"
    static let description: IntentDescription = "Record a fuel fill-up"
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct WrenchLogShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogServiceIntent(),
            phrases: ["Log a service in \(.applicationName)", "Record maintenance in \(.applicationName)"],
            shortTitle: "Log Service",
            systemImageName: "wrench.fill"
        )
        AppShortcut(
            intent: LogFuelIntent(),
            phrases: ["Log fuel in \(.applicationName)", "Record fill-up in \(.applicationName)"],
            shortTitle: "Log Fuel",
            systemImageName: "fuelpump.fill"
        )
    }
}
