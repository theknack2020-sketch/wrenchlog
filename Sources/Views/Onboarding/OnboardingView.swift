import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    @State private var animatePulse = false

    private let totalPages = 4

    var body: some View {
        ZStack {
            // Gradient background per step
            Group {
                switch currentPage {
                case 0:
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.94, blue: 0.85), Color(.systemBackground)],
                        startPoint: .top,
                        endPoint: .center
                    )
                case 1:
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.92, blue: 0.85), Color(.systemBackground)],
                        startPoint: .top,
                        endPoint: .center
                    )
                case 2:
                    LinearGradient(
                        colors: [Color(red: 0.94, green: 0.90, blue: 0.84), Color(.systemBackground)],
                        startPoint: .top,
                        endPoint: .center
                    )
                default:
                    LinearGradient(
                        colors: [Color(red: 0.90, green: 0.95, blue: 0.90), Color(.systemBackground)],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    vehiclePage.tag(1)
                    servicePage.tag(2)
                    notificationsPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentPage)

                // Bottom navigation
                VStack(spacing: 16) {
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.wrenchAmber : Color.wrenchAmber.opacity(0.25))
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .padding(.bottom, 8)

                    // Action button
                    Button {
                        HapticManager.shared.light()
                        if currentPage < totalPages - 1 {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            HapticManager.shared.celebrate()
                            SoundManager.playCelebration()
                            isComplete = true
                        }
                    } label: {
                        Text(buttonTitle)
                            .font(.headline)
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
                            .shadow(color: Color.wrenchAmber.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)
                    .accessibilityLabel(buttonTitle)
                    .accessibilityHint(currentPage < totalPages - 1 ? "Go to next step" : "Begin using WrenchLog")

                    // Skip button (not on last page)
                    if currentPage < totalPages - 1 {
                        Button {
                            HapticManager.shared.light()
                            isComplete = true
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel("Skip onboarding")
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }

    private var buttonTitle: String {
        switch currentPage {
        case 0: "Get Started"
        case 1: "Next"
        case 2: "Next"
        case 3: "Start Tracking"
        default: "Continue"
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 28) {
            Spacer()

            // Animated illustration
            ZStack {
                Circle()
                    .fill(Color.wrenchAmber.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .scaleEffect(animatePulse ? 1.1 : 1.0)

                Circle()
                    .fill(Color.wrenchAmber.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .scaleEffect(animatePulse ? 1.15 : 1.0)

                Image(systemName: "wrench.adjustable.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color.wrenchAmber)
                    .symbolEffect(.bounce, value: currentPage == 0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    animatePulse = true
                }
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("WrenchLog")
                    .font(.system(size: 38, weight: .bold, design: .rounded))

                Text("Your private vehicle\nmaintenance tracker.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Page 2: Add First Vehicle

    private var vehiclePage: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.catTires.opacity(0.15), Color.catTires.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.catTires.opacity(0.15), radius: 10, x: 0, y: 4)

                VStack(spacing: 8) {
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.catTires)
                        .symbolEffect(.bounce, value: currentPage == 1)

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.wrenchAmber)
                        .offset(x: 40, y: -20)
                }
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Add Your Vehicle")
                    .font(.title2.weight(.bold))

                Text("Start by adding your car, truck, or\nmotorcycle. Track make, model, year\nand current mileage.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Feature pills
            HStack(spacing: 10) {
                featurePill(icon: "car.fill", text: "Cars")
                featurePill(icon: "truck.box.fill", text: "Trucks")
                featurePill(icon: "bicycle", text: "Any vehicle")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Supports cars, trucks, and any vehicle")

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Page 3: Add First Service

    private var servicePage: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.catEngine.opacity(0.15), Color.catEngine.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.catEngine.opacity(0.15), radius: 10, x: 0, y: 4)

                Image(systemName: "checklist.checked")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.catEngine)
                    .symbolEffect(.bounce, value: currentPage == 2)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Log Services & Fuel")
                    .font(.title2.weight(.bold))

                Text("22 preset service types from oil changes\nto timing belts. Track fuel fill-ups\nand see your efficiency trends.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Service type preview
            VStack(alignment: .leading, spacing: 10) {
                servicePreviewRow(icon: "drop.fill", text: "Oil Change", color: .catEngine)
                servicePreviewRow(icon: "tire.fill", text: "Tire Rotation", color: .catTires)
                servicePreviewRow(icon: "battery.100percent.bolt", text: "Battery", color: .catElectrical)
                servicePreviewRow(icon: "fuelpump.fill", text: "Fuel Tracking", color: .catFuel)
            }
            .padding(.horizontal, 40)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("22 preset service types including oil change, tire rotation, battery, and fuel tracking")

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Page 4: Notifications

    private var notificationsPage: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.wrenchGreen.opacity(0.1))
                    .frame(width: 160, height: 160)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.wrenchGreen)
                    .symbolEffect(.bounce, value: currentPage == 3)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Never Miss Maintenance")
                    .font(.title2.weight(.bold))

                Text("Smart reminders based on time,\nmileage, and your driving pace.\nWe'll notify you before services are due.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Privacy badge
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("100% Private")
                        .font(.subheadline.weight(.semibold))
                    Text("No account · No ads · No tracking")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
            .padding(.horizontal, 40)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("100% Private. No account, no ads, no tracking.")

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
        .foregroundStyle(.secondary)
    }

    private func servicePreviewRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
    }
}
