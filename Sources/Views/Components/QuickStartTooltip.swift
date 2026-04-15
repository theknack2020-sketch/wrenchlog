import SwiftUI

// MARK: - Quick Start Tooltip

struct QuickStartTooltip: View {
    @Binding var isVisible: Bool
    let tips: [(icon: String, text: String)]
    @Environment(\.appTheme) private var theme

    var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(theme.accent)
                    Text("Quick Start Guide")
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isVisible = false
                            UserDefaults.standard.set(true, forKey: "wl_quickstart_dismissed")
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Dismiss quick start guide")
                }

                ForEach(tips.indices, id: \.self) { index in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.1))
                                .frame(width: 28, height: 28)
                            Image(systemName: tips[index].icon)
                                .font(.caption)
                                .foregroundStyle(theme.accent)
                        }

                        Text(tips[index].text)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.accent.opacity(0.2), lineWidth: 1)
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }
}

// MARK: - Quick Start State

enum QuickStartState {
    static var shouldShow: Bool {
        !UserDefaults.standard.bool(forKey: "wl_quickstart_dismissed")
    }

    static let vehicleDetailTips: [(icon: String, text: String)] = [
        (icon: "plus.circle.fill", text: "Tap + to log a service or fuel fill-up"),
        (icon: "bell.fill", text: "Smart reminders track when services are due"),
        (icon: "chart.bar.fill", text: "View cost analytics for spending insights"),
        (icon: "clock.arrow.circlepath", text: "Timeline shows your complete history"),
        (icon: "checklist", text: "Use the checklist for quick maintenance tasks"),
    ]
}
