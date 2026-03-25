import SwiftUI

/// A blur overlay with lock icon + "Unlock with Pro" label.
/// Used on charts/sections that are Pro-only.
struct ProLockedOverlay: View {
    var message: String = "Unlock with Pro"
    var action: () -> Void

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
                    .foregroundStyle(Color.wrenchAmber)
                Text(message)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
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
                            colors: [Color.wrenchAmber, Color(red: 0.85, green: 0.55, blue: 0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: Color.wrenchAmber.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .accessibilityLabel("Upgrade to Pro")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
