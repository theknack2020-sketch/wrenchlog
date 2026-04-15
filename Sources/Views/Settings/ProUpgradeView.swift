import StoreKit
import SwiftUI

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var purchasing = false
    @State private var restoring = false
    @State private var error: String?
    @State private var restoreSuccess = false
    @State private var showPurchaseErrorAlert = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""
    @State private var heroScale: CGFloat = 0.7
    @State private var heroRotation: Double = -20
    @State private var starsAnimated = false
    @State private var featuresRevealed = false
    private let store = StoreManager.shared

    private var isRegularWidth: Bool {
        sizeClass == .regular
    }

    private var contentMaxWidth: CGFloat {
        isRegularWidth ? 600 : .infinity
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Rich dark background with amber mesh orbs
                backgroundLayer
                    .ignoresSafeArea()

                // Floating ambient particles
                if !reduceMotion {
                    PaywallParticlesView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        heroSection
                        socialProofSection
                        featureShowcase
                        comparisonSection
                        noAdsNote
                        trustSection
                        productsSection
                        feedbackSection
                        restoreSection
                        legalSection
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .accessibilityIdentifier("proUpgradeClose")
                    .accessibilityLabel("Close Pro upgrade screen")
                }
            }
            .disabled(purchasing)
            .alert("Purchase Failed", isPresented: $showPurchaseErrorAlert) {
                Button("Try Again") {
                    retryPurchase()
                }
                Button("Contact Support") {
                    openSupportEmail(subject: "WrenchLog Pro Purchase Issue")
                }
                Button("Cancel", role: .cancel) { error = nil }
            } message: {
                Text(error ?? "An unexpected error occurred. You have not been charged.")
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                if restoreAlertMessage.contains("restored successfully") {
                    Button("OK") { dismiss() }
                } else {
                    Button("Try Again") { performRestore() }
                    Button("Contact Support") {
                        openSupportEmail(subject: "WrenchLog Pro Restore Issue")
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                Text(restoreAlertMessage)
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.Neutral.shade900

            // Ambient amber mesh orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.amber.shade500.opacity(0.10), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 120, y: -180)
                .blur(radius: 40)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.amber.shade600.opacity(0.06), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: -100, y: 400)
                .blur(radius: 30)

            // Subtle top-to-bottom warm gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.10, blue: 0.05).opacity(0.6),
                    Color.clear,
                    Color(red: 0.10, green: 0.07, blue: 0.04).opacity(0.3),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Triple-layer glow
                if !reduceMotion {
                    PhaseAnimator([false, true]) { phase in
                        let expanded = phase
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.amber.shade500.opacity(expanded ? 0.2 : 0.08),
                                            Color.amber.shade500.opacity(expanded ? 0.06 : 0.02),
                                            Color.clear,
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: expanded ? 170 : 140
                                    )
                                )
                                .frame(width: 300, height: 300)
                                .blur(radius: expanded ? 18 : 10)

                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.amber.shade500.opacity(expanded ? 0.35 : 0.15),
                                            Color.amber.shade500.opacity(expanded ? 0.10 : 0.04),
                                            Color.clear,
                                        ],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: expanded ? 120 : 100
                                    )
                                )
                                .frame(width: 240, height: 240)
                        }
                    } animation: { _ in
                        .easeInOut(duration: 3.0)
                    }
                } else {
                    RadialGradient(
                        colors: [Color.amber.shade500.opacity(0.3), Color.amber.shade500.opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 140
                    )
                    .frame(width: 280, height: 280)
                }

                // Glass circle base
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.amber.shade500.opacity(0.2), radius: 24, y: 8)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.amber.shade500.opacity(0.18), Color.amber.shade500.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                // Crown + wrench combo
                ZStack {
                    Image(systemName: "wrench.adjustable.fill")
                        .font(.largeTitle).imageScale(.large)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.amber.shade400, Color.amber.shade600],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.amber.shade300, Color.amber.shade500],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(x: 20, y: -24)
                        .shadow(color: Color.amber.shade500.opacity(0.5), radius: 4, y: 2)
                }
            }
            .shadow(color: Color.amber.shade500.opacity(0.3), radius: 16, y: 6)
            .scaleEffect(heroScale)
            .rotationEffect(.degrees(heroRotation))
            .onAppear {
                if reduceMotion {
                    heroScale = 1.0
                    heroRotation = 0
                } else {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                        heroScale = 1.0
                        heroRotation = 0
                    }
                }
            }
            .accessibilityHidden(true)

            Text("WrenchLog Pro")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            Text("Everything you need to master\nyour vehicle maintenance")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }

    // MARK: - Social Proof

    private var socialProofSection: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0 ..< 5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .symbolEffect(.bounce, value: starsAnimated)
                }
            }
            .accessibilityHidden(true)

            Text("Trusted by car enthusiasts worldwide")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .onAppear {
            if !reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    starsAnimated = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("5 stars. Trusted by car enthusiasts worldwide")
    }

    // MARK: - Feature Showcase (Horizontal Cards)

    private var featureShowcase: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                featureCard(icon: "chart.bar.fill", title: "Analytics", description: "Cost breakdowns & spending trends", color: .catEngine, index: 0)
                featureCard(icon: "gauge.open.with.needle.33percent", title: "Fuel Trends", description: "MPG tracking & efficiency insights", color: .catFuel, index: 1)
                featureCard(icon: "doc.richtext", title: "PDF Reports", description: "Professional service history exports", color: .catElectrical, index: 2)
                featureCard(icon: "car.2.fill", title: "Unlimited", description: "Manage your entire fleet", color: .catTires, index: 3)
                featureCard(icon: "paintpalette.fill", title: "Themes", description: "5 premium color palettes", color: .catFilters, index: 4)
            }
            .padding(.horizontal, 24)
        }
        .scrollTargetBehavior(.viewAligned)
    }

    private func featureCard(icon: String, title: String, description: String, color: Color, index _: Int) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(color)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 160, height: 170)
        .glassBackground(cornerRadius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
        .scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.6)
                .scaleEffect(phase.isIdentity ? 1 : 0.92)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }

    // MARK: - Comparison Table

    private var comparisonSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("What You Get")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 50)
                HStack(spacing: 3) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                    Text("Pro")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.amber.shade500)
                .frame(width: 55)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.amber.shade500.opacity(0.12))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Feature comparison: What you get, Free versus Pro")
            .accessibilityAddTraits(.isHeader)

            comparisonRow("Vehicles", free: "2", pro: "∞", index: 0)
            comparisonRow("Service Logging", free: true, pro: true, index: 1)
            comparisonRow("Fuel Tracking", free: true, pro: true, index: 2)
            comparisonRow("Smart Reminders", free: true, pro: true, index: 3)
            comparisonRow("Basic Insights", free: true, pro: true, index: 4)
            comparisonRow("Full Analytics & Charts", free: false, pro: true, index: 5)
            comparisonRow("Fuel Efficiency Trends", free: false, pro: true, index: 6)
            comparisonRow("Receipt Photos", free: false, pro: true, index: 7)
            comparisonRow("PDF Reports", free: false, pro: true, index: 8)
            comparisonRow("CSV Export", free: false, pro: true, index: 9)
            comparisonRow("Spending Projections", free: false, pro: true, index: 10)
            comparisonRow("All Color Themes", free: false, pro: true, index: 11)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.03))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.amber.shade500.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .padding(.horizontal, 24)
        .onAppear {
            if !reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    featuresRevealed = true
                }
            } else {
                featuresRevealed = true
            }
        }
    }

    // MARK: - No Ads Note

    private var noAdsNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "nosign")
                .font(.caption)
                .foregroundStyle(Color.amber.shade500)
                .accessibilityHidden(true)
            Text("WrenchLog never shows ads — Free or Pro.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("WrenchLog never shows ads, Free or Pro")
    }

    // MARK: - Trust Section

    private var trustSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                trustBadge(icon: "lock.shield.fill", text: "Secure Purchase", index: 0)
                trustBadge(icon: "arrow.clockwise.circle", text: "Cancel Anytime", index: 1)
            }
            HStack(spacing: 16) {
                trustBadge(icon: "iphone.and.arrow.forward", text: "Restore Anytime", index: 2)
                trustBadge(icon: "hand.raised.fill", text: "No Data Collection", index: 3)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Products Section

    private var productsSection: some View {
        Group {
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
                VStack(spacing: 14) {
                    // Yearly — primary CTA
                    if let yearly = store.yearlyProduct {
                        yearlyProductCard(product: yearly)
                    }

                    // Lifetime — secondary
                    if let lifetime = store.lifetimeProduct {
                        lifetimeProductCard(product: lifetime)
                    }

                    // Savings callout
                    if let lifetime = store.lifetimeProduct,
                       let yearly = store.yearlyProduct
                    {
                        savingsCallout(lifetime: lifetime, yearly: yearly)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        Group {
            if let err = error {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(Color.Status.error.shade500)
                    .transition(.opacity)
            }

            if restoreSuccess {
                Label("Purchases restored!", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.Status.success.shade500)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Restore

    private var restoreSection: some View {
        Button {
            performRestore()
        } label: {
            HStack(spacing: 6) {
                if restoring {
                    ProgressView()
                        .controlSize(.small)
                }
                Text("Restore Purchases")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.5))
        .disabled(restoring)
        .accessibilityLabel(restoring ? "Restoring purchases" : "Restore purchases")
        .accessibilityHint("Restore previously purchased Pro access")
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Your data stays on your device. We don't sell your vehicle information to anyone.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 4) {
                Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple ID account. You can manage or cancel subscriptions anytime in Settings → Apple ID → Subscriptions.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.25))
                    .multilineTextAlignment(.center)

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
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Product Cards

private extension ProUpgradeView {
    func yearlyProductCard(product: Product) -> some View {
        Button {
            purchaseProduct(product)
        } label: {
            // Double-bezel outer
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.amber.shade400.opacity(0.15), Color.amber.shade600.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.amber.shade500.opacity(0.3), lineWidth: 1)
                    )

                VStack(spacing: 0) {
                    // RECOMMENDED badge
                    HStack {
                        Spacer()
                        Text("RECOMMENDED")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.amber.shade500.opacity(0.4), in: Capsule())
                        Spacer()
                    }
                    .padding(.top, 14)

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
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                Text("/year")
                                    .font(.caption2)
                                    .opacity(0.7)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .padding(.bottom, 4)
                }
                .foregroundStyle(.white)
                .padding(3)
                .background(
                    RoundedRectangle(cornerRadius: 17)
                        .fill(
                            LinearGradient(
                                colors: [Color.amber.shade400, Color.amber.shade600],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            VStack {
                                RoundedRectangle(cornerRadius: 17)
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
                        )
                )
                .padding(3)
            }
            .shadow(color: Color.amber.shade500.opacity(0.4), radius: 16, y: 6)
        }
        .disabled(purchasing)
        .pressable()
        .glowPulse(color: Color.amber.shade500)
        .accessibilityLabel("Yearly plan, \(product.displayPrice) per year, Start 7-day free trial")
        .accessibilityHint("Recommended option with free trial")
    }

    func lifetimeProductCard(product: Product) -> some View {
        Button {
            purchaseProduct(product)
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
                        .font(.system(.title3, design: .rounded, weight: .bold))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
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
}

// MARK: - Comparison Rows

private extension ProUpgradeView {
    func comparisonRow(_ feature: String, free: Bool, pro: Bool, index: Int) -> some View {
        HStack {
            Text(feature)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: free ? "checkmark" : "xmark")
                .font(.caption2.weight(.bold))
                .foregroundStyle(free ? Color.Status.success.shade500 : .white.opacity(0.25))
                .frame(width: 50)
                .accessibilityHidden(true)
            Image(systemName: pro ? "checkmark" : "xmark")
                .font(.caption2.weight(.bold))
                .foregroundStyle(pro ? Color.amber.shade500 : .white.opacity(0.25))
                .frame(width: 55)
                .symbolEffect(.bounce, value: featuresRevealed && pro)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(index.isMultiple(of: 2) ? Color.white.opacity(0.03) : Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature): Free \(free ? "yes" : "no"), Pro \(pro ? "yes" : "no")")
    }

    func comparisonRow(_ feature: String, free: String, pro: String, index: Int) -> some View {
        HStack {
            Text(feature)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 50)
            Text(pro)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.amber.shade500)
                .frame(width: 55)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(index.isMultiple(of: 2) ? Color.white.opacity(0.03) : Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature): Free \(free), Pro \(pro)")
    }
}

// MARK: - Helpers

private extension ProUpgradeView {
    var savingsBadge: String? {
        guard let yearly = store.yearlyProduct, let lifetime = store.lifetimeProduct else { return nil }
        let yearlyPrice = Double(truncating: yearly.price as NSDecimalNumber)
        let lifetimePrice = Double(truncating: lifetime.price as NSDecimalNumber)
        guard lifetimePrice > 0, yearlyPrice > 0 else { return nil }
        let yearsToBreakEven = lifetimePrice / yearlyPrice
        if yearsToBreakEven > 1 {
            let savingsPercent = Int(((lifetimePrice - yearlyPrice) / lifetimePrice) * 100)
            if savingsPercent > 0 {
                return "Save \(savingsPercent)% vs Lifetime"
            }
        }
        return nil
    }

    func savingsCallout(lifetime: Product, yearly: Product) -> some View {
        let yearlyPrice = Double(truncating: yearly.price as NSDecimalNumber)
        let lifetimePrice = Double(truncating: lifetime.price as NSDecimalNumber)
        let yearsToBreakEven = yearlyPrice > 0 ? lifetimePrice / yearlyPrice : 0.0

        return Group {
            if yearsToBreakEven > 0, yearsToBreakEven < 5 {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.amber.shade500)
                        .accessibilityHidden(true)
                    Text("Lifetime pays for itself in \(String(format: "%.0f", ceil(yearsToBreakEven))) years")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color.amber.shade500.opacity(0.1), in: Capsule())
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Lifetime pays for itself in \(String(format: "%.0f", ceil(yearsToBreakEven))) years")
            }
        }
    }

    func trustBadge(icon: String, text: String, index: Int) -> some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.amber.shade500.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(Color.amber.shade500)
            }
            .accessibilityHidden(true)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .staggeredAppear(index: index)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }

    func purchaseProduct(_ product: Product) {
        Task {
            purchasing = true
            error = nil
            do {
                let ok = try await store.purchase(product)
                if ok {
                    HapticManager.shared.celebrate()
                    dismiss()
                } else {
                    purchasing = false
                }
            } catch StoreKitError.userCancelled {
                purchasing = false
            } catch StoreKitError.networkError {
                HapticManager.shared.error()
                self.error = "Network error. Please check your internet connection and try again."
                showPurchaseErrorAlert = true
                purchasing = false
            } catch {
                HapticManager.shared.error()
                self.error = "Purchase could not be completed. You have not been charged. Please try again."
                showPurchaseErrorAlert = true
                purchasing = false
            }
        }
    }

    func retryPurchase() {
        if let product = store.yearlyProduct ?? store.lifetimeProduct {
            purchaseProduct(product)
        }
    }

    func performRestore() {
        Task {
            restoring = true
            error = nil
            restoreSuccess = false
            let success = await store.restorePurchases()
            restoring = false
            if success {
                restoreAlertMessage = "Your Pro purchase has been restored successfully!"
                showRestoreAlert = true
                HapticManager.shared.success()
            } else {
                restoreAlertMessage = "No previous purchases found.\n\nIf you believe this is an error, make sure you're signed in with the same Apple ID used for the original purchase."
                showRestoreAlert = true
                HapticManager.shared.warning()
            }
        }
    }

    func openSupportEmail(subject: String) {
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        if let url = URL(string: "mailto:theknack2020@gmail.com?subject=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Floating Particles

private struct PaywallParticlesView: View {
    private let particleCount = 10

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for i in 0 ..< particleCount {
                    let seed = Double(i) * 137.508
                    let period = 10.0 + (seed.truncatingRemainder(dividingBy: 5.0))
                    let phase = seed.truncatingRemainder(dividingBy: .pi * 2)

                    let xBase = (seed.truncatingRemainder(dividingBy: size.width)).magnitude
                    let yBase = ((seed * 2.3).truncatingRemainder(dividingBy: size.height)).magnitude

                    let x = xBase + sin(now / period + phase) * 25
                    let y = yBase + cos(now / (period * 0.7) + phase) * 20

                    let breathe = 0.25 + 0.25 * sin(now / (period * 0.5) + phase)
                    let particleSize = 2.0 + (seed.truncatingRemainder(dividingBy: 2.0))

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
