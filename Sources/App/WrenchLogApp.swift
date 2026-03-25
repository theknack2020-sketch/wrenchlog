import SwiftUI
import SwiftData

@main
struct WrenchLogApp: App {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "wl_onboarding_complete")
    @State private var showWhatsNew = false
    @State private var themeManager = ThemeManager.shared
    @Environment(\.scenePhase) private var scenePhase

    /// Tracks the quick action type launched from a Home Screen shortcut.
    @State private var pendingQuickAction: String?

    private let modelContainer: ModelContainer

    init() {
        // Crash-safe container initialization with fallback
        do {
            let schema = Schema([Vehicle.self, ServiceRecord.self, FuelLog.self, MaintenanceChecklistItem.self, VehicleDocument.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If migration or store creation fails, log and attempt a fresh container.
            // This prevents a crash loop from corrupt data.
            print("[WrenchLog] CRITICAL: ModelContainer init failed: \(error)")
            print("[WrenchLog] Attempting fallback with fresh store...")
            do {
                let schema = Schema([Vehicle.self, ServiceRecord.self, FuelLog.self, MaintenanceChecklistItem.self, VehicleDocument.self])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
                // Attempt to remove corrupt store
                let storeURL = config.url
                do {
                    try FileManager.default.removeItem(at: storeURL)
                } catch { /* ignore if file doesn't exist */ }
                // Also remove WAL and SHM files
                let walURL = storeURL.appendingPathExtension("wal")
                let shmURL = storeURL.appendingPathExtension("shm")
                try? FileManager.default.removeItem(at: walURL)
                try? FileManager.default.removeItem(at: shmURL)
                modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("[WrenchLog] Cannot create ModelContainer even with fresh store: \(error)")
            }
        }

        // Enable autosave for crash safety
        modelContainer.mainContext.autosaveEnabled = true

        // Register Home Screen Quick Actions
        Self.registerQuickActions()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingView(isComplete: $showOnboarding)
                        .onChange(of: showOnboarding) { _, done in
                            if done {
                                UserDefaults.standard.set(true, forKey: "wl_onboarding_complete")
                                showOnboarding = false
                            }
                        }
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
                if !showOnboarding && WhatsNewSheet.shouldShow {
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

// MARK: - Quick Action Environment Key

private struct PendingQuickActionKey: EnvironmentKey {
    static let defaultValue: Binding<String?> = .constant(nil)
}

extension EnvironmentValues {
    var pendingQuickAction: Binding<String?> {
        get { self[PendingQuickActionKey.self] }
        set { self[PendingQuickActionKey.self] = newValue }
    }
}

// MARK: - Quick Action App Delegate

/// Handles Home Screen Quick Actions when the app is already running (warm launch).
class QuickActionAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        QuickActionService.pendingAction = shortcutItem.type
        completionHandler(true)
    }
}
