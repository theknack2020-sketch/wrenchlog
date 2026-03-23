import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        GarageOverviewView()
            .tint(theme.accent)
    }
}
