import SwiftUI
import SwiftData

@main
struct WrenchLogApp: App {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "wl_onboarding_complete")
    @State private var themeManager = ThemeManager.shared

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
                }
            }
            .environment(\.appTheme, themeManager.current)
            .preferredColorScheme(themeManager.current.preferredColorScheme)
            .tint(themeManager.current.accent)
        }
        .modelContainer(modelContainer)
    }
}
