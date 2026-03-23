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
        activeVehicles.reduce(0) { $0 + $1.serviceRecords.count }
    }

    var totalCost: Double {
        activeVehicles.reduce(0) { total, v in
            total + v.serviceRecords.reduce(0) { $0 + $1.cost } + v.fuelLogs.reduce(0) { $0 + $1.totalCost }
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
                Image(systemName: "car.side.rear.and.collision.and.car.side.front.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(theme.accent)
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5))
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Your Garage is Empty")
                    .font(.title2.weight(.bold))

                Text("Add your first vehicle to start\ntracking maintenance and costs.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddVehicle = true
            } label: {
                Label("Add Vehicle", systemImage: "plus")
                    .font(.headline)
                    .frame(width: 200, height: 50)
                    .foregroundStyle(.white)
                    .background(theme.accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityHint("Opens a form to add a new vehicle")

            Spacer()
        }
    }

    // MARK: - Dashboard List

    private var dashboardList: some View {
        List {
            // Fleet summary
            if !activeVehicles.isEmpty {
                Section {
                    fleetSummaryCard
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
                        .staggeredAppear(index: index)
                        .onTapGesture {
                            haptic.selection()
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
                            ForEach(badges) { badge in
                                MilestoneBadgeView(badge: badge)
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
                            Text("\(vehicle.serviceRecords.count) services")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .onTapGesture {
                            selectedVehicle = vehicle
                        }
                    }
                }
            }

            // Pro upsell
            if !store.isPro && activeVehicles.count >= 1 {
                Section {
                    Button { showProPrompt = true } label: {
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
            }
        }
        .refreshable {
            haptic.light()
            await ReminderManager.shared.scheduleReminders(for: activeVehicles)
            haptic.success()
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
            summaryStatCard(
                title: "Services",
                value: "\(totalServiceCount)",
                icon: "wrench.fill",
                color: .catEngine
            )
            summaryStatCard(
                title: "Total Cost",
                value: settings.formatCost(totalCost),
                icon: "dollarsign.circle.fill",
                color: .catTires
            )
            if overdueCount > 0 {
                summaryStatCard(
                    title: "Overdue",
                    value: "\(overdueCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .wrenchRed
                )
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
    }

    // MARK: - Next Service Banner

    private func nextServiceBanner(_ next: (vehicle: Vehicle, type: String, urgency: ReminderUrgency, text: String)) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(colorForUrgency(next.urgency).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: next.urgency == .overdue ? "exclamationmark.triangle.fill" : "bell.fill")
                    .font(.body)
                    .foregroundStyle(colorForUrgency(next.urgency))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Next Service Due")
                    .font(.caption)
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
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedVehicle = next.vehicle
        }
    }

    // MARK: - Seasonal Row

    private func seasonalRow(_ suggestion: SeasonalSuggestion) -> some View {
        HStack(spacing: 12) {
            Image(systemName: suggestion.icon)
                .font(.body)
                .foregroundStyle(suggestion.color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.subheadline.weight(.medium))
                Text(suggestion.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Cost Comparison Chart

    private var costComparisonChart: some View {
        let data = activeVehicles.map { vehicle -> (name: String, service: Double, fuel: Double) in
            let svc = vehicle.serviceRecords.reduce(0) { $0 + $1.cost }
            let fuel = vehicle.fuelLogs.reduce(0) { $0 + $1.totalCost }
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
        vehicle.serviceRecords.reduce(0) { $0 + $1.cost } +
        vehicle.fuelLogs.reduce(0) { $0 + $1.totalCost }
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
            }

            Spacer()

            let count = vehicle.serviceRecords.count
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
        .accessibilityElement(children: .combine)
    }
}
