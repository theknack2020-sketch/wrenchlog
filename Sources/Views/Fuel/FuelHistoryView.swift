import SwiftUI
import SwiftData

struct FuelHistoryView: View {
    let vehicle: Vehicle
    @State private var showAddFuel = false
    @State private var logToDelete: FuelLog?
    @State private var showDeleteConfirm = false
    @State private var showUndoBanner = false
    @Environment(\.modelContext) private var context

    private let settings = UserSettings.shared

    var sortedLogs: [FuelLog] {
        vehicle.fuelLogs.sorted { $0.date > $1.date }
    }

    var totalFuelCost: Double {
        vehicle.fuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    var totalVolume: Double {
        vehicle.fuelLogs.reduce(0) { $0 + $1.volume }
    }

    var efficiencyResults: [FuelEfficiencyResult] {
        vehicle.fuelLogs.calculateEfficiency()
    }

    var averageEfficiency: Double? {
        let results = efficiencyResults
        guard !results.isEmpty else { return nil }
        let sum = results.reduce(0.0) { $0 + $1.efficiency(for: settings.efficiencyUnit) }
        return sum / Double(results.count)
    }

    var body: some View {
        List {
            // Summary stats
            Section {
                HStack(spacing: 8) {
                    statCard(
                        title: "Total Fuel",
                        value: settings.formatCost(totalFuelCost),
                        color: .catFuel
                    )
                    statCard(
                        title: "Fill-Ups",
                        value: "\(sortedLogs.count)",
                        color: .catEngine
                    )
                    if let avg = averageEfficiency {
                        statCard(
                            title: "Avg \(settings.efficiencyUnit.label)",
                            value: String(format: "%.1f", avg),
                            color: .catTires
                        )
                    }
                }
            }

            // Fuel log entries
            if sortedLogs.isEmpty {
                Section("Fuel History") {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "fuelpump")
                                .font(.title)
                                .foregroundStyle(.tertiary)
                            Text("No fuel logs yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Tap + to log your first fill-up.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                }
            } else {
                Section("Fuel History") {
                    ForEach(sortedLogs) { log in
                        NavigationLink {
                            EditFuelLogView(fuelLog: log)
                        } label: {
                            FuelLogRow(
                                log: log,
                                efficiency: efficiencyForLog(log)
                            )
                        }
                    }
                    .onDelete { indexSet in
                        logToDelete = indexSet.first.map { sortedLogs[$0] }
                        showDeleteConfirm = true
                    }
                }
            }
        }
        .navigationTitle("Fuel History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddFuel = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.wrenchAmber)
                }
            }
        }
        .sheet(isPresented: $showAddFuel) {
            AddFuelLogView(vehicle: vehicle)
        }
        .alert("Delete Fuel Log?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let log = logToDelete {
                    // Store undo snapshot
                    let snapshot = DeletedFuelLogSnapshot(
                        date: log.date,
                        mileage: log.mileage,
                        volume: log.volume,
                        totalCost: log.totalCost,
                        pricePerUnit: log.pricePerUnit,
                        fuelTypeRaw: log.fuelTypeRaw,
                        station: log.station,
                        isFullTank: log.isFullTank,
                        notes: log.notes,
                        volumeUnitRaw: log.volumeUnitRaw,
                        deletedAt: .now
                    )
                    DeletionUndoManager.shared.storeDeletedFuelLog(snapshot)

                    context.delete(log)
                    DataManager.trySave(context)

                    withAnimation { showUndoBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + DeletedFuelLogSnapshot.undoWindowDuration) {
                        withAnimation { showUndoBanner = false }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let log = logToDelete {
                Text("Delete fuel log from \(log.date, format: .dateTime.month(.abbreviated).day())?")
            }
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
        DataManager.trySave(context)

        withAnimation { showUndoBanner = false }
        HapticManager.shared.success()
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
    }
}
