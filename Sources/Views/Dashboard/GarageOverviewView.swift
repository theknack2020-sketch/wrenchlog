import Charts
import SwiftData
import SwiftUI
import TipKit

// MARK: - Garage Overview Dashboard

struct GarageOverviewView: View {
    @Query(filter: #Predicate<Vehicle> { !$0.isArchived },
           sort: \Vehicle.dateAdded, order: .reverse)
    private var activeVehicles: [Vehicle]

    @Query(filter: #Predicate<Vehicle> { $0.isArchived },
           sort: \Vehicle.dateAdded, order: .reverse)
    private var archivedVehicles: [Vehicle]

    @State private var showAddVehicle = false
    @State private var showProPrompt = false
    @State private var showSoftPaywall = false
    @State private var selectedVehicle: Vehicle?
    @State private var showArchivedVehicles = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoaded = false
    // Quick Action sheet state
    @State private var quickActionVehicle: Vehicle?
    @State private var showQuickAddService = false
    @State private var showQuickAddFuel = false
    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme
    @Environment(\.pendingQuickAction) private var pendingQuickAction
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Namespace private var heroNamespace

    private let store = StoreManager.shared
    private let settings = UserSettings.shared
    private let haptic = HapticManager.shared
    private let retention = RetentionEngine.shared

    /// Next service due across all vehicles
    var nextServiceDue: (vehicle: Vehicle, type: String, urgency: ReminderUrgency, text: String)? {
        for vehicle in activeVehicles {
            if let next = ServiceReminderEngine.nextServiceSummary(for: vehicle) {
                if next.urgency == .overdue || next.urgency == .due {
                    return (vehicle: vehicle, type: next.type, urgency: next.urgency, text: next.text)
                }
            }
        }
        // If no overdue, pick first due soon
        for vehicle in activeVehicles {
            if let next = ServiceReminderEngine.nextServiceSummary(for: vehicle) {
                if next.urgency == .dueSoon {
                    return (vehicle: vehicle, type: next.type, urgency: next.urgency, text: next.text)
                }
            }
        }
        // Otherwise first reminder
        for vehicle in activeVehicles {
            if let next = ServiceReminderEngine.nextServiceSummary(for: vehicle) {
                return (vehicle: vehicle, type: next.type, urgency: next.urgency, text: next.text)
            }
        }
        return nil
    }

    var totalServiceCount: Int {
        activeVehicles.reduce(0) { $0 + $1.safeServiceRecords.count }
    }

    var totalCost: Double {
        activeVehicles.reduce(0) { total, v in
            total + v.safeServiceRecords.reduce(0) { $0 + $1.cost } + v.safeFuelLogs.reduce(0) { $0 + $1.totalCost }
        }
    }

    var overdueCount: Int {
        activeVehicles.reduce(0) { total, v in
            total + ServiceReminderEngine.reminders(for: v).count(where: { $0.urgency == .overdue })
        }
    }

