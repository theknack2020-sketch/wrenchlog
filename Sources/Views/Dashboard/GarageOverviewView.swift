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
    @State private var selectedVehicle: Vehicle?
    @State private var showArchivedVehicles = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme

    private let store = StoreManager.shared
    private let settings = UserSettings.shared
    private let haptic = HapticManager.shared

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
                    .accessibilityLabel("Add vehicle")
                }
            }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView()
            }
            .sheet(isPresented: $showProPrompt) {
                ProUpgradeView()
            }
            .navigationDestination(item: $selectedVehicle) { vehicle in
                VehicleDetailView(vehicle: vehicle)
            }
            .onAppear {
                Task {
                    await ReminderManager.shared.scheduleReminders(for: activeVehicles)
                }
            }
            .alert("Something Went Wrong", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
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
                    .font(.system(size: 48))
                    .foregroundStyle(theme.accent)
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5))
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Your Garage is Empty")
                    .font(.title2.weight(.bold))

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
                                    .font(.subheadline.weight(.bold))
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
                    }
                    .floatIn(delay: 0.05)
                }
            }

            // Next service due banner
            if let next = nextServiceDue {
                Section {
                    nextServiceBanner(next)
                }
            }

            // Seasonal suggestions
            if !seasonalSuggestions.isEmpty {
                Section("Seasonal Tips") {
                    ForEach(seasonalSuggestions) { suggestion in
                        seasonalRow(suggestion)
                    }
                }
            }

            // Vehicles
            Section("Vehicles") {
                ForEach(Array(activeVehicles.enumerated()), id: \.element.id) { index, vehicle in
                    GarageVehicleCard(vehicle: vehicle)
                        .contentShape(Rectangle())
                        .springStaggeredAppear(index: index, offsetY: 16)
                        .scalePressEffect()
                        .onTapGesture {
                            haptic.cardPress()
                            SoundManager.playTransition()
                            selectedVehicle = vehicle
                        }
                }
            }

            // Milestones
            let badges = MilestoneEngine.earnedBadges(for: activeVehicles)
            if !badges.isEmpty {
                Section("Milestones") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(badges.enumerated()), id: \.element.id) { index, badge in
                                MilestoneBadgeView(badge: badge)
                                    .statPop(index: index)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Multi-vehicle cost comparison
            if activeVehicles.count >= 2 {
                Section("Cost Comparison") {
                    costComparisonChart
                        .chartReveal()
                }
            }

            // Insights link
            if !activeVehicles.isEmpty {
                Section {
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Insights & Statistics")
                                    .font(.subheadline.weight(.semibold))
                                Text("Spending trends, projections, and analysis")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
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
                    }
                }
            }

            // Pro upsell
            if !store.isPro && activeVehicles.count >= 1 {
                Section {
                    Button { haptic.buttonTap(); showProPrompt = true } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(theme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Free: 1 vehicle")
                                    .font(.subheadline.weight(.medium))
                                Text("Upgrade to Pro for unlimited vehicles, photos, PDF export")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityLabel("Upgrade to Pro for unlimited vehicles")
                }
            }

            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .accessibilityLabel("Open settings")
            }
        }
        .refreshable {
            haptic.refreshPull()
            await ReminderManager.shared.scheduleReminders(for: activeVehicles)
            haptic.success()
            SoundManager.playSaveSuccess()
        }
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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: color.opacity(0.10), radius: 4, x: 0, y: 2)
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
        .contentShape(Rectangle())
        .onTapGesture {
            haptic.buttonTap()
            selectedVehicle = next.vehicle
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next service due: \(next.type) for \(next.vehicle.displayName). \(next.text)")
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
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: suggestion.color.opacity(0.10), radius: 4, x: 0, y: 2)
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
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
                .shadow(color: healthColor.opacity(0.12), radius: 8, x: 0, y: 4)
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
    }
}
