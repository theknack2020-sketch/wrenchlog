import StoreKit
import SwiftUI
import UserNotifications

// MARK: - OnboardingView

struct OnboardingView: View {
    @Binding var isShowing: Bool

    // MARK: - Environment

    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkRotation: Double = -90
    @State private var bellBounce = false
    @State private var showCelebration = false
    @State private var pageAppeared: Set<Int> = []
    @State private var selectedConfettiTrigger = 0

    // MARK: - Purchase State

    @State private var purchasing = false
    @State private var purchaseError: String?

    // MARK: - Preview Ring

    @State private var healthRingProgress: Double = 0

    private let totalPages = 6

    private var isRegularWidth: Bool {
        sizeClass == .regular
    }

    private var contentMaxWidth: CGFloat {
        isRegularWidth ? 500 : .infinity
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            pageGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            // Ambient floating particles
            if !reduceMotion {
                FloatingParticlesView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                skipBar

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    vehicleCountPage.tag(1)
                    interestsPage.tag(2)
                    previewPage.tag(3)
                    notificationsPage.tag(4)
                    paywallPage.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentPage)

                bottomControls
            }
            .frame(maxWidth: contentMaxWidth)

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
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.3))
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
            // Premium glowing capsule indicators
            HStack(spacing: 8) {
                ForEach(0 ..< totalPages, id: \.self) { i in
                    let isActive = i == currentPage
                    let isCompleted = i < currentPage
                    Capsule()
                        .fill(
                            isActive
                                ? Color.amber.shade500
                                : isCompleted
                                ? Color.amber.shade500.opacity(0.7)
                                : Color.white.opacity(0.12)
                        )
                        .frame(width: isActive ? 32 : 8, height: 8)
                        .overlay(
                            Capsule()
                                .stroke(
                                    isActive ? Color.amber.shade400.opacity(0.6) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isActive ? Color.amber.shade500.opacity(0.5) : Color.clear,
                            radius: isActive ? 6 : 0
                        )
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
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundStyle(.black)
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(amberButtonGradient)
                                VStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.15), Color.clear],
                                                startPoint: .top,
                                                endPoint: .center
                                            )
                                        )
                                        .frame(height: 28)
                                    Spacer()
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .shadow(color: Color.amber.shade500.opacity(0.35), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
                .accessibilityLabel(continueTitle)
            }

            // Paywall page has its own buttons, so no CTA here for page 5
        }
        .padding(.bottom, currentPage == totalPages - 1 ? 8 : 40)
        .animation(.easeInOut(duration: 0.25), value: currentPage)
    }

    // MARK: - Page 0: Welcome Hero

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)

            VStack(spacing: 24) {
                // Dramatic glow hero with orbiting particles
                ZStack {
                    if reduceMotion {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.amber.shade500.opacity(0.3), Color.amber.shade500.opacity(0.08), Color.clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                    } else {
                        PhaseAnimator([false, true]) { phase in
                            let isExpanded = phase
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.amber.shade500.opacity(isExpanded ? 0.18 : 0.08),
                                                Color.amber.shade500.opacity(isExpanded ? 0.06 : 0.02),
                                                Color.clear,
                                            ],
                                            center: .center,
                                            startRadius: 15,
                                            endRadius: isExpanded ? 120 : 100
                                        )
                                    )
                                    .frame(width: 220, height: 220)
                                    .blur(radius: isExpanded ? 16 : 10)

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.amber.shade500.opacity(isExpanded ? 0.35 : 0.15),
                                                Color.amber.shade500.opacity(isExpanded ? 0.12 : 0.04),
                                                Color.clear,
                                            ],
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: isExpanded ? 90 : 75
                                        )
                                    )
                                    .frame(width: 180, height: 180)

                                Circle()
                                    .fill(Color.amber.shade500.opacity(isExpanded ? 0.18 : 0.08))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 6)
                            }
                        } animation: { _ in
                            .easeInOut(duration: 2.8)
                        }

                        // Orbiting particles ring
                        OrbitingDotsView()
                            .frame(width: 160, height: 160)
                    }

                    Image(systemName: "wrench.adjustable.fill")
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.amber.shade400, Color.amber.shade500],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.amber.shade500.opacity(0.6), radius: 16, y: 4)
                        .shadow(color: Color.amber.shade500.opacity(0.25), radius: 30, y: 8)
                        .symbolEffect(.bounce, value: pageAppeared.contains(0))
                }
                .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("WrenchLog")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Your private vehicle maintenance tracker")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Benefit pills in glass capsules
                VStack(spacing: 10) {
                    benefitPill(icon: "checkmark.circle.fill", text: "Track every service", index: 0)
                    benefitPill(icon: "bell.badge.fill", text: "Smart reminders", index: 1)
                    benefitPill(icon: "lock.shield.fill", text: "No ads, no tracking", index: 2)
                }
            }

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 24)
        .onAppear { pageAppeared.insert(0) }
    }

    // MARK: - Page 1: Vehicle Count Quiz

    private var vehicleCountPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                VStack(spacing: 10) {
                    Text("How many vehicles\ndo you have?")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .staggeredAppear(index: 0)

                    Text("We'll tailor your experience")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .staggeredAppear(index: 1)
                }

                let columns: [GridItem] = if isRegularWidth {
                    Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
                } else {
                    Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
                }

                LazyVGrid(columns: columns, spacing: 16) {
                    vehicleCountCard(value: "1", icon: "car.fill", label: "Just one", index: 0)
                    vehicleCountCard(value: "2-3", icon: "car.2.fill", label: "A few", index: 1)
                    vehicleCountCard(value: "4+", icon: "bus.fill", label: "Fleet", index: 2)
                }
            }

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 24)
        .onAppear { pageAppeared.insert(1) }
    }

    // MARK: - Page 2: Interests Multi-Select

    private var interestsPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("What matters\nmost to you?")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .staggeredAppear(index: 0)

                    Text("These help us personalize your experience")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .staggeredAppear(index: 1)
                }

                let interests = [
                    ("wrench.fill", "Service tracking"),
                    ("fuelpump.fill", "Fuel economy"),
                    ("chart.bar.fill", "Cost analysis"),
                    ("bell.fill", "Reminders"),
                    ("dollarsign.circle.fill", "Resale value"),
                ]

                if isRegularWidth {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(Array(interests.enumerated()), id: \.element.1) { idx, item in
                            interestChip(icon: item.0, label: item.1, index: idx)
                        }
                    }
                } else {
                    OnboardingFlowLayout(spacing: 10) {
                        ForEach(Array(interests.enumerated()), id: \.element.1) { idx, item in
                            interestChip(icon: item.0, label: item.1, index: idx)
                        }
                    }
                }
            }

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 24)
        .onAppear { pageAppeared.insert(2) }
    }

    // MARK: - Page 3: Preview

    private var previewPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("Your garage\nis ready")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .staggeredAppear(index: 0)

                    Text("Here's a preview of your setup")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .staggeredAppear(index: 1)
                }

                // Double-bezel mock vehicle card
                ZStack {
                    // Outer bezel
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )

                    // Inner content
                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.amber.shade500.opacity(0.15))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "car.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.amber.shade500)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("2024 Toyota Camry")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("32,150 miles")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }

                            Spacer()

                            // Health ring with score
                            ZStack {
                                ProgressRing(
                                    progress: healthRingProgress / 100.0,
                                    lineWidth: 5,
                                    color: Color.Status.success.shade500
                                )
                                .frame(width: 48, height: 48)

                                Text("\(Int(healthRingProgress))")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.Status.success.shade500)
                            }
                        }
                        .padding(16)

                        Divider()
                            .overlay(Color.white.opacity(0.08))

                        VStack(spacing: 10) {
                            mockServiceRow(icon: "drop.fill", name: "Oil Change", due: "Due in 500 mi", color: .catEngine)
                            mockServiceRow(icon: "tire.fill", name: "Tire Rotation", due: "Due in 2 weeks", color: .catTires)
                            mockServiceRow(icon: "bolt.fill", name: "Battery Check", due: "Up to date", color: .catElectrical)
                        }
                        .padding(16)
                    }
                    .padding(3)
                    .background(
                        RoundedRectangle(cornerRadius: 21)
                            .fill(.ultraThinMaterial)
                    )
                    .padding(3)
                }
                .springStaggeredAppear(index: 2)

                if let count = selectedVehicleCount {
                    let label = count == "1" ? "your vehicle" : "your \(count) vehicles"
                    Text("Ready to track \(label)")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.4))
                        .floatIn(delay: 0.4)
                }
            }

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 24)
        .onAppear {
            pageAppeared.insert(3)
            // Animate health ring
            withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
                healthRingProgress = 82
            }
        }
    }

    // MARK: - Page 4: Notifications

    private var notificationsPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Animated bell with KeyframeAnimator
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.amber.shade500.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    if reduceMotion {
                        Image(systemName: "bell.badge.fill")
                            .font(.largeTitle).imageScale(.large)
                            .foregroundStyle(Color.amber.shade500)
                    } else {
                        KeyframeAnimator(
                            initialValue: BellKeyframe(),
                            trigger: bellBounce
                        ) { value in
                            Image(systemName: "bell.badge.fill")
                                .font(.largeTitle).imageScale(.large)
                                .foregroundStyle(Color.amber.shade500)
                                .rotationEffect(.degrees(value.rotation), anchor: .top)
                                .scaleEffect(value.scale)
                        } keyframes: { _ in
                            KeyframeTrack(\.rotation) {
                                SpringKeyframe(15, duration: 0.15, spring: .bouncy(duration: 0.15))
                                SpringKeyframe(-12, duration: 0.15, spring: .bouncy(duration: 0.15))
                                SpringKeyframe(8, duration: 0.12, spring: .bouncy(duration: 0.12))
                                SpringKeyframe(-5, duration: 0.12, spring: .bouncy(duration: 0.12))
                                SpringKeyframe(2, duration: 0.1, spring: .bouncy(duration: 0.1))
                                SpringKeyframe(0, duration: 0.2, spring: .smooth(duration: 0.3))
                            }
                            KeyframeTrack(\.scale) {
                                SpringKeyframe(1.12, duration: 0.15, spring: .bouncy)
                                SpringKeyframe(0.95, duration: 0.15, spring: .bouncy)
                                SpringKeyframe(1.05, duration: 0.12, spring: .bouncy)
                                SpringKeyframe(1.0, duration: 0.3, spring: .smooth(duration: 0.3))
                            }
                        }
                    }
                }
                .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("Never miss\na service")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Stay on top of maintenance")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Mock notification banner
                notificationBanner
                    .floatIn(delay: 0.2)

                // Benefits with animated checkmarks
                VStack(alignment: .leading, spacing: 14) {
                    notifBenefitRow(icon: "clock.badge.checkmark.fill", text: "Smart reminders before due dates", index: 0)
                    notifBenefitRow(icon: "exclamationmark.triangle.fill", text: "Overdue service alerts", index: 1)
                    notifBenefitRow(icon: "moon.fill", text: "Quiet at night — no interruptions", index: 2)
                }
                .padding(.horizontal, 8)

                if !notificationsRequested {
                    Button {
                        HapticManager.shared.medium()
                        requestNotifications()
                    } label: {
                        Label("Enable Notifications", systemImage: "bell.fill")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundStyle(.black)
                            .background {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(amberButtonGradient)
                                    VStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.15), Color.clear],
                                                    startPoint: .top,
                                                    endPoint: .center
                                                )
                                            )
                                            .frame(height: 28)
                                        Spacer()
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .shadow(color: Color.amber.shade500.opacity(0.35), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 8)

                    Button {
                        HapticManager.shared.light()
                        notificationsRequested = true
                    } label: {
                        Text("Maybe Later")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: notificationsGranted ? "checkmark.circle.fill" : "info.circle.fill")
                            .foregroundStyle(notificationsGranted ? Color.Status.success.shade500 : .white.opacity(0.5))
                        Text(notificationsGranted ? "Notifications enabled!" : "You can enable them later in Settings")
                            .font(.subheadline)
                            .foregroundStyle(notificationsGranted ? Color.Status.success.shade500 : .white.opacity(0.5))
                    }
                    .padding(.vertical, 8)
                    .transition(.opacity.combined(with: .scale))
                }
            }

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 24)
        .onAppear { pageAppeared.insert(4) }
    }

    // MARK: - Page 5: Paywall

    private var paywallPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                VStack(spacing: 28) {
                    // Crown hero
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.amber.shade500.opacity(0.25),
                                        Color.amber.shade500.opacity(0.06),
                                        Color.clear,
                                    ],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)

                        Image(systemName: "crown.fill")
                            .font(.largeTitle).imageScale(.large)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.amber.shade400, Color.amber.shade600],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.amber.shade500.opacity(0.5), radius: 16, y: 4)
                            .scaleEffect(checkmarkScale)
                            .rotationEffect(.degrees(checkmarkRotation))
                    }
                    .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        Text("Unlock the Full\nExperience")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("Take your maintenance tracking to the next level")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                    }

                    // Pro feature rows
                    VStack(spacing: 14) {
                        proFeatureRow(icon: "car.2.fill", text: "Unlimited vehicles", index: 0)
                        proFeatureRow(icon: "chart.bar.xaxis", text: "Full analytics & charts", index: 1)
                        proFeatureRow(icon: "camera.fill", text: "Receipt photo storage", index: 2)
                        proFeatureRow(icon: "doc.text.fill", text: "PDF & CSV export", index: 3)
                        proFeatureRow(icon: "paintpalette.fill", text: "All color themes", index: 4)
                    }
                    .padding(.horizontal, 8)

                    // Product cards
                    paywallProducts

                    // Error display
                    if let err = purchaseError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(Color.Status.error.shade500)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    // Secondary: Continue Free
                    Button {
                        HapticManager.shared.buttonTap()
                        SoundManager.playCelebration()
                        saveOnboardingData()
                        showAddVehicle = true
                    } label: {
                        Label("Continue Free — Add Your Vehicle", systemImage: "plus.circle.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundStyle(.white.opacity(0.8))
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Continue free and add your first vehicle")

                    // Tertiary: Explore First
                    Button {
                        HapticManager.shared.light()
                        SoundManager.playCelebration()
                        completeOnboarding()
                    } label: {
                        Text("Explore First")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .accessibilityLabel("Skip adding a vehicle and explore the app")

                    // Restore purchases
                    Button {
                        Task {
                            purchasing = true
                            let success = await StoreManager.shared.restorePurchases()
                            purchasing = false
                            if success {
                                HapticManager.shared.success()
                                saveOnboardingData()
                                showAddVehicle = true
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .disabled(purchasing)
                    .accessibilityLabel("Restore previous purchases")

                    // Legal footer
                    paywallLegal
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear { pageAppeared.insert(5) }
    }

    // MARK: - Notification Banner Mock

    private var notificationBanner: some View {
        HStack(spacing: 12) {
            // App icon mock
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.amber.shade500, Color.amber.shade600],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)

                Image(systemName: "wrench.adjustable.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("WrenchLog")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("now")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
                Text("Oil change due in 3 days")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(12)
        .glassBackground(cornerRadius: 16)
    }
}

// MARK: - Bell Keyframe Model

private struct BellKeyframe {
    var rotation: Double = 0
    var scale: Double = 1.0
}

// MARK: - Floating Particles View (Persistent Ambient)

private struct FloatingParticlesView: View {
    private let particleCount = 12

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for i in 0 ..< particleCount {
                    let seed = Double(i) * 137.508
                    let period = 8.0 + (seed.truncatingRemainder(dividingBy: 6.0))
                    let phase = seed.truncatingRemainder(dividingBy: .pi * 2)

                    let xBase = (seed.truncatingRemainder(dividingBy: size.width)).magnitude
                    let yBase = ((seed * 2.3).truncatingRemainder(dividingBy: size.height)).magnitude

                    let x = xBase + sin(now / period + phase) * 30
                    let y = yBase + cos(now / (period * 0.8) + phase) * 20

                    let breathe = 0.3 + 0.3 * sin(now / (period * 0.5) + phase)
                    let particleSize = 2.5 + (seed.truncatingRemainder(dividingBy: 2.0))

                    let rect = CGRect(
                        x: x - particleSize / 2,
                        y: y - particleSize / 2,
                        width: particleSize,
                        height: particleSize
                    )
                    context.opacity = breathe
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(Color.amber.shade400)
                    )
                }
            }
        }
    }
}