    /// Seasonal suggestions
    var seasonalSuggestions: [SeasonalSuggestion] {
        SeasonalSuggestionEngine.suggestions(for: activeVehicles)
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeVehicles.isEmpty, archivedVehicles.isEmpty {
                    emptyState
                } else {
                    dashboardList
                }
            }
            .navigationTitle("Garage")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        haptic.light()
                        if !store.isPro, activeVehicles.count >= 2 {
                            TelemetryService.paywallShown(source: "garage_add_limit")
                            showProPrompt = true
                        } else {
                            showAddVehicle = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(theme.accent)
                    }
                    .accessibilityIdentifier("garageAddVehicle")
                    .accessibilityLabel("Add vehicle")
                }
            }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView()
            }
            .fullScreenCover(isPresented: $showProPrompt) {
                ProUpgradeView()
            }
            .sheet(isPresented: $showSoftPaywall) {
                SoftPaywallSheet()
            }
            .navigationDestination(item: $selectedVehicle) { vehicle in
                VehicleDetailView(vehicle: vehicle)
                    .heroZoomTransition(id: vehicle.id, in: heroNamespace)
            }
            .onAppear {
                // Shimmer loading effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { isLoaded = true }
                }
                // Track retention
                retention.recordActivity()
                Task {
                    await retention.resetInactivityTimer()
                    await retention.scheduleRetentionNotifications()
                    await ReminderManager.shared.scheduleReminders(for: activeVehicles)
                }
                // Index vehicles for Spotlight
                SpotlightService.indexVehicles(activeVehicles)
                // Check soft paywall trigger
                if SoftPaywallTracker.shared.shouldShowPaywall {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showSoftPaywall = true
                        SoftPaywallTracker.shared.markShown()
                    }
                }
            }
            .alert("Something Went Wrong", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            // Quick Action sheets
            .sheet(isPresented: $showQuickAddService) {
                if let vehicle = quickActionVehicle {
                    AddServiceView(vehicle: vehicle)
                }
            }
            .sheet(isPresented: $showQuickAddFuel) {
                if let vehicle = quickActionVehicle {
                    AddFuelLogView(vehicle: vehicle)
                }
            }
            .onChange(of: pendingQuickAction.wrappedValue) { _, action in
                guard let action else { return }
                handleQuickAction(action)
                pendingQuickAction.wrappedValue = nil
            }
            .onAppear {
                // Handle quick action that arrived before the view appeared
                if let action = pendingQuickAction.wrappedValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        handleQuickAction(action)
                        pendingQuickAction.wrappedValue = nil
                    }
                }
            }
        }
    }

    // MARK: - Quick Action Handler

    private func handleQuickAction(_ action: String) {
        if activeVehicles.isEmpty {
            // No vehicles — open Add Vehicle instead
            showAddVehicle = true
            return
        }
        let vehicle = activeVehicles[0]
        quickActionVehicle = vehicle
        switch action {
        case "com.theknack.wrenchlog.addService":
            showQuickAddService = true
        case "com.theknack.wrenchlog.addFuel":
            showQuickAddFuel = true
        default:
            break
        }
    }

    // MARK: - Empty State (Premium)

    private var emptyState: some View {
        VStack(spacing: 28) {
            Spacer()

            // Large pulsing glow icon
            ZStack {
                // Outer glow ring — animated pulse
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.accent.opacity(0.25), theme.accent.opacity(0.0)],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(isLoaded ? 1.08 : 0.92)
                    .opacity(isLoaded ? 0.8 : 0.4)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: isLoaded
                    )

                // Solid background circle
                Circle()
                    .fill(theme.accent.opacity(0.12))
                    .frame(width: 120, height: 120)

                // Inner highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "car.side.fill")
                    .font(.system(.largeTitle, design: .rounded, weight: .medium))
                    .foregroundStyle(theme.accent)
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5))
            }
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Your Garage is Empty")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                Text("Add your first vehicle to start tracking\nmaintenance, fuel costs, and service history.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("No account needed — your data stays on this device.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }

            TipView(AddFirstVehicleTip())
                .padding(.horizontal, 8)
                .tipBackground(theme.accent.opacity(0.08))

            // Gradient CTA button with shadow
            Button {
                haptic.buttonTap()
                showAddVehicle = true
            } label: {
                Label("Add Your First Vehicle", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: 260, minHeight: 52)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(
                            colors: theme.headerGradient + [theme.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .shadow(color: theme.accent.opacity(0.35), radius: 12, x: 0, y: 6)
                    .shadow(color: theme.accent.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .accessibilityLabel("Add your first vehicle")
            .accessibilityHint("Opens a form to add a new vehicle")
            .pressable()
            .floatIn(delay: 0.3)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Dashboard List

    private var dashboardList: some View {
        List {
            // Fleet summary with gradient header
            if !activeVehicles.isEmpty {
                Section {
                    VStack(spacing: 0) {
                        // Premium gradient header banner — 3-color with radial glow
                        premiumHeaderBanner
                            .padding(.bottom, 12)

                        fleetSummaryCard

                        // Retention: daily tip + streak + journey
                        RetentionBanner()
                            .padding(.top, 8)
                    }
                    .floatIn(delay: 0.05)
                } header: {
                    Text("Overview")
                        .font(.system(.headline, design: .rounded))
                }
            }

            // Next service due banner
            if let next = nextServiceDue {
                Section {
                    nextServiceBanner(next)
                }
            }

            // Seasonal suggestions (collapsed by default)
            if !seasonalSuggestions.isEmpty {
                Section {
                    DisclosureGroup("Seasonal Tips") {
                        ForEach(seasonalSuggestions) { suggestion in
                            seasonalRow(suggestion)
                        }
                    }
                    .accessibilityLabel("Seasonal maintenance tips, \(seasonalSuggestions.count) suggestions")
                }
            }

            // Vehicles — adaptive grid for iPad
            Section {
                vehicleCardGrid

                // Pro upsell (inline)
                if !store.isPro, activeVehicles.count >= 2 {
                    Button {
                        haptic.buttonTap()
                        TelemetryService.paywallShown(source: "garage_inline_upsell")
                        showProPrompt = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(theme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Free: 2 vehicles")
                                    .font(.subheadline.weight(.medium))
                                Text("Upgrade to Pro for unlimited vehicles, analytics, PDF export & more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .glassBackground(cornerRadius: 14)
                    }
                    .pressable()
                    .accessibilityIdentifier("garageProUpsell")
                    .accessibilityLabel("Upgrade to Pro for unlimited vehicles")
                }
            } header: {
                Text("Vehicles")
                    .font(.system(.headline, design: .rounded))
            }

            // Milestones (only show when 2+ badges earned)
            let badges = MilestoneEngine.earnedBadges(for: activeVehicles)
            if badges.count >= 2 {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(badges.enumerated()), id: \.element.id) { index, badge in
                                MilestoneBadgeView(badge: badge)
                                    .statPop(index: index)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Milestones")
                        .font(.system(.headline, design: .rounded))
                }
            }

            // Multi-vehicle cost comparison
            if activeVehicles.count >= 2 {
                Section {
                    costComparisonChart
                        .chartReveal()
                } header: {
                    Text("Cost Comparison")
                        .font(.system(.headline, design: .rounded))
                }
            }

            // Insights & Weekly Summary
            if !activeVehicles.isEmpty {
                Section {
                    NavigationLink {
                        WeeklySummaryView()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(theme.accent.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "calendar.badge.clock")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(theme.accent)
                            }
                            .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("This Week's Summary")
                                    .font(.subheadline.weight(.semibold))
                                Text("Services, fuel logs, and activity digest")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .glassBackground(cornerRadius: 14)
                    }
                    .pressable()
                    .accessibilityIdentifier("weeklySummary")
                    .accessibilityLabel("This week's summary")
                    .accessibilityHint("Services, fuel logs, and activity digest")

                    NavigationLink {
                        InsightsView()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(theme.accent.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "chart.bar.xaxis.ascending")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(theme.accent)
                            }
                            .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Insights & Statistics")
                                    .font(.subheadline.weight(.semibold))
                                Text("Spending trends, projections, and analysis")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .glassBackground(cornerRadius: 14)
                    }
                    .pressable()
                    .accessibilityLabel("Insights and statistics")
                    .accessibilityHint("Spending trends, projections, and analysis")
                } header: {
                    Text("Insights")
                        .font(.system(.headline, design: .rounded))
                }
            }

            // Archived vehicles
            let soldVehicles = archivedVehicles.filter(\.isSold)
            if !soldVehicles.isEmpty {
                Section("Sold Vehicles") {
                    ForEach(soldVehicles) { vehicle in
                        HStack(spacing: 12) {
                            Image(systemName: "car.fill")
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vehicle.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let sold = vehicle.soldDate {
                                    Text("Sold \(sold, format: .dateTime.month(.abbreviated).year())")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                            Text("\(vehicle.safeServiceRecords.count) services")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .onTapGesture {
                            haptic.light()
                            selectedVehicle = vehicle
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Sold vehicle: \(vehicle.displayName)\(vehicle.soldDate.map { ", sold \($0, format: .dateTime.month(.abbreviated).year())" } ?? "")")
                        .accessibilityAddTraits(.isButton)
                    }
                }
            }

            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .pressable()
                .accessibilityLabel("Open settings")
            }
        }
        .redacted(reason: isLoaded ? [] : .placeholder)
        .refreshable {
            haptic.refreshPull()
            await ReminderManager.shared.scheduleReminders(for: activeVehicles)
            haptic.success()
            SoundManager.playSaveSuccess()
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Premium Header Banner

    private var premiumHeaderBanner: some View {
        ZStack {
            // 3-color gradient background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.headerGradient[0],
                            theme.headerGradient.count > 1 ? theme.headerGradient[1] : theme.accent,
                            theme.accent.opacity(0.6),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Subtle radial glow overlay
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.15), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 180
                    )
                )

            // Inner highlight at top edge
            VStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 1)
                Spacer()
            }

            // Content
            HStack(spacing: 12) {
                // Icon with circle background
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "car.2.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Your Garage")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(activeVehicles.count) vehicle\(activeVehicles.count == 1 ? "" : "s") · \(totalServiceCount) services")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(minHeight: 64)
        .shadow(color: theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your garage: \(activeVehicles.count) vehicles, \(totalServiceCount) services")
    }

    // MARK: - Fleet Summary Card (Premium Stats)

    private var fleetSummaryCard: some View {
        let compactCount = overdueCount > 0 ? 4 : 3
        let regularCount = overdueCount > 0 ? 4 : 4
        let columns: [GridItem] = Array(
            repeating: GridItem(.flexible(), spacing: sizeClass == .regular ? 12 : 8),
            count: sizeClass == .regular ? regularCount : compactCount
        )

        return LazyVGrid(columns: columns, spacing: 8) {
            premiumStatCard(
                title: "Vehicles",
                value: "\(activeVehicles.count)",
                icon: "car.2.fill",
                color: theme.accent
            )
            .statPop(index: 0)

            premiumStatCard(
                title: "Services",
                value: "\(totalServiceCount)",
                icon: "wrench.fill",
                color: .catEngine
            )
            .statPop(index: 1)

            premiumStatCard(
                title: "Total Cost",
                value: settings.formatCost(totalCost),
                icon: "dollarsign.circle.fill",
                color: .catTires
            )
            .statPop(index: 2)

            if overdueCount > 0 {
                premiumStatCard(
                    title: "Overdue",
                    value: "\(overdueCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: Color.Status.error.shade500
                )
                .statPop(index: 3)
            }
        }
    }

    private func premiumStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            // Icon in circle background
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.system(.callout, design: .rounded, weight: .bold).monospacedDigit())
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background {
            // Double-layer depth: outer material + inner shadow
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)

                // Inner shadow for depth
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.black.opacity(0.04), lineWidth: 1)

                // Top inner highlight
                VStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.08))
                        .frame(height: 0.5)
                        .padding(.horizontal, 1)
                    Spacer()
                }
            }
        }
        .shadow(color: color.opacity(0.12), radius: 6, x: 0, y: 3)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Vehicle Card Grid (iPad Adaptive)

    @ViewBuilder
    private var vehicleCardGrid: some View {
        if sizeClass == .regular, activeVehicles.count > 1 {
            // iPad: 2-column grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 12
            ) {
                ForEach(Array(activeVehicles.enumerated()), id: \.element.id) { index, vehicle in
                    Button {
                        haptic.cardPress()
                        SoundManager.playTransition()
                        selectedVehicle = vehicle
                    } label: {
                        GarageVehicleCard(vehicle: vehicle)
                            .heroTransitionSource(id: vehicle.id, in: heroNamespace)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableButtonStyle())
                    .springStaggeredAppear(index: index, offsetY: 16)
                    .accessibilityHint("Double tap to view vehicle details")
                }
            }
        } else {
            // iPhone: single-column
            ForEach(Array(activeVehicles.enumerated()), id: \.element.id) { index, vehicle in
                Button {
                    haptic.cardPress()
                    SoundManager.playTransition()
                    selectedVehicle = vehicle
                } label: {
                    GarageVehicleCard(vehicle: vehicle)
                        .heroTransitionSource(id: vehicle.id, in: heroNamespace)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .springStaggeredAppear(index: index, offsetY: 16)
                .accessibilityHint("Double tap to view vehicle details")
            }
        }
    }

    // MARK: - Next Service Banner

    private func nextServiceBanner(_ next: (vehicle: Vehicle, type: String, urgency: ReminderUrgency, text: String)) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(colorForUrgency(next.urgency).opacity(0.15))
                    .frame(width: 40, height: 40)
                    .shadow(color: colorForUrgency(next.urgency).opacity(0.3), radius: 6, x: 0, y: 0)
                Image(systemName: next.urgency == .overdue ? "exclamationmark.triangle.fill" : "bell.fill")
                    .font(.body)
                    .foregroundStyle(colorForUrgency(next.urgency))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Next Service Due")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(next.type) — \(next.vehicle.displayName)")
                    .font(.subheadline.weight(.semibold))
                if !next.text.isEmpty {
                    Text(next.text)
                        .font(.caption)
                        .foregroundStyle(colorForUrgency(next.urgency))
                }
            }

            Spacer()

            DueSoonBadge(urgency: next.urgency, compact: true)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .glassBackground(cornerRadius: 14)
        .contentShape(Rectangle())
        .onTapGesture {
            haptic.buttonTap()
            selectedVehicle = next.vehicle
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next service due: \(next.type) for \(next.vehicle.displayName). \(next.text)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to view vehicle details")
    }

    // MARK: - Seasonal Row

    private func seasonalRow(_ suggestion: SeasonalSuggestion) -> some View {
        HStack(spacing: 12) {
            Image(systemName: suggestion.icon)
                .font(.body)
                .foregroundStyle(suggestion.color)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.subheadline.weight(.medium))
                Text(suggestion.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(color: suggestion.color.opacity(0.12), radius: 4, x: 0, y: 2)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Seasonal tip: \(suggestion.title). \(suggestion.detail)")
    }

    // MARK: - Cost Comparison Chart

    private var costComparisonChart: some View {
        let data = activeVehicles.map { vehicle -> (name: String, service: Double, fuel: Double) in
            let svc = vehicle.safeServiceRecords.reduce(0) { $0 + $1.cost }
            let fuel = vehicle.safeFuelLogs.reduce(0) { $0 + $1.totalCost }
            return (name: vehicle.displayName, service: svc, fuel: fuel)
        }

        return VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(data, id: \.name) { item in
                    BarMark(
                        x: .value("Vehicle", item.name),
                        y: .value("Cost", item.service)
                    )
                    .foregroundStyle(Color.catEngine)
                    .position(by: .value("Type", "Services"))

                    BarMark(
                        x: .value("Vehicle", item.name),
                        y: .value("Cost", item.fuel)
                    )
                    .foregroundStyle(Color.catFuel)
                    .position(by: .value("Type", "Fuel"))
                }
            }
            .chartForegroundStyleScale([
                "Services": Color.catEngine,
                "Fuel": Color.catFuel,
            ])
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let cost = value.as(Double.self) {
                        AxisValueLabel {
                            Text(settings.formatCost(cost))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    if let name = value.as(String.self) {
                        AxisValueLabel {
                            Text(name)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Cost comparison chart for \(data.map(\.name).joined(separator: " and "))")
            .accessibilityElement(children: .combine)
        }
    }

    private func colorForUrgency(_ urgency: ReminderUrgency) -> Color {
        switch urgency {
        case .ok: Color.Status.success.shade500
        case .dueSoon: Color.Status.warning.shade500
        case .due: theme.accent
        case .overdue: Color.Status.error.shade500
        }
    }
}

// MARK: - Garage Vehicle Card (Premium Double-Bezel)

struct GarageVehicleCard: View {
    let vehicle: Vehicle
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    private let settings = UserSettings.shared
    private let vehiclePhotoManager = VehiclePhotoManager.shared

    var healthScore: Int {
        MaintenanceScoreEngine.score(for: vehicle)
    }

    var healthColor: Color {
        MaintenanceScoreEngine.color(for: healthScore)
    }

    var totalCost: Double {
        vehicle.safeServiceRecords.reduce(0) { $0 + $1.cost } +
            vehicle.safeFuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    var nextService: (type: String, urgency: ReminderUrgency, text: String)? {
        ServiceReminderEngine.nextServiceSummary(for: vehicle)
    }

    /// Resolves vehicle photo from file or inline data
    private var vehicleImage: UIImage? {
        if let img = vehiclePhotoManager.loadVehiclePhoto(named: vehicle.vehiclePhotoFileName) {
            return img
        }
        if let data = vehicle.photoData {
            return UIImage(data: data)
        }
        return nil
    }

    var body: some View {
        // Outer shell — the "tray"
        VStack(spacing: 0) {
            // Hero image section or vehicle icon header
            if let uiImage = vehicleImage {
                vehicleHeroImage(uiImage)
            } else {
                vehicleIconHeader
            }

            // Inner core — vehicle details
            VStack(alignment: .leading, spacing: 8) {
                // Name + health ring row
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(vehicle.displayName)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))

                        HStack(spacing: 8) {
                            Text(settings.formatMileage(vehicle.currentMileage))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if !vehicle.licensePlate.isEmpty {
                                Text("· \(vehicle.licensePlate)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    Spacer()

                    // Prominent health score ring
                    healthRing
                }

                // Cost summary
                if totalCost > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("Total: \(settings.formatCost(totalCost))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Service urgency badge
                if let next = nextService {
                    HStack(spacing: 4) {
                        DueSoonBadge(urgency: next.urgency)
                        if !next.text.isEmpty, next.urgency != .ok {
                            Text("· \(next.type)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Footer bar — service count + chevron
            HStack {
                let count = vehicle.safeServiceRecords.count
                if count > 0 {
                    Text("\(count) service\(count == 1 ? "" : "s")")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(theme.accent)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        // Outer shell styling — double-bezel architecture
        .background {
            ZStack {
                // Outer shell background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark
                        ? Color(.systemGray6).opacity(0.5)
                        : Color(.systemBackground))

                // Inner highlight — top edge light
                VStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.white.opacity(colorScheme == .dark ? 0.06 : 0.8))
                        .frame(height: 0.5)
                        .padding(.horizontal, 0.5)
                    Spacer()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // Outer border — hairline
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    colorScheme == .dark
                        ? .white.opacity(0.08)
                        : .black.opacity(0.06),
                    lineWidth: 0.5
                )
        )
        // Health-colored accent line on left
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [healthColor.opacity(0.6), healthColor.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.vertical, 12)
                .padding(.leading, 2)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        .shadow(color: healthColor.opacity(0.1), radius: 12, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vehicle.displayName), health \(healthScore) percent, total cost \(UserSettings.shared.formatCost(totalCost))\(nextService.map { ", next service: \($0.type) \($0.urgency.label)" } ?? "")")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Hero Image (when photo exists)

    private func vehicleHeroImage(_ uiImage: UIImage) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipped()

            // Gradient overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 16,
                style: .continuous
            )
        )
        .accessibilityLabel("\(vehicle.displayName) photo")
    }

    // MARK: - Vehicle Icon Header (when no photo)

    private var vehicleIconHeader: some View {
        ZStack {
            // Branded gradient background
            LinearGradient(
                colors: [
                    healthColor.opacity(0.15),
                    theme.accent.opacity(0.08),
                    Color(.systemBackground).opacity(0.01),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 56)

            // Large vehicle icon
            Image(systemName: "car.fill")
                .font(.system(.title2, weight: .medium))
                .foregroundStyle(healthColor.opacity(0.5))
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 16,
                style: .continuous
            )
        )
        .accessibilityHidden(true)
    }

    // MARK: - Health Score Ring (Prominent)

    private var healthRing: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(healthColor.opacity(0.08))
                .frame(width: 56, height: 56)

            ProgressRing(
                progress: Double(healthScore) / 100.0,
                lineWidth: 4.5,
                color: healthColor
            )
            .frame(width: 48, height: 48)

            VStack(spacing: 0) {
                Text("\(healthScore)")
                    .font(.system(.caption, design: .rounded, weight: .bold).monospacedDigit())
                    .foregroundStyle(healthColor)
                Text("%")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(healthColor.opacity(0.7))
            }
        }
        .accessibilityLabel("Health score \(healthScore) percent")
    }
}

// MARK: - iOS 18 Hero Transition Helpers

private extension View {
    /// Applies `.matchedTransitionSource(id:in:)` on iOS 18+, no-op on older.
    @ViewBuilder
    func heroTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Applies `.navigationTransition(.zoom(sourceID:in:))` on iOS 18+, no-op on older.
    @ViewBuilder
    func heroZoomTransition(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
