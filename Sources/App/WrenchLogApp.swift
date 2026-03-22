import SwiftUI
import SwiftData

@main
struct WrenchLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Vehicle.self, ServiceRecord.self])
    }
}
