import OSLog

// MARK: - App Logger

/// Centralized logging using os.Logger — structured, filterable, privacy-safe.
/// Usage: Logger.app.info("Vehicle saved")
///        Logger.store.error("Purchase failed: \(error)")
extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.theknack.wrenchlog"

    /// General app events (lifecycle, navigation, state)
    static let app = Logger(subsystem: subsystem, category: "app")

    /// Data operations (save, fetch, delete, migration)
    static let data = Logger(subsystem: subsystem, category: "data")

    /// Store / IAP operations
    static let store = Logger(subsystem: subsystem, category: "store")

    /// Reminders & notifications
    static let reminders = Logger(subsystem: subsystem, category: "reminders")

    /// Photo & document handling
    static let media = Logger(subsystem: subsystem, category: "media")

    /// Calendar integration
    static let calendar = Logger(subsystem: subsystem, category: "calendar")

    /// Export / import operations
    static let export = Logger(subsystem: subsystem, category: "export")
}
