import SwiftUI

/// A soft, non-blocking paywall sheet shown after N completed actions.
/// Premium glass design. Always dismissable.
struct SoftPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showFullPaywall = false
    @State private var appeared = false
    private let store = StoreManager.shared

    var body: some View {
        ZStack {
            // Rich gradient background
            LinearGradient(
                colors: [
                    Color.amber.shade500.opacity(0.12),
                    Color.Neutral.shade800.opacity(0.3),
                    Color(.systemBackground),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Dismiss indicator
                Capsule()
                    .fill(.tertiary)
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                // Hero icon with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.amber.shade500.opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 90, height: 90)
                        .shadow(color: Color.amber.shade500.opacity(0.2), radius: 16, y: 6)

                    Image(systemName: "crown.fill")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.amber.shade400, Color.amber.shade600],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .accessibilityHidden(true)

                // Title
                VStack(spacing: 8) {
                    Text("Great Progress! 🎉")
                        .font(.system(.title2, design: .rounded, weight: .bold))

                    Text("You're getting the most out of WrenchLog.\nUnlock the full experience with Pro.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // What you'll unlock
                VStack(spacing: 12) {
                    unlockRow(icon: "chart.bar.fill", text: "Full Analytics & Charts", color: .catEngine, index: 0)
                    unlockRow(icon: "gauge.open.with.needle.33percent", text: "Fuel Efficiency Trends", color: .catFuel, index: 1)
                    unlockRow(icon: "doc.richtext", text: "PDF Reports & CSV Export", color: .catElectrical, index: 2)
                    unlockRow(icon: "car.2.fill", text: "Unlimited Vehicles", color: .catTires, index: 3)
                    unlockRow(icon: "paintpalette.fill", text: "All Color Themes", color: .catFilters, index: 4)
                }
                .padding(16)
                .glassBackground(cornerRadius: 16)
                .padding(.horizontal, 24)

                // CTA
                Button {
                    SoftPaywallTracker.shared.markShown()
                    showFullPaywall = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.subheadline)
                        Text("Start 7-Day Free Trial")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(.white)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.amber.shade400, Color.amber.shade600],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            VStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.12), Color.clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                                    .frame(height: 27)
                                Spacer()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    )
                    .shadow(color: Color.amber.shade500.opacity(0.35), radius: 12, y: 6)
                }
                .pressable()
                .padding(.horizontal, 24)
                .accessibilityIdentifier("softPaywallTrialCTA")
                .accessibilityLabel("Start 7-day free trial")

                // Dismiss
                Button {
                    SoftPaywallTracker.shared.markDismissed()
                    dismiss()
                } label: {
                    Text("Maybe Later")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("softPaywallDismiss")
                .accessibilityLabel("Dismiss, maybe later")

                // Note
                Text("No charge until trial ends · Cancel anytime")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer(minLength: 8)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $showFullPaywall) {
            ProUpgradeView()
        }
        .onAppear {
            TelemetryService.paywallShown(source: "soft_paywall")
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func unlockRow(icon: String, text: String, color: Color, index: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.amber.shade500)
                .accessibilityHidden(true)
        }
        .staggeredAppear(index: index)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}
