import SwiftUI

/// A soft, non-blocking paywall sheet shown after N completed actions.
/// Glassmorphism design. Always dismissable.
struct SoftPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showFullPaywall = false
    private let store = StoreManager.shared

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.wrenchAmber.opacity(0.15),
                    Color(red: 0.85, green: 0.55, blue: 0.05).opacity(0.08),
                    Color(.systemBackground)
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
                                colors: [Color.wrenchAmber.opacity(0.25), Color.wrenchAmber.opacity(0.0)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 90, height: 90)
                        .shadow(color: Color.wrenchAmber.opacity(0.2), radius: 16, x: 0, y: 6)

                    Image(systemName: "wrench.adjustable.fill")
                        .font(.system(.largeTitle, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.wrenchAmber, Color(red: 0.85, green: 0.55, blue: 0.05)],
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
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // What you'll unlock
                VStack(spacing: 12) {
                    unlockRow(icon: "chart.bar.fill", text: "Full Analytics & Charts", color: .catEngine)
                    unlockRow(icon: "gauge.open.with.needle.33percent", text: "Fuel Efficiency Trends", color: .catFuel)
                    unlockRow(icon: "doc.richtext", text: "PDF Reports & CSV Export", color: .catElectrical)
                    unlockRow(icon: "car.2.fill", text: "Unlimited Vehicles", color: .catTires)
                    unlockRow(icon: "paintpalette.fill", text: "All Color Themes", color: .catFilters)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
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
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: [Color.wrenchAmber, Color(red: 0.85, green: 0.55, blue: 0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .shadow(color: Color.wrenchAmber.opacity(0.35), radius: 12, x: 0, y: 6)
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
        .sheet(isPresented: $showFullPaywall) {
            ProUpgradeView()
        }
    }

    private func unlockRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            Text(text)
                .font(.subheadline.weight(.medium))
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(Color.wrenchAmber)
        }
    }
}