// MARK: - Orbiting Dots View

private struct OrbitingDotsView: View {
    private let dotCount = 6

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let cx = size.width / 2
                let cy = size.height / 2
                let radius: CGFloat = min(size.width, size.height) / 2 - 8

                for i in 0 ..< dotCount {
                    let baseAngle = (Double(i) / Double(dotCount)) * .pi * 2
                    let angle = baseAngle + now * 0.4
                    let x = cx + cos(angle) * radius
                    let y = cy + sin(angle) * radius

                    let dotSize: CGFloat = 4
                    let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                    let opacity = 0.4 + 0.3 * sin(now * 2 + Double(i))
                    context.opacity = opacity
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(Color.amber.shade400)
                    )
                }
            }
        }
    }
}

// MARK: - Gradients & Styling

private extension OnboardingView {
    var pageGradient: some View {
        let colors: [Color] = switch currentPage {
        case 0:
            [Color(red: 0.45, green: 0.28, blue: 0.05), Color(red: 0.08, green: 0.06, blue: 0.04), Color.Neutral.shade900]
        case 1:
            [Color(red: 0.38, green: 0.24, blue: 0.06), Color(red: 0.10, green: 0.07, blue: 0.04), Color.Neutral.shade900]
        case 2:
            [Color(red: 0.35, green: 0.22, blue: 0.07), Color(red: 0.10, green: 0.08, blue: 0.04), Color.Neutral.shade900]
        case 3:
            [Color(red: 0.30, green: 0.20, blue: 0.08), Color(red: 0.09, green: 0.07, blue: 0.04), Color.Neutral.shade900]
        case 4:
            [Color(red: 0.28, green: 0.18, blue: 0.06), Color(red: 0.08, green: 0.06, blue: 0.04), Color.Neutral.shade900]
        default:
            [Color(red: 0.35, green: 0.22, blue: 0.07), Color(red: 0.10, green: 0.07, blue: 0.04), Color.Neutral.shade900]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    var amberButtonGradient: LinearGradient {
        LinearGradient(
            colors: [Color.amber.shade400, Color.amber.shade600],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var continueTitle: String {
        switch currentPage {
        case 0: "Get Started"
        case 4 where notificationsRequested: "Continue"
        default: "Next"
        }
    }
}

// MARK: - Component Builders

private extension OnboardingView {
    // MARK: Welcome Page Benefit Pill

    func benefitPill(icon: String, text: String, index: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.amber.shade500)
                .frame(width: 24)
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: Capsule())
        .staggeredAppear(index: index + 2)
    }

    // MARK: Vehicle Count Card (Double Bezel)

    func vehicleCountCard(value: String, icon: String, label: String, index: Int) -> some View {
        let isSelected = selectedVehicleCount == value
        return Button {
            HapticManager.shared.cardPress()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedVehicleCount = value
            }
            if !reduceMotion {
                selectedConfettiTrigger += 1
            }
        } label: {
            // Outer bezel
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                isSelected ? Color.amber.shade500.opacity(0.7) : Color.white.opacity(0.06),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )

                // Inner card
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(isSelected ? Color.amber.shade500 : .white.opacity(0.5))
                        .symbolEffect(.bounce, value: isSelected)

                    Text(value)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.7))

                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 130)
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 21)
                        .fill(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color.amber.shade500.opacity(0.2), Color.amber.shade600.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(Color.clear)
                        )
                )
                .padding(3)
            }
            .overlay {
                if isSelected, !reduceMotion {
                    OnboardingSparkleView(trigger: selectedConfettiTrigger)
                        .allowsHitTesting(false)
                }
            }
            .shadow(color: isSelected ? Color.amber.shade500.opacity(0.25) : .black.opacity(0.15), radius: isSelected ? 10 : 6, y: 3)
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(OnboardingCardButtonStyle())
        .springStaggeredAppear(index: index + 2)
        .accessibilityLabel("\(value) vehicles, \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Interest Chip (Glass)

    func interestChip(icon: String, label: String, index: Int) -> some View {
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
            if !reduceMotion, !isSelected {
                selectedConfettiTrigger += 1
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .symbolEffect(.bounce, value: isSelected)
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.amber.shade400, Color.amber.shade600],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(.ultraThinMaterial)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(OnboardingCardButtonStyle())
        .staggeredAppear(index: index + 2)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Notification Benefit Row

    func notifBenefitRow(icon: String, text: String, index: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.amber.shade500)
                .frame(width: 28)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        }
        .staggeredAppear(index: index + 3)
    }

    // MARK: Mock Service Row

    func mockServiceRow(icon: String, name: String, due: String, color: Color) -> some View {
        HStack(spacing: 0) {
            // Colored left border
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3, height: 32)
                .padding(.trailing, 12)

            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
                .padding(.trailing, 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
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

    // MARK: Pro Feature Row

    func proFeatureRow(icon: String, text: String, index: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.amber.shade500.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.amber.shade500)
            }
            Text(text)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.amber.shade500)
        }
        .staggeredAppear(index: index)
    }

    // MARK: Paywall Products

    var paywallProducts: some View {
        let store = StoreManager.shared
        return Group {
            if store.isLoading {
                ProgressView()
                    .padding()
            } else if let loadErr = store.loadError {
                VStack(spacing: 8) {
                    Text(loadErr)
                        .font(.caption)
                        .foregroundStyle(Color.Status.error.shade500)
                    Button("Retry") {
                        Task { await store.loadProducts() }
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.amber.shade500)
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    // Yearly — primary CTA
                    if let yearly = store.yearlyProduct {
                        paywallYearlyCard(product: yearly)
                    }

                    // Lifetime — secondary
                    if let lifetime = store.lifetimeProduct {
                        paywallLifetimeCard(product: lifetime)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: Yearly Card

    func paywallYearlyCard(product: Product) -> some View {
        Button {
            Task {
                purchasing = true
                purchaseError = nil
                do {
                    let ok = try await StoreManager.shared.purchase(product)
                    if ok {
                        HapticManager.shared.celebrate()
                        SoundManager.playCelebration()
                        saveOnboardingData()
                        showAddVehicle = true
                    }
                    purchasing = false
                } catch StoreKitError.userCancelled {
                    purchasing = false
                } catch {
                    HapticManager.shared.error()
                    purchaseError = "Purchase could not be completed. You have not been charged."
                    purchasing = false
                }
            }
        } label: {
            VStack(spacing: 0) {
                // RECOMMENDED badge
                HStack {
                    Spacer()
                    Text("RECOMMENDED")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2), in: Capsule())
                    Spacer()
                }
                .padding(.top, 12)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yearly")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        Text("Start 7-Day Free Trial")
                            .font(.system(.subheadline, design: .rounded))
                            .opacity(0.85)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if purchasing {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Text(product.displayPrice)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                            Text("/year")
                                .font(.caption2)
                                .opacity(0.7)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.amber.shade400, Color.amber.shade600],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    // Inner highlight
                    VStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.15), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .frame(height: 40)
                        Spacer()
                    }
                    // Animated glow border
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.amber.shade400.opacity(0.2), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.amber.shade500.opacity(0.4), radius: 16, y: 6)
        }
        .disabled(purchasing)
        .pressable()
        .glowPulse(color: Color.amber.shade500)
        .accessibilityLabel("Yearly plan, \(product.displayPrice) per year, Start 7-day free trial")
    }

    // MARK: Lifetime Card

    func paywallLifetimeCard(product: Product) -> some View {
        Button {
            Task {
                purchasing = true
                purchaseError = nil
                do {
                    let ok = try await StoreManager.shared.purchase(product)
                    if ok {
                        HapticManager.shared.celebrate()
                        SoundManager.playCelebration()
                        saveOnboardingData()
                        showAddVehicle = true
                    }
                    purchasing = false
                } catch StoreKitError.userCancelled {
                    purchasing = false
                } catch {
                    HapticManager.shared.error()
                    purchaseError = "Purchase could not be completed. You have not been charged."
                    purchasing = false
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lifetime")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                    Text("One-time purchase · Yours forever")
                        .font(.caption)
                        .opacity(0.7)
                }
                Spacer()
                if purchasing {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Text(product.displayPrice)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .disabled(purchasing)
        .pressable()
        .accessibilityLabel("Lifetime plan, \(product.displayPrice), one-time purchase")
    }

    // MARK: Paywall Legal

    var paywallLegal: some View {
        VStack(spacing: 8) {
            Text("No charge until trial ends · Cancel anytime")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.45))

            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple ID account. Manage in Settings → Apple ID → Subscriptions.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.25))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://theknack2020-sketch.github.io/wrenchlog/privacy/")!)
                    .accessibilityLabel("Privacy Policy")
                    .accessibilityHint("Opens privacy policy in browser")
                Link("Terms of Use", destination: URL(string: "https://theknack2020-sketch.github.io/wrenchlog/terms/")!)
                    .accessibilityLabel("Terms of Use")
                    .accessibilityHint("Opens terms of use in browser")
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.top, 8)
    }
}

