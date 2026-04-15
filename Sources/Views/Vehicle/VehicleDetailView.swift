import SwiftData
import SwiftUI
import TipKit

// MARK: - Sort Options

enum ServiceSortOption: String, CaseIterable, Identifiable {
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case costHighest = "Cost (Highest)"
    case costLowest = "Cost (Lowest)"
    case type = "Service Type"

    var id: String {
        rawValue
    }
}

// MARK: - Vehicle Detail

struct VehicleDetailView: View {
    @Bindable var vehicle: Vehicle
    @State private var showAddService = false
    @State private var showAddFuel = false
    @State private var showEditVehicle = false
    @State private var showEditMileage = false
    @State private var showCostAnalytics = false
    @State private var showPDFShare = false
    @State private var showProPrompt = false
    @State private var showDeleteRecord = false
    @State private var showSellVehicle = false
    @State private var recordToDelete: ServiceRecord?
    @State private var serviceRecordForEdit: ServiceRecord?
    @State private var newMileage = ""
    @State private var pdfData: Data?
    @State private var showQuickStart = QuickStartState.shouldShow

    // Undo support
    @State private var showUndoBanner = false
    @State private var mileageValidationError: String?

    // Error handling
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    // Recalls
    @State private var recalls: [RecallInfo] = []
    @State private var isLoadingRecalls = false
    @State private var recallError: String?

    // Search & Filter & Sort
    @State private var searchText = ""
    @State private var filterCategory: ServiceCategory?
    @State private var sortOption: ServiceSortOption = .dateNewest

    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private let settings = UserSettings.shared
    private let store = StoreManager.shared
    private let photoManager = ServicePhotoManager.shared
    private let vehiclePhotoManager = VehiclePhotoManager.shared
    private let haptic = HapticManager.shared

    // MARK: - Computed

