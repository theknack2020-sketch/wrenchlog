import SwiftUI
import SwiftData

struct FuelHistoryView: View {
    let vehicle: Vehicle
    @State private var showAddFuel = false
    @State private var logToDelete: FuelLog?
    @State private var showDeleteConfirm = false
    @State private var showUndoBanner = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @Environment(\.modelContext) private var context

    private let settings = UserSettings.shared

    var sortedLogs: [FuelLog] {
        vehicle.safeFuelLogs.sorted { $0.date > $1.date }
    }

    var totalFuelCost: Double {
        vehicle.safeFuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    var totalVolume: Double {
        vehicle.safeFuelLogs.reduce(0) { $0 + $1.volume }
    }

    var efficiencyResults: [FuelEfficiencyResult] {
        vehicle.safeFuelLogs.calculateEfficiency()
    }

    var averageEfficiency: Double? {
        let results = efficiencyResults
        guard !results.isEmpty else { return nil }
        let sum = results.reduce(0.0) { $0 + $1.efficiency(for: settings.efficiencyUnit) }
        return sum / Double(results.count)
    }

    var body: some View {
        fuelHistoryList
            .navigationTitle("Fuel History")
            .toolbar { fuelToolbar }
            .sheet(isPresented: $showAddFuel) {
                AddFuelLogView(vehicle: vehicle)
            }
            .alert("Delete Fuel Log?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { performDelete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let log = logToDelete {
                    Text("Delete fuel log from \(log.date, format: .dateTime.month(.abbreviated).day())?")
                }
            }
            .alert("Something Went Wrong", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .overlay(alignment: .bottom) {
                if showUndoBanner {
                    undoFuelBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 16)
                        .padding(.horizontal, 16)
                }
            }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var fuelToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                HapticManager.shared.buttonTap()
                showAddFuel = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.wrenchAmber)
            }
            .accessibilityLabel("Add fuel log")
        }
    }

    // MARK: - List Content

    private var fuelHistoryList: some View {
        List {
            summaryStatsSection
            fuelEntriesSection
        }
    }

    private var summaryStatsSection: some View {
        Section {
            HStack(spacing: 8) {
                statCard(title: "Total Fuel", value: settings.formatCost(totalFuelCost), color: .catFuel)
                    .statPop(index: 0)
                statCard(title: "Fill-Ups", value: "\(sortedLogs.count)", color: .catEngine)
                    .statPop(index: 1)
                if let avg = averageEfficiency {
                    statCard(title: "Avg \(settings.efficiencyUnit.label)", value: String(format: "%.1f", avg), color: .catTires)
                        .statPop(index: 2)
                }
            }
        }
    }

    @ViewBuilder
    private var fuelEntriesSection: some View {
        if sortedLogs.isEmpty {
            fuelEmptySection
        } else {
            fuelLogListSection
        }
    }

    private var fuelEmptySection: some View {
        Section("Fuel History") {
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    ZStack {
                        Circle().fill(Color.catFuel.opacity(0.1)).frame(width: 72, height: 72)
                        Image(systemName: "fuelpump.circle.fill").font(.system(size: 32)).foregroundStyle(Color.catFuel.opacity(0.4))
                    }
                    Text("No Fuel Logs").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                    Text("Track your fill-ups to see efficiency trends,\nspending patterns, and cost-per-mile.")
                        .font(.caption).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                    Button { HapticManager.shared.buttonTap(); showAddFuel = true } label: {
                        Label("Log First Fill-Up", systemImage: "plus.circle.fill").font(.caption.weight(.medium)).foregroundStyle(Color.wrenchAmber)
                    }
                }
                .padding(.vertical, 24)
                Spacer()
            }
        }
    }

    private var fuelLogListSection: some View {
        Section("Fuel History") {
            ForEach(Array(sortedLogs.enumerated()), id: \.element.id) { index, log in
                NavigationLink { EditFuelLogView(fuelLog: log) } label: {
                    FuelLogRow(log: log, efficiency: efficiencyForLog(log))
                }
                .simultaneousGesture(TapGesture().onEnded { HapticManager.shared.light() })
                .staggeredAppear(index: index)
            }
            .onDelete { indexSet in
                HapticManager.shared.deleteWarning()
                logToDelete = indexSet.first.map { sortedLogs[$0] }
                showDeleteConfirm = true
            }
        }
    }

    // MARK: - Delete Action

    private func performDelete() {
        guard let log = logToDelete else { return }
        let snapshot = DeletedFuelLogSnapshot(
            date: log.date, mileage: log.mileage, volume: log.volume,
            totalCost: log.totalCost, pricePerUnit: log.pricePerUnit,
            fuelTypeRaw: log.fuelTypeRaw, station: log.station,
            isFullTank: log.isFullTank, notes: log.notes,
            volumeUnitRaw: log.volumeUnitRaw, deletedAt: .now
        )
        DeletionUndoManager.shared.storeDeletedFuelLog(snapshot)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { context.delete(log) }
        do {
            try DataManager.save(context)
            HapticManager.shared.deleteWarning()
            SoundManager.playDelete()
            withAnimation { showUndoBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + DeletedFuelLogSnapshot.undoWindowDuration) {
                withAnimation { showUndoBanner = false }
            }
        } catch {
            errorMessage = error.errorDescription ?? "Unable to delete the fuel log. Please try again."
            showErrorAlert = true
            HapticManager.shared.error()
            SoundManager.playError()
        }
    }

    private func efficiencyForLog(_ log: FuelLog) -> FuelEfficiencyResult? {
        efficiencyResults.first { $0.date == log.date && $0.mileage == log.mileage }
    }

    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: color.opacity(0.12), radius: 5, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Undo Banner

    private var undoFuelBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.body)
                .foregroundStyle(.white)
            Text("Fuel log deleted")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Button {
                undoDeleteFuelLog()
            } label: {
                Text("Undo")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.9))
        .background(Color.wrenchCharcoal.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func undoDeleteFuelLog() {
        guard let snapshot = DeletionUndoManager.shared.reconstructFuelLog() else { return }

        let log = FuelLog(
            date: snapshot.date,
            mileage: snapshot.mileage,
            volume: snapshot.volume,
            totalCost: snapshot.totalCost,
            pricePerUnit: snapshot.pricePerUnit,
            fuelType: FuelType(rawValue: snapshot.fuelTypeRaw) ?? .regular,
            station: snapshot.station,
            isFullTank: snapshot.isFullTank,
            notes: snapshot.notes,
            volumeUnit: VolumeUnit(rawValue: snapshot.volumeUnitRaw) ?? .gallons
        )
        log.vehicle = vehicle

        context.insert(log)
        do {
            try DataManager.save(context)
            withAnimation { showUndoBanner = false }
            HapticManager.shared.saveSuccess()
            SoundManager.playSaveSuccess()
        } catch {
            errorMessage = error.errorDescription ?? "Unable to restore the fuel log."
            showErrorAlert = true
            HapticManager.shared.error()
        }
    }
}