// MARK: - Card Button Style (Press Feedback)

private struct OnboardingCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Sparkle Particle Overlay

private struct OnboardingSparkleView: View {
    let trigger: Int
    @State private var particles: [SparkleParticle] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, _ in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let age = now - particle.startTime
                    guard age < particle.lifetime else { continue }
                    let progress = age / particle.lifetime
                    let opacity = 1.0 - progress
                    let y = particle.startY - CGFloat(age) * particle.speed
                    let x = particle.startX + sin(CGFloat(age) * particle.wobble) * 6

                    let rect = CGRect(
                        x: x - particle.size / 2,
                        y: y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )
                    context.opacity = opacity * 0.7
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onChange(of: trigger) { _, _ in
            spawnParticles()
        }
        .allowsHitTesting(false)
    }

    private func spawnParticles() {
        let now = Date.now.timeIntervalSinceReferenceDate
        let colors: [Color] = [Color.amber.shade500, Color.amber.shade400, .white, .yellow]
        var newParticles: [SparkleParticle] = []
        for _ in 0 ..< 8 {
            newParticles.append(SparkleParticle(
                startX: CGFloat.random(in: 20 ... 100),
                startY: CGFloat.random(in: 40 ... 90),
                speed: CGFloat.random(in: 30 ... 60),
                wobble: CGFloat.random(in: 2 ... 5),
                size: CGFloat.random(in: 3 ... 6),
                lifetime: Double.random(in: 0.5 ... 1.0),
                startTime: now,
                color: colors.randomElement() ?? Color.amber.shade500
            ))
        }
        particles = newParticles
    }
}

private struct SparkleParticle {
    let startX: CGFloat
    let startY: CGFloat
    let speed: CGFloat
    let wobble: CGFloat
    let size: CGFloat
    let lifetime: Double
    let startTime: Double
    let color: Color
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
        if reduceMotion {
            checkmarkScale = 1.0
            checkmarkRotation = 0
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.15)) {
                checkmarkScale = 1.0
                checkmarkRotation = 0
            }
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
        isShowing = false
    }
}

// MARK: - FlowLayout

private struct OnboardingFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
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
