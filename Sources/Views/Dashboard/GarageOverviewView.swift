import SwiftUI
import SwiftData
import Charts

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

    // Next service due across all vehicles
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
            total + ServiceReminderEngine.reminders(for: v).filter { $0.urgency == .overdue }.count
        }
    }

    // Seasonal suggestions
    var seasonalSuggestions: [SeasonalSuggestion] {
        SeasonalSuggestionEngine.suggestions(for: activeVehicles)
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeVehicles.isEmpty && archivedVehicles.isEmpty {
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
                        if !store.isPro && activeVehicles.count >= 1 {
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
            .sheet(isPresented: $showProPrompt) {
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "car.side.fill")
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundStyle(theme.accent)
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5))
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Your Garage is Empty")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                Text("Add your first vehicle to start tracking\nmaintenance, fuel costs, and service history.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("No account needed — your data stays on this device.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }

            Button {
                haptic.buttonTap()
                showAddVehicle = true
            } label: {
                Label("Add Vehicle", systemImage: "plus")
                    .font(.headline)
                    .frame(width: 200, height: 50)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(colors: [theme.accent, theme.accent.opacity(0.8)], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .shadow(color: theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel("Add your first vehicle")
            .accessibilityHint("Opens a form to add a new vehicle")
            .pressable()
            .floatIn(delay: 0.3)

            Spacer()
        }
    }

    // MARK: - Dashboard List

    private var dashboardList: some View {
        List {
            // Fleet summary with gradient header
            if !activeVehicles.isEmpty {
                Section {
                    VStack(spacing: 0) {
                        // Gradient header banner
                        HStack(spacing: 10) {
                            Image(systemName: "car.2.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your Garage")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("\(activeVehicles.count) vehicle\(activeVehicles.count == 1 ? "" : "s") · \(totalServiceCount) services")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: theme.headerGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: theme.accent.opacity(0.25), radius: 8, x: 0, y: 4)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Your garage: \(activeVehicles.count) vehicles, \(totalServiceCount) services")
                        .padding(.bottom, 10)

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
                }
            }

            // Vehicles
            Section {
                ForEach(Array(activeVehicles.enumerated()), id: \.element.id) { index, vehicle in
                    GarageVehicleCard(vehicle: vehicle)
                        .heroTransitionSource(id: vehicle.id, in: heroNamespace)
                        .contentShape(Rectangle())
                        .springStaggeredAppear(index: index, offsetY: 16)
                        .scalePressEffect()
                        .onTapGesture {
                            haptic.cardPress()
                            SoundManager.playTransition()
                            selectedVehicle = vehicle
                        }
                }

                // Pro upsell (inline)
                if !store.isPro && activeVehicles.count >= 1 {
                    Button { haptic.buttonTap(); showProPrompt = true } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(theme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Free: 1 vehicle")
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
            let soldVehicles = archivedVehicles.filter { $0.isSold }
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

    // MARK: - Fleet Summary Card

    private var fleetSummaryCard: some View {
        HStack(spacing: 8) {
            summaryStatCard(
                title: "Vehicles",
                value: "\(activeVehicles.count)",
                icon: "car.2.fill",
                color: .wrenchAmber
            )
            .statPop(index: 0)
            summaryStatCard(
                title: "Services",
                value: "\(totalServiceCount)",
                icon: "wrench.fill",
                color: .catEngine
            )
            .statPop(index: 1)
            summaryStatCard(
                title: "Total Cost",
                value: settings.formatCost(totalCost),
                icon: "dollarsign.circle.fill",
                color: .catTires
            )
            .statPop(index: 2)
            if overdueCount > 0 {
                summaryStatCard(
                    title: "Overdue",
                    value: "\(overdueCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .wrenchRed
                )
                .statPop(index: 3)
            }
        }
    }

    private func summaryStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.caption2.weight(.bold).monospacedDigit())
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: color.opacity(0.15), radius: 4, x: 0, y: 2)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
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
                "Fuel": Color.catFuel
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
        case .ok: .wrenchGreen
        case .dueSoon: .wrenchYellow
        case .due: .wrenchAmber
        case .overdue: .wrenchRed
        }
    }
}

// MARK: - Garage Vehicle Card

struct GarageVehicleCard: View {
    let vehicle: Vehicle
    @Environment(\.appTheme) private var theme
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
        HStack(spacing: 14) {
            // Vehicle image / health ring
            ZStack {
                ProgressRing(
                    progress: Double(healthScore) / 100.0,
                    lineWidth: 4,
                    color: healthColor
                )
                .frame(width: 56, height: 56)

                if let uiImage = vehicleImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .accessibilityLabel("\(vehicle.displayName) photo")
                } else {
                    Image(systemName: "car.fill")
                        .font(.title3)
                        .foregroundStyle(healthColor)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.displayName)
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 8) {
                    Text(settings.formatMileage(vehicle.currentMileage))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Health badge
                    HStack(spacing: 3) {
                        Image(systemName: healthScore >= 80 ? "heart.fill" : healthScore >= 50 ? "heart" : "heart.slash")
                            .font(.caption2)
                        Text("\(healthScore)%")
                            .font(.caption2.weight(.medium).monospacedDigit())
                    }
                    .foregroundStyle(healthColor)

                    // License plate
                    if !vehicle.licensePlate.isEmpty {
                        Text("· \(vehicle.licensePlate)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Cost summary
                if totalCost > 0 {
                    Text("Total: \(settings.formatCost(totalCost))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Service urgency badge
                if let next = nextService {
                    HStack(spacing: 4) {
                        DueSoonBadge(urgency: next.urgency)
                        if !next.text.isEmpty && next.urgency != .ok {
                            Text("· \(next.type)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()

            let count = vehicle.safeServiceRecords.count
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .contentTransition(.numericText())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.accent.opacity(0.15), in: Capsule())
                    .foregroundStyle(theme.accent)
                    .accessibilityLabel("\(count) services")
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                .shadow(color: healthColor.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(colors: [healthColor.opacity(0.5), healthColor.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 3)
                .padding(.vertical, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vehicle.displayName), health \(healthScore) percent, total cost \(UserSettings.shared.formatCost(totalCost))\(nextService.map { ", next service: \($0.type) \($0.urgency.label)" } ?? "")")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - iOS 18 Hero Transition Helpers

private extension View {
    /// Applies `.matchedTransitionSource(id:in:)` on iOS 18+, no-op on older.
    @ViewBuilder
    func heroTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// Applies `.navigationTransition(.zoom(sourceID:in:))` on iOS 18+, no-op on older.
    @ViewBuilder
    func heroZoomTransition(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