// MARK: - Fuel Log Row

struct FuelLogRow: View {
    let log: FuelLog
    let efficiency: FuelEfficiencyResult?
    private let settings = UserSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: log.fuelType.icon)
                    .font(.body)
                    .foregroundStyle(log.fuelType.color)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(log.fuelType.rawValue)
                            .font(.subheadline.weight(.medium))
                        if !log.station.isEmpty {
                            Text("· \(log.station)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(log.date, format: .dateTime.month(.abbreviated).day().year())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if log.mileage > 0 {
                            Text("· \(settings.formatMileage(log.mileage))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    if log.totalCost > 0 {
                        Text(settings.formatCost(log.totalCost))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Color.wrenchAmber)
                    }
                    Text(settings.formatVolume(log.volume))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            // Efficiency badge
            if let eff = efficiency {
                HStack(spacing: 6) {
                    Image(systemName: "gauge.medium")
                        .font(.caption2)
                        .foregroundStyle(Color.catFuel)
                    Text(settings.formatEfficiency(eff.efficiency(for: settings.efficiencyUnit)))
                        .font(.caption2.weight(.medium).monospacedDigit())
                        .foregroundStyle(Color.catFuel)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(settings.formatCostPerDistance(eff.costPerDistance(for: settings.distanceUnit)))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 40)
            }

            if !log.isFullTank {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("Partial fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                .padding(.leading, 40)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(log.fuelType.rawValue) fill-up\(log.station.isEmpty ? "" : " at \(log.station)"), \(log.date, format: .dateTime.month(.abbreviated).day().year()), cost \(UserSettings.shared.formatCost(log.totalCost))")
    }
}
