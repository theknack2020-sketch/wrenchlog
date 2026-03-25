import SwiftUI
import UserNotifications

// MARK: - OnboardingView

struct OnboardingView: View {
    @Binding var isComplete: Bool

    // MARK: - Navigation

    @State private var currentPage = 0
    @State private var showAddVehicle = false

    // MARK: - Quiz Data

    @State private var selectedVehicleCount: String?
    @State private var selectedInterests: Set<String> = []

    // MARK: - Notification State

    @State private var notificationsRequested = false
    @State private var notificationsGranted = false

    // MARK: - Animations

    @State private var pulseGlow = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var bellBounce = false
    @State private var showCelebration = false
    @State private var pageAppeared: Set<Int> = []

    private let totalPages = 6

    // MARK: - Body

    var body: some View {
        ZStack {
            pageGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                skipBar

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    vehicleCountPage.tag(1)
                    interestsPage.tag(2)
                    previewPage.tag(3)
                    notificationsPage.tag(4)
                    getStartedPage.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentPage)

                bottomControls
            }

            CelebrationOverlay(isShowing: $showCelebration)
        }
        .preferredColorScheme(.dark)
        .onChange(of: currentPage) { _, page in
            HapticManager.shared.selection()
            if page == 4 { bellBounce.toggle() }
            if page == 5 { triggerCelebration() }
        }
        .fullScreenCover(isPresented: $showAddVehicle, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                completeOnboarding()
            }
        }) {
            NavigationStack {
                AddVehicleView()
            }
        }
    }

    // MARK: - Skip Bar

    private var skipBar: some View {
        HStack {
            Spacer()
            if currentPage < totalPages - 1 {
                Button {
                    HapticManager.shared.light()
                    completeOnboarding()
                } label: {
                    Text("Skip")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .accessibilityLabel("Skip onboarding")
                .transition(.opacity)
            }
        }
        .frame(height: 44)
        .padding(.trailing, 8)
        .animation(.easeOut(duration: 0.2), value: currentPage)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? Color.wrenchAmber : Color.white.opacity(0.25))
                        .frame(width: i == currentPage ? 28 : 8, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.bottom, 4)

            if currentPage < totalPages - 1 {
                Button {
                    HapticManager.shared.buttonTap()
                    advancePage()
                } label: {
                    Text(continueTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .foregroundStyle(.black)
                        .background(amberButtonGradient, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.wrenchAmber.opacity(0.35), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
                .accessibilityLabel(continueTitle)
            } else {
                Button {
                    HapticManager.shared.celebrate()
                    SoundManager.playCelebration()
                    saveOnboardingData()
                    showAddVehicle = true
                } label: {
                    Label("Add Your First Vehicle", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .foregroundStyle(.black)
                        .background(amberButtonGradient, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.wrenchAmber.opacity(0.35), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
                .accessibilityLabel("Add your first vehicle")

                Button {
                    HapticManager.shared.light()
                    SoundManager.playCelebration()
                    completeOnboarding()
                } label: {
                    Text("Explore First")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .accessibilityLabel("Skip adding a vehicle and explore the app")
            }
        }
        .padding(.bottom, 40)
        .animation(.easeInOut(duration: 0.25), value: currentPage)
    }

    // MARK: - Page 1: Welcome Hero

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.wrenchAmber.opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 110
                            )
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(pulseGlow ? 1.15 : 0.95)

                    // Inner glow
                    Circle()
                        .fill(Color.wrenchAmber.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseGlow ? 1.05 : 0.98)

                    Image(systemName: "wrench.adjustable.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.wrenchAmberLight, Color.wrenchAmber],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.wrenchAmber.opacity(0.5), radius: 16, y: 4)
                        .symbolEffect(.bounce, value: pageAppeared.contains(0))
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                        pulseGlow = true
                    }
                }
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("WrenchLog")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Your private vehicle maintenance tracker")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }

                // Benefits
                VStack(alignment: .leading, spacing: 16) {
                    benefitRow(icon: "checkmark.circle.fill", text: "Track every service")
                    benefitRow(icon: "bell.badge.fill", text: "Smart reminders")
                    benefitRow(icon: "lock.shield.fill", text: "No ads, no tracking")
                }
                .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear { pageAppeared.insert(0) }
    }

    // MARK: - Page 2: Vehicle Count Quiz

    private var vehicleCountPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 10) {
                    Text("How many vehicles\ndo you have?")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("We'll tailor your experience")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }

                HStack(spacing: 16) {
                    vehicleCountCard(value: "1", icon: "car.fill", label: "Just one")
                    vehicleCountCard(value: "2-3", icon: "car.2.fill", label: "A few")
                    vehicleCountCard(value: "4+", icon: "bus.fill", label: "Fleet")
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { pageAppeared.insert(1) }
    }

    // MARK: - Page 3: Interests Multi-Select

    private var interestsPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("What matters\nmost to you?")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("These help us personalize your experience")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }

                let interests = [
                    ("wrench.fill", "Service tracking"),
                    ("fuelpump.fill", "Fuel economy"),
                    ("chart.bar.fill", "Cost analysis"),
                    ("bell.fill", "Reminders"),
                    ("dollarsign.circle.fill", "Resale value"),
                ]

                OnboardingFlowLayout(spacing: 10) {
                    ForEach(interests, id: \.1) { icon, label in
                        interestChip(icon: icon, label: label)
                    }
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { pageAppeared.insert(2) }
    }

    // MARK: - Page 4: Preview

    private var previewPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("Your garage\nis ready")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Here's a preview of your setup")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Mock vehicle card
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wrenchAmber.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: "car.fill")
                                .font(.title2)
                                .foregroundStyle(Color.wrenchAmber)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("2024 Toyota Camry")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("32,150 miles")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        DueSoonBadge(urgency: .dueSoon)
                    }
                    .padding(16)

                    Divider()
                        .overlay(Color.white.opacity(0.08))

                    // Mock upcoming services
                    VStack(spacing: 10) {
                        mockServiceRow(icon: "drop.fill", name: "Oil Change", due: "Due in 500 mi", color: .catEngine)
                        mockServiceRow(icon: "tire.fill", name: "Tire Rotation", due: "Due in 2 weeks", color: .catTires)
                    }
                    .padding(16)
                }
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

                // Context message
                if let count = selectedVehicleCount {
                    let label = count == "1" ? "your vehicle" : "your \(count) vehicles"
                    Text("Ready to track \(label)")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { pageAppeared.insert(3) }
    }

    // MARK: - Page 5: Notifications

    private var notificationsPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Animated bell
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.wrenchAmber.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.wrenchAmber)
                        .symbolEffect(.bounce, value: bellBounce)
                }
                .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("Never miss\na service")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Stay on top of maintenance")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Benefits list
                VStack(alignment: .leading, spacing: 14) {
                    notifBenefitRow(icon: "clock.badge.checkmark.fill", text: "Smart reminders before due dates")
                    notifBenefitRow(icon: "exclamationmark.triangle.fill", text: "Overdue service alerts")
                    notifBenefitRow(icon: "moon.fill", text: "Quiet at night — no interruptions")
                }
                .padding(.horizontal, 8)

                if !notificationsRequested {
                    Button {
                        HapticManager.shared.medium()
                        requestNotifications()
                    } label: {
                        Label("Enable Notifications", systemImage: "bell.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .foregroundStyle(.black)
                            .background(amberButtonGradient, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.wrenchAmber.opacity(0.35), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 8)

                    Button {
                        HapticManager.shared.light()
                        notificationsRequested = true
                    } label: {
                        Text("Maybe Later")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                } else {
                    // Post-permission state
                    HStack(spacing: 10) {
                        Image(systemName: notificationsGranted ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundStyle(notificationsGranted ? .green : .white.opacity(0.5))
                        Text(notificationsGranted ? "Notifications enabled!" : "You can enable them later in Settings")
                            .font(.subheadline)
                            .foregroundStyle(notificationsGranted ? .green : .white.opacity(0.5))
                    }
                    .padding(.vertical, 8)
                    .transition(.opacity.combined(with: .scale))
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { pageAppeared.insert(4) }
    }

    // MARK: - Page 6: Get Started

    private var getStartedPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 36) {
                // Animated checkmark circle
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.wrenchGreen.opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)

                    Circle()
                        .stroke(Color.wrenchGreen.opacity(0.3), lineWidth: 3)
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.wrenchGreen)
                        .scaleEffect(checkmarkScale)
                }
                .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("You're all set!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Your maintenance tracker is ready.\nLet's add your first vehicle.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }

                // Trial CTA
                if !StoreManager.shared.isPro {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(Color.wrenchAmber)
                            Text("Start 7-Day Free Trial")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        Text("Unlock analytics, themes, and more")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.wrenchAmber.opacity(0.15), radius: 8, y: 4)
                    .accessibilityLabel("Start 7-day free trial for Pro features")
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { pageAppeared.insert(5) }
    }
}

