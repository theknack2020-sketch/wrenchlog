import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                featuresPage.tag(1)
                privacyPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wrench.adjustable.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.wrenchAmber)
                .accessibilityHidden(true)

            Text("WrenchLog")
                .font(.system(size: 38, weight: .bold, design: .rounded))

            Text("Your private vehicle\nmaintenance tracker.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(Color.wrenchAmber, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)

            dots(current: 0)
        }
        .padding()
    }

    private var featuresPage: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                featureRow(icon: "wrench.fill", title: "Log Services", desc: "Oil changes, brakes, tires — 22 preset types")
                featureRow(icon: "bell.fill", title: "Smart Reminders", desc: "Never miss maintenance again")
                featureRow(icon: "chart.bar.fill", title: "Cost Tracking", desc: "See where your money goes")
                featureRow(icon: "doc.text.fill", title: "PDF Reports", desc: "Boost resale value with documented history")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                withAnimation { currentPage = 2 }
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(Color.wrenchAmber, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)

            dots(current: 1)
        }
        .padding()
    }

    private var privacyPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            Text("Your Data Stays Yours")
                .font(.title2.weight(.bold))

            Text("No account. No ads. No tracking.\nEverything stays on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                isComplete = true
            } label: {
                Text("Start Tracking")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(Color.wrenchAmber, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)

            dots(current: 2)
        }
        .padding()
    }

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.wrenchAmber)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func dots(current: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i == current ? Color.wrenchAmber : Color.wrenchAmber.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 8)
        .accessibilityHidden(true)
    }
}
