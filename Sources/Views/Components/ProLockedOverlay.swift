import SwiftUI

/// A blur overlay with lock icon + "Unlock with Pro" label.
/// Used on charts/sections that are Pro-only.
struct ProLockedOverlay: View {
    var message: String = "Unlock with Pro"
    var action: () -> Void
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Color(.systemBackground).opacity(0.3)
                }
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(theme.accent)
                    .accessibilityHidden(true)
                Text(message)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Button {
                    action()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                        Text("Upgrade to Pro")
                            .font(.caption.weight(.bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [theme.accent, theme.accent.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: theme.accent.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Upgrade to Pro")
                .accessibilityHint("Unlocks this Pro feature")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
