import SwiftUI

/// Streak + daily tip banner for the garage dashboard.
/// Shows journey messages (day 1-3), streak milestones, and rotating tips.
struct RetentionBanner: View {
    private let retention = RetentionEngine.shared
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // Journey message (day 1-3)
            if let journey = retention.journeyMessage {
                bannerRow(
                    icon: "sparkles",
                    iconColor: .wrenchAmber,
                    text: journey,
                    style: .journey
                )
            }

            // Streak milestone
            if let streakMsg = retention.streakMessage {
                bannerRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    text: streakMsg,
                    style: .streak
                )
            }

            // Daily tip
            bannerRow(
                icon: "lightbulb.fill",
                iconColor: theme.accent,
                text: retention.dailyTip,
                style: .tip
            )
        }
    }

    private enum BannerStyle {
        case journey, streak, tip
    }

    private func bannerRow(icon: String, iconColor: Color, text: String, style: BannerStyle) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            Text(text)
                .font(.caption)
                .foregroundStyle(style == .tip ? .secondary : .primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // Streak counter badge
            if style == .streak || (style == .tip && RetentionEngine.shared.currentStreak > 0) {
                if style == .tip && RetentionEngine.shared.currentStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("\(RetentionEngine.shared.currentStreak)")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.orange.opacity(0.12), in: Capsule())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            switch style {
            case .journey:
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.wrenchAmber.opacity(0.08))
            case .streak:
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.08))
            case .tip:
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Compact streak indicator for dashboard header
struct StreakBadge: View {
    private let streak = RetentionEngine.shared.currentStreak

    var body: some View {
        if streak > 0 {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                Text("\(streak)")
                    .font(.caption2.weight(.bold).monospacedDigit())
            }
            .foregroundStyle(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.orange.opacity(0.12), in: Capsule())
            .accessibilityLabel("\(streak) day streak")
        }
    }
}
