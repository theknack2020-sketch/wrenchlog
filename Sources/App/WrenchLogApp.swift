import OSLog
import SwiftData
import SwiftUI
import TelemetryDeck
import TipKit

@main
struct WrenchLogApp: App {
    @State private var showOnboarding: Bool
    @State private var showWhatsNew = false
    @State private var themeManager = ThemeManager.shared
    @Environment(\.scenePhase) private var scenePhase

    /// Tracks the quick action type launched from a Home Screen shortcut.
    @State private var pendingQuickAction: String?

    private let modelContainer: ModelContainer

    @State private var showDataError = false

    init() {
        // Initialize onboarding state first; will be re-evaluated after seeder (if DEBUG)
        _showOnboarding = State(initialValue: !UserDefaults.standard.bool(forKey: "wl_onboarding_complete"))

        let schema = Schema(versionedSchema: WrenchLogSchemaV4.self)

        // Crash-safe container initialization with migration plan
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: WrenchLogMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            // If migration fails, attempt a fresh store
            Logger.app.fault("ModelContainer init failed: \(error)")
            Logger.app.warning("Attempting fallback with fresh store")
            do {
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
                let storeURL = config.url
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
                modelContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: WrenchLogMigrationPlan.self,
                    configurations: [config]
                )
            } catch {
                // Last resort: in-memory container to avoid crash loop
                Logger.app.fault("Cannot create persistent store: \(error). Using in-memory fallback.")
                let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                // In-memory ModelContainer creation is safe — schema is already validated
                modelContainer = Self.makeInMemoryContainer(schema: schema, config: memConfig)
                // Flag to show user alert about data loss
                DispatchQueue.main.async { [self] in
                    showDataError = true
                }
            }
        }

        // Enable autosave for crash safety
        modelContainer.mainContext.autosaveEnabled = true

        #if DEBUG
            // Seed mock data for App Store screenshot capture (DEBUG only)
            if ScreenshotSeeder.shouldSeed {
                MainActor.assumeIsolated {
                    ScreenshotSeeder.seed(context: modelContainer.mainContext)
                }
            }
        #endif

        // Initialize TelemetryDeck analytics
        TelemetryService.initialize()
        TelemetryService.appLaunched()

        // Initialize TipKit for feature discovery
        try? Tips.configure()

        // Register Home Screen Quick Actions
        Self.registerQuickActions()

        // Re-evaluate onboarding AFTER seeder may have set UserDefaults (DEBUG path).
        // For normal release launches this is a no-op with the same result.
        _showOnboarding = State(initialValue: !UserDefaults.standard.bool(forKey: "wl_onboarding_complete"))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingView(isShowing: $showOnboarding)
                } else {
                    ContentView()
                        .environment(\.pendingQuickAction, $pendingQuickAction)
                }
            }
            .environment(\.appTheme, themeManager.current)
            .preferredColorScheme(themeManager.current.preferredColorScheme)
            .tint(themeManager.current.accent)
            .onAppear {
                // Show What's New sheet if version changed (and onboarding is done)
                if !showOnboarding, WhatsNewSheet.shouldShow {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showWhatsNew = true
                    }
                }
            }
            .sheet(isPresented: $showWhatsNew) {
                WhatsNewSheet()
            }
            .onOpenURL { url in
                // wrenchlog://vehicle/{id}
                // wrenchlog://add-service
                // wrenchlog://add-fuel
                guard url.scheme == "wrenchlog" else { return }
                switch url.host {
                case "add-service":
                    QuickActionService.pendingAction = "com.theknack.wrenchlog.addService"
                case "add-fuel":
                    QuickActionService.pendingAction = "com.theknack.wrenchlog.addFuel"
                default:
                    break
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    // Check for quick action when returning from background
                    if let shortcut = QuickActionService.pendingAction {
                        pendingQuickAction = shortcut
                        QuickActionService.pendingAction = nil
                    }
                }
            }
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Container Fallback

    /// Creates an in-memory ModelContainer as a last resort.
    /// In-memory containers with a valid schema do not fail in practice.
    private static func makeInMemoryContainer(schema: Schema, config: ModelConfiguration) -> ModelContainer {
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }
        // Absolute fallback — effectively unreachable because in-memory stores always succeed
        Logger.app.fault("In-memory container failed with provided config, trying bare minimum")
        let bare = ModelConfiguration(isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: schema, configurations: [bare]) else {
            preconditionFailure("ModelContainer cannot be created even in-memory — corrupted binary")
        }
        return container
    }

    // MARK: - Home Screen Quick Actions

    private static func registerQuickActions() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: "com.theknack.wrenchlog.addService",
                localizedTitle: "Log Service",
                localizedSubtitle: "Record a maintenance service",
                icon: UIApplicationShortcutIcon(systemImageName: "wrench.fill")
            ),
            UIApplicationShortcutItem(
                type: "com.theknack.wrenchlog.addFuel",
                localizedTitle: "Log Fuel",
                localizedSubtitle: "Record a fill-up",
                icon: UIApplicationShortcutIcon(systemImageName: "fuelpump.fill")
            ),
        ]
    }
}

// MARK: - Quick Action Service

/// Bridges UIKit shortcut handling to SwiftUI via a static property.
enum QuickActionService {
    /// Set by the AppDelegate / scene delegate adapter when a shortcut is triggered.
    nonisolated(unsafe) static var pendingAction: String?
}

extension EnvironmentValues {
    @Entry var pendingQuickAction: Binding<String?> = .constant(nil)
}

// MARK: - Quick Action App Delegate

/// Handles Home Screen Quick Actions when the app is already running (warm launch).
class QuickActionAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActionService.pendingAction = shortcutItem.type
        completionHandler(true)
    }
}
