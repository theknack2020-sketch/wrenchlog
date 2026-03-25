import SwiftUI

/// Shows new features after an app update.
/// Displays once per version, tracked via UserDefaults.
struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    private let version: String

    private struct FeatureItem: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let color: Color
    }

    private let features: [FeatureItem] = [
        FeatureItem(icon: "flame.fill", title: "Streak Tracking", description: "Build daily habits with streak rewards", color: .orange),
        FeatureItem(icon: "chart.bar.fill", title: "Weekly Summary", description: "See your vehicle activity at a glance", color: .catEngine),
        FeatureItem(icon: "bell.badge.fill", title: "Smart Reminders", description: "Mileage + time-based service alerts", color: .wrenchAmber),
        FeatureItem(icon: "square.and.arrow.up", title: "Share Records", description: "Share service and fuel logs with anyone", color: .catTires),
        FeatureItem(icon: "hand.draw.fill", title: "Swipe Actions", description: "Swipe to edit or delete records", color: .catElectrical),
        FeatureItem(icon: "paintpalette.fill", title: "5 Color Themes", description: "Personalize your experience", color: .catFilters),
    ]

    init() {
        self.version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.12, green: 0.10, blue: 0.18),
                    Color(red: 0.06, green: 0.06, blue: 0.10),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(.white.opacity(0.25))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 24)

                // Header
                VStack(spacing: 8) {
                    Text("What's New")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Version \(version)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 28)

                // Feature list
                VStack(spacing: 16) {
                    ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                        featureRow(feature)
                            .floatIn(delay: Double(index) * 0.08)
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)

                // Continue button
                Button {
                    WhatsNewSheet.markShown()
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundStyle(.white)
                        .background(
                            LinearGradient(
                                colors: [theme.accent, theme.accent.opacity(0.75)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .shadow(color: theme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .pressable()
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .accessibilityIdentifier("whatsNewContinue")
                .accessibilityLabel("Continue")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(false)
    }

    private func featureRow(_ feature: FeatureItem) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(feature.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: feature.icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(feature.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.title): \(feature.description)")
    }

    // MARK: - Version Tracking

    private static let shownVersionKey = "wl_last_whats_new_version"

    /// Whether the sheet should be presented for the current app version.
    static var shouldShow: Bool {
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let shown = UserDefaults.standard.string(forKey: shownVersionKey)
        return shown != current
    }

    /// Mark the current version as shown so the sheet won't appear again.
    static func markShown() {
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        UserDefaults.standard.set(current, forKey: shownVersionKey)
    }
}