// MARK: - Gradients & Styling

private extension OnboardingView {

    var pageGradient: some View {
        let colors: [Color] = switch currentPage {
        case 0:
            [Color(red: 0.45, green: 0.28, blue: 0.05), Color(red: 0.08, green: 0.06, blue: 0.04), .black]
        case 1:
            [Color(red: 0.38, green: 0.24, blue: 0.06), Color(red: 0.10, green: 0.07, blue: 0.04), .black]
        case 2:
            [Color(red: 0.35, green: 0.22, blue: 0.07), Color(red: 0.10, green: 0.08, blue: 0.04), .black]
        case 3:
            [Color(red: 0.30, green: 0.20, blue: 0.08), Color(red: 0.09, green: 0.07, blue: 0.04), .black]
        case 4:
            [Color(red: 0.28, green: 0.18, blue: 0.06), Color(red: 0.08, green: 0.06, blue: 0.04), .black]
        default:
            [Color(red: 0.10, green: 0.22, blue: 0.12), Color(red: 0.06, green: 0.08, blue: 0.05), .black]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    var amberButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color.wrenchAmberLight, Color.wrenchAmber],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var continueTitle: String {
        switch currentPage {
        case 0: return "Get Started"
        case 4 where notificationsRequested: return "Continue"
        default: return "Next"
        }
    }
}

// MARK: - Component Builders

private extension OnboardingView {

