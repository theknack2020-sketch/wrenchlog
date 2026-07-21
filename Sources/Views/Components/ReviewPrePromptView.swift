import SwiftUI

/// The honest in-app review pre-prompt — a warm "Enjoying WrenchLog?" card
/// surfaced only at a peak moment (see ``ReviewPromptManager``). A happy tap
/// opens Apple's native rating prompt; an unhappy tap opens private feedback so
/// a gripe reaches us in Mail instead of a public one-star.
///
/// This is the honest two-option ask. It is never a fake star UI that secretly
/// routes 1–3 taps to feedback and 4–5 to the App Store — Apple's HIG
/// discourages that review-gating, and it clashes with TheKnack's honest-brand
/// rule.
struct ReviewPrePromptView: View {
    let onLove: () -> Void
    let onFeedback: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: theme.headerGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                Image(systemName: "wrench.adjustable.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text("Enjoying WrenchLog?")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("A quick word helps other drivers find it — and if something's off, tell us and we'll fix it.")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Spacing.sm) {
                Button {
                    onLove()
                    dismiss()
                } label: {
                    Text("I love it")
                        .font(.body.weight(.semibold))
                        // Dark ink on the accent — white fails WCAG-AA on all themes.
                        .foregroundStyle(theme.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(theme.accent, in: .rect(cornerRadius: 14, style: .continuous))
                }
                .pressable()

                Button {
                    onFeedback()
                    dismiss()
                } label: {
                    Text("Could be better")
                        .font(.body.weight(.medium))
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .pressable()
            }
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}

#if DEBUG
    #Preview("Review pre-prompt") {
        Color.black.opacity(0.2)
            .sheet(isPresented: .constant(true)) {
                ReviewPrePromptView(onLove: {}, onFeedback: {})
            }
    }
#endif
