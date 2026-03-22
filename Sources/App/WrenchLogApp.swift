import SwiftUI
import SwiftData

@main
struct WrenchLogApp: App {
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "wl_onboarding_complete")

    var body: some Scene {
        WindowGroup {
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
        .modelContainer(for: [Vehicle.self, ServiceRecord.self])
    }
}
