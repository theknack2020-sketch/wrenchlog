import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.appTheme) private var theme
    private let haptic = HapticManager.shared

    var body: some View {
        GarageOverviewView()
            .tint(theme.accent)
            .onAppear {
                haptic.light()
            }
    }
}