    var filteredAndSortedRecords: [ServiceRecord] {
        var records = vehicle.safeServiceRecords
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            records = records.filter {
                $0.displayServiceType.lowercased().contains(query) ||
                    $0.notes.lowercased().contains(query) ||
                    $0.categoryRaw.lowercased().contains(query)
            }
        }
        if let cat = filterCategory {
            records = records.filter { $0.categoryRaw == cat.rawValue }
        }
        switch sortOption {
        case .dateNewest: records.sort { $0.date > $1.date }
        case .dateOldest: records.sort { $0.date < $1.date }
        case .costHighest: records.sort { $0.cost > $1.cost }
        case .costLowest: records.sort { $0.cost < $1.cost }
        case .type: records.sort { $0.displayServiceType < $1.displayServiceType }
        }
        return records
    }

    var totalCost: Double {
        vehicle.safeServiceRecords.reduce(0) { $0 + $1.cost }
    }

    var totalFuelCost: Double {
        vehicle.safeFuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    var totalOwnershipCost: Double {
        totalCost + totalFuelCost
    }

    var latestEfficiency: String? {
        let results = vehicle.safeFuelLogs.calculateEfficiency()
        guard let latest = results.last else { return nil }
        return settings.formatEfficiency(latest.efficiency(for: settings.efficiencyUnit))
    }

    var healthScore: Int {
        MaintenanceScoreEngine.score(for: vehicle)
    }

    var upcomingReminders: [(type: String, icon: String, dueText: String, isOverdue: Bool)] {
        var reminders: [(String, String, String, Bool)] = []
        let calendar = Calendar.current
        for serviceType in ServiceType.allCases {
            guard serviceType.defaultMonthInterval > 0 else { continue }
            let lastRecord = vehicle.safeServiceRecords
                .filter { $0.serviceTypeRaw == serviceType.rawValue }
                .sorted { $0.date > $1.date }
                .first
            if let last = lastRecord {
                let nextDue = calendar.date(byAdding: .month, value: serviceType.defaultMonthInterval, to: last.date) ?? Date()
                let isOverdue = nextDue < Date()
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                let dueText = isOverdue ? "Overdue" : formatter.localizedString(for: nextDue, relativeTo: Date())
                reminders.append((serviceType.rawValue, serviceType.uniqueIcon, dueText, isOverdue))
            }
        }
        return reminders.sorted { $0.3 && !$1.3 }
    }

    private var mileageProgress: Double {
        let m = Double(vehicle.currentMileage)
        let milestone = ceil(m / 50000) * 50000
        return milestone > 0 ? m / milestone : 0
    }

    /// Resolves vehicle photo from file system or inline data
    private var vehicleImage: UIImage? {
        if let img = vehiclePhotoManager.loadVehiclePhoto(named: vehicle.vehiclePhotoFileName) { return img }
        if let data = vehicle.photoData { return UIImage(data: data) }
        return nil
    }

    // MARK: - Mini Stat Computations

    private var averageCostPerService: Double {
        let paid = vehicle.safeServiceRecords.filter { $0.cost > 0 }
        guard !paid.isEmpty else { return 0 }
        return paid.reduce(0) { $0 + $1.cost } / Double(paid.count)
    }

    private var lastServiceDate: Date? {
        vehicle.safeServiceRecords.sorted { $0.date > $1.date }.first?.date
    }

    private var mostExpensiveService: ServiceRecord? {
        vehicle.safeServiceRecords.max { $0.cost < $1.cost }
    }

    private var daysSinceLastService: Int? {
        guard let lastDate = lastServiceDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }

    // MARK: - Body

    var body: some View {
        List {
            if showQuickStart {
                Section {
                    QuickStartTooltip(isVisible: $showQuickStart, tips: QuickStartState.vehicleDetailTips)
                }
            }
            photoHeaderSection
            dashboardSection
                .floatIn(delay: 0.05)
            miniStatCardsSection
            vehicleInfoSection
            recallsSection
            documentsSection
            toolsSection
            remindersSection
            fuelTrackingSection
            serviceHistorySection
            actionsSection
        }
        .navigationTitle("Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar }
        .sheet(isPresented: $showAddService) { AddServiceView(vehicle: vehicle) }
        .sheet(isPresented: $showAddFuel) { AddFuelLogView(vehicle: vehicle) }
        .sheet(isPresented: $showEditVehicle) { EditVehicleView(vehicle: vehicle) }
        .fullScreenCover(isPresented: $showProPrompt) { ProUpgradeView() }
        .sheet(isPresented: $showSellVehicle) { SellVehicleView(vehicle: vehicle) }
        .sheet(isPresented: $showPDFShare) {
            if let data = pdfData { ShareSheetView(items: [data]) }
        }
        .navigationDestination(isPresented: $showCostAnalytics) { CostAnalyticsView(vehicle: vehicle) }
        .navigationDestination(item: $serviceRecordForEdit) { record in
            EditServiceView(record: record)
        }
        .alert("Update Mileage", isPresented: $showEditMileage) {
            TextField(settings.distanceUnit.label, text: $newMileage).keyboardType(.numberPad)
            Button("Update") { handleMileageUpdate() }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let error = mileageValidationError {
                Text(error)
            } else {
                Text("Current: \(settings.formatMileage(vehicle.currentMileage))")
            }
        }
        .onChange(of: showEditMileage) { _, showing in
            if showing { mileageValidationError = nil }
        }
        .confirmationDialog("Delete Service Record?", isPresented: $showDeleteRecord, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { handleDeleteRecord() }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let record = recordToDelete {
                Text("Delete '\(record.displayServiceType)' from \(record.date, format: .dateTime.month(.abbreviated).day())?")
            }
        }
        .alert("Something Went Wrong", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await loadRecalls()
        }
        .overlay(alignment: .bottom) {
            if showUndoBanner {
                undoBanner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var detailToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    haptic.buttonTap()
                    showAddService = true
                } label: { Label("Log Service", systemImage: "wrench.fill") }
                Button {
                    haptic.buttonTap()
                    showAddFuel = true
                } label: { Label("Log Fuel", systemImage: "fuelpump.fill") }
            } label: {
                Image(systemName: "plus.circle.fill").foregroundStyle(theme.accent)
            }
            .accessibilityIdentifier("vehicleDetailAdd")
            .accessibilityLabel("Add record")
            .accessibilityHint("Log a new service or fuel fill-up")
        }
    }

    // MARK: - Photo Header

    private var photoHeaderSection: some View {
        Section {
            ZStack(alignment: .bottomLeading) {
                if let img = vehicleImage {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 240)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .accessibilityLabel("\(vehicle.displayName) photo")
                } else {
                    // Gradient placeholder when no photo — rich multi-layer design
                    let vehicleTint = vehicle.vehicleColor?.color ?? theme.accent
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [
                                    vehicleTint.opacity(0.55),
                                    theme.accent.opacity(0.35),
                                    vehicleTint.opacity(0.15),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                        .overlay {
                            // Decorative blur orbs for depth
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 180, height: 180)
                                    .blur(radius: 30)
                                    .offset(x: -90, y: -50)
                                Circle()
                                    .fill(theme.accent.opacity(0.25))
                                    .frame(width: 140, height: 140)
                                    .blur(radius: 25)
                                    .offset(x: 100, y: 60)
                            }
                        }
                        .overlay {
                            // Large car silhouette
                            Image(systemName: "car.side.fill")
                                .font(.system(size: 100, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                                .offset(y: -16)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .accessibilityHidden(true)
                }

                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.35), .black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.displayName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    if !vehicle.licensePlate.isEmpty {
                        Text(vehicle.licensePlate)
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.15), in: Capsule())
                    }
                }
                .padding(16)
                .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 2)
            }
            .shadow(color: theme.accent.opacity(0.2), radius: 12, x: 0, y: 6)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }

    // MARK: - Dashboard

    private var dashboardSection: some View {
        Section {
            VStack(spacing: 16) {
                dashboardInfoRow
                dashboardSpeedometer
                dashboardStats
                if !vehicle.safeFuelLogs.isEmpty { dashboardFuelStats }
            }
            .glassBackground(cornerRadius: 14)
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
    }

    @ViewBuilder
    private var dashboardInfoRow: some View {
        if vehicleImage == nil {
            HStack(spacing: 16) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.accent.opacity(0.12))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Image(systemName: "car.side.fill").font(.system(.title2, design: .rounded)).foregroundStyle(theme.accent)
                        }
                        .accessibilityHidden(true)
                    if let vc = vehicle.vehicleColor {
                        Circle().fill(vc.color).frame(width: 16, height: 16)
                            .overlay { Circle().strokeBorder(vc.needsBorder ? Color.secondary.opacity(0.4) : .clear, lineWidth: 1) }
                            .offset(x: 4, y: 4)
                            .accessibilityHidden(true)
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(vehicle.displayName).font(.title3.weight(.bold)).accessibilityAddTraits(.isHeader)
                    HStack(spacing: 8) {
                        if !vehicle.licensePlate.isEmpty {
                            Text(vehicle.licensePlate).font(.caption.weight(.medium).monospacedDigit()).foregroundStyle(.secondary)
                        }
                        healthBadge
                    }
                    let age = Calendar.current.component(.year, from: .now) - vehicle.year
                    if age >= 0 {
                        Text("\(age) year\(age == 1 ? "" : "s") old").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Button {
                    haptic.buttonTap()
                    showEditVehicle = true
                } label: {
                    Image(systemName: "pencil.circle.fill").font(.title3).foregroundStyle(theme.accent)
                }
                .accessibilityLabel("Edit vehicle")
            }
        } else {
            HStack {
                HStack(spacing: 8) {
                    if let vc = vehicle.vehicleColor {
                        Circle().fill(vc.color).frame(width: 12, height: 12)
                            .overlay { Circle().strokeBorder(vc.needsBorder ? Color.secondary.opacity(0.4) : .clear, lineWidth: 1) }
                            .accessibilityHidden(true)
                    }
                    healthBadge
                    let age = Calendar.current.component(.year, from: .now) - vehicle.year
                    if age >= 0 {
                        Text("· \(age) yr\(age == 1 ? "" : "s") old").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Button {
                    haptic.buttonTap()
                    showEditVehicle = true
                } label: {
                    Image(systemName: "pencil.circle.fill").font(.title3).foregroundStyle(theme.accent)
                }
                .accessibilityLabel("Edit vehicle")
            }
        }
    }

    private var healthBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: MaintenanceScoreEngine.icon(for: healthScore)).font(.caption2)
                .foregroundStyle(MaintenanceScoreEngine.color(for: healthScore))
            Text("Health: \(MaintenanceScoreEngine.label(for: healthScore))")
                .font(.caption2.weight(.medium))
                .foregroundStyle(MaintenanceScoreEngine.color(for: healthScore))
        }
        .accessibilityLabel("Maintenance health: \(MaintenanceScoreEngine.label(for: healthScore))")
    }

    private var dashboardSpeedometer: some View {
        let healthColor = MaintenanceScoreEngine.color(for: healthScore)
        let healthLabel = MaintenanceScoreEngine.label(for: healthScore)

        return VStack(spacing: 10) {
            // Hero Health Score ring — dominant element
            ZStack {
                // Outer glow
                Circle()
                    .fill(healthColor.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .blur(radius: 12)

                // Track
                Circle()
                    .stroke(healthColor.opacity(0.12), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 120, height: 120)

                // Progress
                Circle()
                    .trim(from: 0, to: CGFloat(healthScore) / 100.0)
                    .stroke(
                        LinearGradient(colors: [healthColor, healthColor.opacity(0.7)], startPoint: .top, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: healthColor.opacity(0.35), radius: 8, x: 0, y: 0)

                // Center content
                VStack(spacing: 1) {
                    Text("\(healthScore)")
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy).monospacedDigit())
                        .foregroundStyle(healthColor)
                        .contentTransition(.numericText())
                    Text("Health")
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Health score: \(healthScore) out of 100, \(healthLabel)")

            // Mileage — tappable to update
            Button {
                haptic.buttonTap()
                showEditMileage = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gauge.open.with.needle.33percent")
                        .font(.caption)
                        .foregroundStyle(theme.accent)
                    Text(vehicle.currentMileage > 0 ? vehicle.currentMileage.formatted() : "—")
                        .font(.system(.headline, design: .rounded, weight: .semibold).monospacedDigit())
                    Text(settings.distanceUnit.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Image(systemName: "pencil.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(theme.accent.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Current mileage: \(settings.formatMileage(vehicle.currentMileage)). Double tap to update.")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private var dashboardStats: some View {
        HStack(spacing: 8) {
            statCard(title: "Total Spent", value: settings.formatCost(totalOwnershipCost), icon: "dollarsign.circle.fill", color: theme.accent)
                .statPop(index: 0)
            statCard(title: "Services", value: "\(vehicle.safeServiceRecords.count)", icon: "wrench.fill", color: .catEngine)
                .statPop(index: 1)
            statCard(title: "Age", value: "\(max(0, Calendar.current.component(.year, from: .now) - vehicle.year)) yr", icon: "calendar", color: .catElectrical)
                .statPop(index: 2)
        }
    }

    private var dashboardFuelStats: some View {
        HStack(spacing: 8) {
            statCard(title: "Fuel Cost", value: settings.formatCost(totalFuelCost), icon: "fuelpump.fill", color: .catFuel)
            statCard(title: "Fill-Ups", value: "\(vehicle.safeFuelLogs.count)", icon: "drop.fill", color: .catFuelRegular)
            if let eff = latestEfficiency {
                statCard(title: "Latest", value: eff, icon: "gauge.medium", color: .catTires)
            }
        }
    }

    // MARK: - Mini Stat Cards

    private var miniStatCardsSection: some View {
        Section {
            VStack(spacing: 10) {
                if sizeClass == .regular {
                    // iPad: 4 cards in one row
                    HStack(spacing: 8) {
                        miniStatCard(
                            title: "Total Spent",
                            value: settings.formatCost(totalOwnershipCost),
                            icon: "dollarsign.circle.fill",
                            color: theme.accent
                        )
                        miniStatCard(
                            title: "Avg/Service",
                            value: averageCostPerService > 0 ? settings.formatCost(averageCostPerService) : "—",
                            icon: "equal.circle.fill",
                            color: .catFilters
                        )
                        miniStatCard(
                            title: "Services",
                            value: "\(vehicle.safeServiceRecords.count)",
                            icon: "wrench.fill",
                            color: .catEngine
                        )
                        miniStatCard(
                            title: "Last Service",
                            value: lastServiceDateLabel,
                            icon: "calendar.badge.clock",
                            color: lastServiceColor
                        )
                    }
                } else {
                    // iPhone: 2x2 grid
                    HStack(spacing: 8) {
                        miniStatCard(
                            title: "Total Spent",
                            value: settings.formatCost(totalOwnershipCost),
                            icon: "dollarsign.circle.fill",
                            color: theme.accent
                        )
                        miniStatCard(
                            title: "Avg/Service",
                            value: averageCostPerService > 0 ? settings.formatCost(averageCostPerService) : "—",
                            icon: "equal.circle.fill",
                            color: .catFilters
                        )
                    }
                    HStack(spacing: 8) {
                        miniStatCard(
                            title: "Services",
                            value: "\(vehicle.safeServiceRecords.count)",
                            icon: "wrench.fill",
                            color: .catEngine
                        )
                        miniStatCard(
                            title: "Last Service",
                            value: lastServiceDateLabel,
                            icon: "calendar.badge.clock",
                            color: lastServiceColor
                        )
                    }
                }
                if let expensive = mostExpensiveService, expensive.cost > 0 {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.Status.error.shade500)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Most Expensive")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("\(expensive.displayServiceType) — \(settings.formatCost(expensive.cost))")
                                .font(.caption.weight(.medium).monospacedDigit())
                        }
                        Spacer()
                        Text(expensive.date, format: .dateTime.month(.abbreviated).year(.twoDigits))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Most expensive service: \(expensive.displayServiceType), \(settings.formatCost(expensive.cost))")
                }
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(colors: theme.headerGradient, startPoint: .leading, endPoint: .trailing)
                    )
                Text("Quick Stats")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: theme.headerGradient, startPoint: .leading, endPoint: .trailing)
                    )
            }
        }
    }

    private var lastServiceDateLabel: String {
        guard let date = lastServiceDate else { return "None" }
        if let days = daysSinceLastService {
            if days == 0 { return "Today" }
            if days == 1 { return "Yesterday" }
            if days < 30 { return "\(days)d ago" }
            if days < 365 { return "\(days / 30)mo ago" }
            return "\(days / 365)yr ago"
        }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private var lastServiceColor: Color {
        guard let days = daysSinceLastService else { return .secondary }
        if days <= 90 { return Color.Status.success.shade500 }
        if days <= 180 { return Color.Status.warning.shade500 }
        return Color.Status.error.shade500
    }

    private func miniStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.18), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.subheadline, design: .rounded, weight: .bold).monospacedDigit())
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.12), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Vehicle Info

    @ViewBuilder
    private var vehicleInfoSection: some View {
        if !vehicle.vin.isEmpty || vehicle.purchasePrice > 0 {
            Section("Vehicle Info") {
                if !vehicle.vin.isEmpty {
                    HStack {
                        Label("VIN", systemImage: "barcode").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Text(vehicle.vin).font(.caption.monospacedDigit()).textSelection(.enabled)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("VIN: \(vehicle.vin)")
                }
                if vehicle.purchasePrice > 0 { purchaseInfoRows }
            }
        }
    }

    @ViewBuilder
    private var purchaseInfoRows: some View {
        HStack {
            Label("Purchase Price", systemImage: "tag.fill").font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(settings.formatCost(vehicle.purchasePrice)).font(.subheadline.weight(.semibold).monospacedDigit())
        }
        if let purchaseDate = vehicle.purchaseDate {
            HStack {
                Label("Purchased", systemImage: "calendar").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text(purchaseDate, format: .dateTime.month(.abbreviated).day().year()).font(.subheadline)
            }
        }
        if let currentValue = vehicle.estimatedCurrentValue, let depreciation = vehicle.estimatedDepreciation {
            Divider()
            HStack {
                Label("Est. Value", systemImage: "chart.line.downtrend.xyaxis").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text(settings.formatCost(currentValue)).font(.subheadline.weight(.semibold).monospacedDigit()).foregroundStyle(Color.catTires)
            }
            HStack {
                Label("Depreciation", systemImage: "arrow.down.right").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("-\(settings.formatCost(depreciation))").font(.caption.weight(.medium).monospacedDigit()).foregroundStyle(Color.Status.error.shade500)
            }
            if vehicle.yearsOwned > 0 {
                HStack {
                    Text("Per Year").font(.caption).foregroundStyle(.tertiary).padding(.leading, 28)
                    Spacer()
                    Text("~\(settings.formatCost(depreciation / Double(vehicle.yearsOwned)))/yr")
                        .font(.caption.monospacedDigit()).foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Safety Recalls

    @ViewBuilder
    private var recallsSection: some View {
        if isLoadingRecalls || !recalls.isEmpty || recallError != nil {
            Section {
                if isLoadingRecalls {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking for recalls…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityLabel("Checking for safety recalls")
                } else if let error = recallError {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button {
                            Task { await loadRecalls() }
                        } label: {
                            Label("Try Again", systemImage: "arrow.clockwise")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(theme.accent)
                        }
                        .pressable()
                        .accessibilityLabel("Retry recall check")
                        .accessibilityHint("Tries to load safety recalls again")
                    }
                    .padding(.vertical, 2)
                } else if recalls.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                        Text("No open recalls")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                    .accessibilityLabel("No open safety recalls found")
                } else {
                    ForEach(recalls) { recall in
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 10) {
                                if !recall.component.isEmpty {
                                    recallDetailRow(label: "Component", value: recall.component)
                                }
                                if !recall.summary.isEmpty {
                                    recallDetailRow(label: "Summary", value: recall.summary)
                                }
                                if !recall.consequence.isEmpty {
                                    recallDetailRow(label: "Risk", value: recall.consequence)
                                }
                                if !recall.remedy.isEmpty {
                                    recallDetailRow(label: "Remedy", value: recall.remedy)
                                }
                                if !recall.reportReceivedDate.isEmpty {
                                    recallDetailRow(label: "Reported", value: recall.reportReceivedDate)
                                }
                            }
                            .padding(.vertical, 4)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.Status.error.shade500)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recall.campaignNumber)
                                        .font(.subheadline.weight(.semibold))
                                    if !recall.component.isEmpty {
                                        Text(recall.component)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .accessibilityLabel("Recall \(recall.campaignNumber), \(recall.component)")
                        .accessibilityHint("Expand to see recall details")
                    }
                }
            } header: {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: recalls.isEmpty ? [.green, .green.opacity(0.7)] : [Color.Status.error.shade500, Color.Status.error.shade500.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Safety Recalls")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: recalls.isEmpty ? [.green, .green.opacity(0.7)] : [Color.Status.error.shade500, Color.Status.error.shade500.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    if !recalls.isEmpty {
                        Text("\(recalls.count)")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.Status.error.shade500, in: Capsule())
                            .foregroundStyle(.white)
                            .accessibilityLabel("\(recalls.count) open recalls")
                    }
                }
            }
        }
    }

    private func recallDetailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Documents

    private var documentsSection: some View {
        Section {
            NavigationLink {
                VehicleDocumentsView(vehicle: vehicle)
            } label: {
                HStack {
                    Label("Documents", systemImage: "doc.text.fill").foregroundStyle(theme.accent)
                    Spacer()
                    let docCount = vehicle.safeDocuments.count
                    if docCount > 0 {
                        Text("\(docCount)")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(theme.accent.opacity(0.15), in: Capsule())
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .pressable()
            .accessibilityLabel("Documents, \(vehicle.safeDocuments.count) stored")

            let expiringDocs = Array(vehicle.safeDocuments.filter { doc in
                guard let expiry = doc.expirationDate else { return false }
                return (Calendar.current.dateComponents([.day], from: .now, to: expiry).day ?? 999) <= 30
            })
            if !expiringDocs.isEmpty {
                ForEach(expiringDocs, id: \.id) { doc in
                    if let expiry = doc.expirationDate {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").font(.caption)
                                .foregroundStyle(expiry < Date() ? Color.Status.error.shade500 : theme.accent)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(doc.title).font(.caption.weight(.medium))
                                Text(expiry < Date() ? "Expired" : "Expires \(expiry, format: .dateTime.month(.abbreviated).day())")
                                    .font(.caption2).foregroundStyle(expiry < Date() ? .red : .secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tools

    private var toolsSection: some View {
        Section {
            TipView(LogServiceTip())
                .tipBackground(theme.accent.opacity(0.08))

            VStack(spacing: 0) {
                NavigationLink { MaintenanceTimelineView(vehicle: vehicle) } label: {
                    Label("Maintenance Timeline", systemImage: "clock.arrow.circlepath").foregroundStyle(theme.accent)
                }
                .pressable()
                .accessibilityLabel("View maintenance timeline")

                Divider().padding(.leading, 36).accessibilityHidden(true)

                NavigationLink { MaintenanceChecklistView(vehicle: vehicle) } label: {
                    HStack {
                        Label("Maintenance Checklist", systemImage: "checklist")
                        Spacer()
                        let pending = vehicle.safeChecklistItems.count(where: { !$0.isCompleted })
                        if pending > 0 {
                            Text("\(pending)")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(theme.accent.opacity(0.15), in: Capsule())
                                .foregroundStyle(theme.accent)
                        }
                    }
                    .foregroundStyle(theme.accent)
                }
                .pressable()
                .accessibilityLabel("Maintenance checklist, \(vehicle.safeChecklistItems.count(where: { !$0.isCompleted })) pending items")

                Divider().padding(.leading, 36).accessibilityHidden(true)

                NavigationLink { ReminderSettingsView(vehicle: vehicle) } label: {
                    Label("Reminder Settings", systemImage: "bell.fill").foregroundStyle(theme.accent)
                }
                .pressable()
                .accessibilityLabel("Configure service reminders")
            }
            .padding(.vertical, 4)
            .glassBackground(cornerRadius: 14)
        } header: {
            Text("Tools")
                .font(.system(.headline, design: .rounded))
        }
    }

    // MARK: - Reminders

    @ViewBuilder
    private var remindersSection: some View {
        if !upcomingReminders.isEmpty {
            Section("Upcoming Service") {
                ForEach(upcomingReminders.prefix(6), id: \.type) { reminder in
                    HStack(spacing: 10) {
                        Image(systemName: reminder.icon).font(.caption)
                            .foregroundStyle(reminder.isOverdue ? Color.Status.error.shade500 : Color.Status.success.shade500)
                            .frame(width: 22)
                            .accessibilityHidden(true)
                        Text(reminder.type).font(.subheadline)
                        Spacer()
                        Text(reminder.dueText).font(.caption)
                            .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(reminder.type), \(reminder.dueText)")
                }
            }
        }
    }

    // MARK: - Fuel Tracking

    private var fuelTrackingSection: some View {
        Section {
            if vehicle.safeFuelLogs.isEmpty {
                fuelEmptyState
            } else {
                fuelLogsList
            }
        } header: {
            Text("Fuel Tracking")
                .font(.system(.headline, design: .rounded))
        }
    }

    private var fuelEmptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color.catFuel.opacity(0.1)).frame(width: 64, height: 64)
                    Image(systemName: "fuelpump.circle.fill").font(.system(.title, design: .rounded)).foregroundStyle(Color.catFuel.opacity(0.4))
                }
                .accessibilityHidden(true)
                Text("No fuel logs yet").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                Text("Start tracking fuel to see your efficiency.").font(.caption).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                Button { haptic.buttonTap(); showAddFuel = true } label: {
                    Label("Log First Fill-Up", systemImage: "plus.circle.fill").font(.caption.weight(.medium)).foregroundStyle(theme.accent)
                }
                .pressable()
                .accessibilityLabel("Log your first fuel fill-up")
            }
            .padding(.vertical, 16)
            Spacer()
        }
    }

    @ViewBuilder
    private var fuelLogsList: some View {
        let recentFuel = vehicle.safeFuelLogs.sorted { $0.date > $1.date }.prefix(3)
        let effResults = vehicle.safeFuelLogs.calculateEfficiency()
        ForEach(Array(recentFuel)) { log in
            NavigationLink { EditFuelLogView(fuelLog: log) } label: {
                FuelLogRow(log: log, efficiency: effResults.first { $0.date == log.date && $0.mileage == log.mileage })
            }
            .pressable()
        }
        Button { haptic.buttonTap(); showAddFuel = true } label: {
            Label("Add Fill-Up", systemImage: "plus.circle").foregroundStyle(theme.accent).font(.subheadline)
        }
        .pressable()
        .accessibilityLabel("Add fuel fill-up")
        NavigationLink { FuelHistoryView(vehicle: vehicle) } label: {
            Label("All Fuel History", systemImage: "list.bullet").foregroundStyle(theme.accent)
        }
        .pressable()
        .accessibilityLabel("View all fuel history")
        NavigationLink { FuelEfficiencyChartView(vehicle: vehicle) } label: {
            Label("Fuel Efficiency & Charts", systemImage: "chart.xyaxis.line").foregroundStyle(theme.accent)
        }
        .pressable()
        .accessibilityLabel("Fuel efficiency charts")
    }

    // MARK: - Service History

    private var serviceHistorySection: some View {
        Section {
            serviceSearchBar
            serviceFilterBar
            serviceResultsList
        } header: {
            HStack {
                Text("Service History")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                if !vehicle.safeServiceRecords.isEmpty {
                    Text(serviceHistorySubtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var serviceHistorySubtitle: String {
        let count = vehicle.safeServiceRecords.count
        switch count {
        case 1 ... 4: return "\(count) logged — off to a great start!"
        case 5 ... 14: return "\(count) logged — solid record keeping 👍"
        case 15 ... 49: return "\(count) logged — your car thanks you!"
        default: return "\(count) logged — maintenance pro 🏆"
        }
    }

    private var serviceSearchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search services...", text: $searchText)
                .font(.subheadline)
                .accessibilityLabel("Search services")
                .accessibilityIdentifier("serviceSearchField")
        }
    }

    private var serviceFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    ForEach(ServiceSortOption.allCases) { option in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { sortOption = option }
                            haptic.selection()
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down").font(.caption2)
                        Text(sortOption.rawValue).font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(theme.accent.opacity(0.12), in: Capsule())
                    .foregroundStyle(theme.accent)
                }
                .accessibilityLabel("Sort by \(sortOption.rawValue)")
                .accessibilityHint("Double tap to change sort order")
                filterChip(label: "All", isSelected: filterCategory == nil) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { filterCategory = nil }
                    haptic.selection()
                }
                ForEach(ServiceCategory.allCases.filter { $0 != .custom }, id: \.self) { cat in
                    filterChip(label: cat.rawValue, icon: cat.icon, isSelected: filterCategory == cat) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            filterCategory = filterCategory == cat ? nil : cat
                        }
                        haptic.selection()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var serviceResultsList: some View {
        if filteredAndSortedRecords.isEmpty {
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    if vehicle.safeServiceRecords.isEmpty {
                        ZStack {
                            Circle().fill(theme.accent.opacity(0.08)).frame(width: 72, height: 72)
                            Image(systemName: "wrench.and.screwdriver.fill").font(.system(.title2, design: .rounded)).foregroundStyle(theme.accent.opacity(0.3))
                        }
                        .accessibilityHidden(true)
                        Text("No services logged yet").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                        Text("Tap + to add your first oil change,\ntire rotation, or any service.")
                            .font(.caption).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                    } else {
                        Image(systemName: "magnifyingglass").font(.title2).foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                        Text("No matching services").font(.subheadline).foregroundStyle(.secondary)
                        Button("Clear Filters") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { searchText = ""; filterCategory = nil }
                            haptic.light()
                        }
                        .font(.caption.weight(.medium)).foregroundStyle(theme.accent)
                        .accessibilityLabel("Clear search filters")
                    }
                }
                .padding(.vertical, 20)
                Spacer()
            }
        } else {
            ForEach(Array(filteredAndSortedRecords.enumerated()), id: \.element.id) { index, record in
                NavigationLink { EditServiceView(record: record) } label: { ServiceRecordRow(record: record) }
                    .pressable()
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            haptic.warning()
                            recordToDelete = record
                            showDeleteRecord = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        NavigationLink {
                            EditServiceView(record: record)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        ShareLink(item: shareTextForServiceRecord(record)) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            serviceRecordForEdit = record
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            haptic.warning()
                            recordToDelete = record
                            showDeleteRecord = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .simultaneousGesture(TapGesture().onEnded { haptic.light() })
                    .staggeredAppear(index: index)
            }
            .onDelete { indexSet in
                haptic.warning()
                recordToDelete = indexSet.first.map { filteredAndSortedRecords[$0] }
                showDeleteRecord = true
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section {
            Button {
                haptic.buttonTap()
                if store.isPro {
                    showCostAnalytics = true
                } else {
                    TelemetryService.paywallShown(source: "vehicle_detail_cost_analytics")
                    showProPrompt = true
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accent.opacity(0.2), theme.accent.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        Image(systemName: "chart.bar.fill")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(theme.accent)
                    }
                    Text("Cost Analytics")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if !store.isPro {
                        Image(systemName: "crown.fill").font(.caption).foregroundStyle(theme.accent)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.primary)
            }
            .pressable()
            .accessibilityLabel("Cost analytics\(store.isPro ? "" : ", Pro feature")")

            Button {
                haptic.buttonTap()
                if store.isPro {
                    exportPDF()
                } else {
                    TelemetryService.paywallShown(source: "vehicle_detail_pdf_export")
                    showProPrompt = true
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accent.opacity(0.2), theme.accent.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        Image(systemName: "doc.text.fill")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(theme.accent)
                    }
                    Text("Export PDF Report")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if !store.isPro {
                        Image(systemName: "crown.fill").font(.caption).foregroundStyle(theme.accent)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.primary)
            }
            .pressable()
            .accessibilityLabel("Export PDF report\(store.isPro ? "" : ", Pro feature")")

            ShareLink(item: vehicleSummaryShareText) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accent.opacity(0.2), theme.accent.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(theme.accent)
                    }
                    Text("Share Vehicle Summary")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.primary)
            }
            .pressable()
            .accessibilityLabel("Share vehicle summary")

            Button(role: .destructive) {
                haptic.warning()
                showSellVehicle = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.Status.error.shade500.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "tag.fill")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    Text("Mark as Sold")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                }
            }
            .pressable()
            .accessibilityLabel("Mark vehicle as sold")
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(colors: theme.headerGradient, startPoint: .leading, endPoint: .trailing)
                    )
                Text("Actions")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: theme.headerGradient, startPoint: .leading, endPoint: .trailing)
                    )
            }
        }
    }

    // MARK: - Helpers

    private func exportPDF() {
        pdfData = PDFExportService.generatePDF(for: vehicle, settings: settings)
        if pdfData != nil {
            showPDFShare = true
        } else {
            surfaceError("Unable to generate PDF report. Please try again.")
        }
    }

    private func surfaceError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
        haptic.error()
        SoundManager.playError()
    }

    // MARK: - Recall Loading

    private func loadRecalls() async {
        let trimmedMake = vehicle.make.trimmingCharacters(in: .whitespaces)
        let trimmedModel = vehicle.model.trimmingCharacters(in: .whitespaces)
        guard !trimmedMake.isEmpty, !trimmedModel.isEmpty, vehicle.year > 0 else { return }

        isLoadingRecalls = true
        recallError = nil

        do {
            let results = try await NHTSAService.shared.fetchRecalls(
                make: trimmedMake,
                model: trimmedModel,
                year: vehicle.year
            )
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                recalls = results
            }
            if !results.isEmpty {
                haptic.warning()
            }
        } catch {
            recallError = error.localizedDescription
        }

        isLoadingRecalls = false
    }

    // MARK: - Share Text Helpers

    private func shareTextForServiceRecord(_ record: ServiceRecord) -> String {
        let dateStr = record.date.formatted(.dateTime.month(.abbreviated).day().year())
        var text = "🔧 Service: \(record.displayServiceType) on \(dateStr)"
        if record.cost > 0 {
            text += " — \(settings.formatCost(record.cost))"
        }
        if record.mileage > 0 {
            text += " at \(settings.formatMileage(record.mileage))"
        }
        if !record.notes.isEmpty {
            text += "\n\(record.notes)"
        }
        text += "\n\n— Shared from WrenchLog"
        return text
    }

    private var vehicleSummaryShareText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        var text = "🚗 \(vehicle.displayName)\n"
        text += "Health: \(healthScore)%\n"
        text += "Total Services: \(vehicle.safeServiceRecords.count)\n"
        text += "Total Cost: \(settings.formatCost(totalOwnershipCost))\n"
        if let lastDate = lastServiceDate {
            text += "Last Service: \(dateFormatter.string(from: lastDate))\n"
        }
        if vehicle.currentMileage > 0 {
            text += "Mileage: \(settings.formatMileage(vehicle.currentMileage))\n"
        }
        text += "\n— Shared from WrenchLog"
        return text
    }

    private func handleMileageUpdate() {
        guard let m = Int(newMileage), m > 0 else { return }
        let validation = VehicleValidator.validateMileageUpdate(newMileage: m, currentMileage: vehicle.currentMileage)
        if validation.isValid {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                vehicle.currentMileage = m
                vehicle.lastUpdated = .now
            }
            haptic.mileageUpdate()
            SoundManager.playSaveSuccess()
            do {
                try DataManager.save(context)
            } catch {
                surfaceError(error.errorDescription ?? "Unable to save mileage update.")
            }
            Task {
                if let vehicles = try? context.fetch(FetchDescriptor<Vehicle>()) {
                    await ReminderManager.shared.scheduleReminders(for: vehicles)
                }
            }
        } else {
            mileageValidationError = validation.firstError
        }
    }

    private func handleDeleteRecord() {
        guard let record = recordToDelete else { return }
        let snapshot = DeletedServiceRecordSnapshot(
            serviceTypeRaw: record.serviceTypeRaw,
            categoryRaw: record.categoryRaw,
            date: record.date,
            mileage: record.mileage,
            cost: record.cost,
            notes: record.notes,
            photoFileNames: record.photoFileNames,
            deletedAt: .now
        )
        DeletionUndoManager.shared.storeDeletedService(snapshot)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { context.delete(record) }
        haptic.deleteWarning()
        SoundManager.playDelete()
        do {
            try DataManager.save(context)
        } catch {
            surfaceError(error.errorDescription ?? "Unable to delete the record. Please try again.")
            return
        }
        vehicle.lastUpdated = .now
        withAnimation { showUndoBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + DeletedServiceRecordSnapshot.undoWindowDuration) {
            withAnimation { showUndoBanner = false }
            if !DeletionUndoManager.shared.canUndoService {
                photoManager.deletePhotos(for: snapshot.photoFileNames)
            }
        }
    }

    // MARK: - Undo Banner

    private var undoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle.fill").font(.body).foregroundStyle(.white)
                .accessibilityHidden(true)
            Text("Service record deleted").font(.subheadline.weight(.medium)).foregroundStyle(.white)
            Spacer()
            Button { undoDeleteService() } label: {
                Text("Undo").font(.subheadline.weight(.bold)).foregroundStyle(.yellow)
            }
            .accessibilityLabel("Undo delete")
            .accessibilityHint("Restores the deleted service record")
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(Color.Neutral.shade800.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }

    private func undoDeleteService() {
        guard let snapshot = DeletionUndoManager.shared.reconstructService() else { return }
        let record = if let serviceType = ServiceType(rawValue: snapshot.serviceTypeRaw) {
            ServiceRecord(serviceType: serviceType, date: snapshot.date, mileage: snapshot.mileage, cost: snapshot.cost, notes: snapshot.notes)
        } else {
            ServiceRecord(customType: snapshot.serviceTypeRaw, category: ServiceCategory(rawValue: snapshot.categoryRaw) ?? .custom, date: snapshot.date, mileage: snapshot.mileage, cost: snapshot.cost, notes: snapshot.notes)
        }
        record.photoFileNames = snapshot.photoFileNames
        record.vehicle = vehicle
        context.insert(record)
        do {
            try DataManager.save(context)
            vehicle.lastUpdated = .now
            withAnimation { showUndoBanner = false }
            haptic.saveSuccess()
            SoundManager.playSaveSuccess()
        } catch {
            surfaceError(error.errorDescription ?? "Unable to restore the record.")
        }
    }

    private func filterChip(label: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                if let icon { Image(systemName: icon).font(.caption2) }
                Text(label).font(.caption2.weight(.medium))
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(isSelected ? AnyShapeStyle(theme.accent.opacity(0.15)) : AnyShapeStyle(.ultraThinMaterial), in: Capsule())
            .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
            .foregroundStyle(isSelected ? theme.accent : .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) filter\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon).font(.system(.caption2, weight: .semibold)).foregroundStyle(color)
            }
            Text(value).font(.system(.caption, design: .rounded, weight: .bold).monospacedDigit()).contentTransition(.numericText()).lineLimit(1).minimumScaleFactor(0.7)
            Text(title).font(.caption2.weight(.medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.12), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Service Record Row

struct ServiceRecordRow: View {
    let record: ServiceRecord
    @Environment(\.appTheme) private var theme
    private let settings = UserSettings.shared
    private let photoManager = ServicePhotoManager.shared

    var body: some View {
        HStack(spacing: 0) {
            // Color-coded left accent bar by category
            RoundedRectangle(cornerRadius: 2)
                .fill(record.color)
                .frame(width: 4)
                .padding(.vertical, 4)
                .padding(.trailing, 10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(record.color.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: record.icon)
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(record.color)
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.displayServiceType).font(.subheadline.weight(.semibold))
                        HStack(spacing: 8) {
                            Text(record.date, format: .dateTime.month(.abbreviated).day().year()).font(.caption).foregroundStyle(.secondary)
                            if record.mileage > 0 {
                                Text("· \(settings.formatMileage(record.mileage))").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                    if record.cost > 0 {
                        Text(settings.formatCost(record.cost))
                            .font(.system(.subheadline, design: .rounded, weight: .bold).monospacedDigit())
                            .foregroundStyle(theme.accent)
                    }
                }
                if !record.notes.isEmpty {
                    Text(record.notes).font(.caption).foregroundStyle(.tertiary).lineLimit(2).padding(.leading, 44)
                }
                if !record.photoFileNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(record.photoFileNames, id: \.self) { fileName in
                                if let img = photoManager.loadPhoto(named: fileName) {
                                    Image(uiImage: img).resizable().scaledToFill()
                                        .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .padding(.leading, 44)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.displayServiceType), \(record.date, format: .dateTime.month(.abbreviated).day().year()), cost \(UserSettings.shared.formatCost(record.cost))")
    }
}

// MARK: - Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context _: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = UIView()
        return vc
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