    func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.wrenchAmber)
                .frame(width: 28)
            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
    }

    func vehicleCountCard(value: String, icon: String, label: String) -> some View {
        let isSelected = selectedVehicleCount == value
        return Button {
            HapticManager.shared.cardPress()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedVehicleCount = value
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? Color.wrenchAmber : .white.opacity(0.5))

                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? AnyShapeStyle(Color.wrenchAmber.opacity(0.15)) : AnyShapeStyle(.ultraThinMaterial))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.wrenchAmber : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.wrenchAmber.opacity(0.2) : .black.opacity(0.15), radius: 6, y: 3)
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(value) vehicles, \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    func interestChip(icon: String, label: String) -> some View {
        let isSelected = selectedInterests.contains(label)
        return Button {
            HapticManager.shared.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    selectedInterests.remove(label)
                } else {
                    selectedInterests.insert(label)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? Color.wrenchAmber : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    func notifBenefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.wrenchAmber)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    func mockServiceRow(icon: String, name: String, due: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                Text(due)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.2))
        }
    }
}

// MARK: - Actions

private extension OnboardingView {

    func advancePage() {
        guard currentPage < totalPages - 1 else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentPage += 1
        }
    }

    func requestNotifications() {
        Task { @MainActor in
            let granted = await ReminderManager.shared.requestAuthorization()
            withAnimation(.easeInOut(duration: 0.3)) {
                notificationsGranted = granted
                notificationsRequested = true
            }
            if granted {
                HapticManager.shared.success()
            }
        }
    }

    func triggerCelebration() {
        showCelebration = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15)) {
            checkmarkScale = 1.0
        }
    }

    func saveOnboardingData() {
        let defaults = UserDefaults.standard
        if let count = selectedVehicleCount {
            defaults.set(count, forKey: "wl_vehicle_count")
        }
        if !selectedInterests.isEmpty {
            defaults.set(Array(selectedInterests), forKey: "wl_interests")
        }
        defaults.set(notificationsGranted, forKey: "wl_notifications_enabled")
    }

    func completeOnboarding() {
        saveOnboardingData()
        UserDefaults.standard.set(true, forKey: "wl_onboarding_complete")
        isComplete = true
    }
}

// MARK: - FlowLayout

/// Simple horizontal wrapping layout for interest chips.
private struct OnboardingFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return LayoutResult(
            size: CGSize(width: totalWidth, height: currentY + rowHeight),
            positions: positions
        )
    }
}
