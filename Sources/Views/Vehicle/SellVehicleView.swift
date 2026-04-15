import SwiftUI

struct SellVehicleView: View {
    @Bindable var vehicle: Vehicle
    @State private var soldDate = Date.now
    @State private var confirmSell = false
    @State private var didComplete = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme

    private let settings = UserSettings.shared

    var totalServiceCost: Double {
        vehicle.safeServiceRecords.reduce(0) { $0 + $1.cost }
    }

    var totalFuelCost: Double {
        vehicle.safeFuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    /// Ownership duration as a human-readable string
    private var ownershipDuration: String {
        let from = vehicle.purchaseDate ?? vehicle.dateAdded
        let components = Calendar.current.dateComponents([.year, .month], from: from, to: .now)
        let years = components.year ?? 0
        let months = components.month ?? 0
        if years > 0, months > 0 {
            return "\(years)y \(months)mo"
        } else if years > 0 {
            return "\(years) year\(years == 1 ? "" : "s")"
        } else {
            return "\(max(1, months)) month\(months <= 1 ? "" : "s")"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Vehicle Header (glass card)

                Section {
                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(theme.accent.opacity(0.12))
                                    .frame(width: 60, height: 60)
                                Image(systemName: "car.fill")
                                    .font(.title2)
                                    .foregroundStyle(theme.accent)
                            }
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(vehicle.displayName)
                                    .font(.headline)
                                Text("\(vehicle.year)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(settings.formatMileage(vehicle.currentMileage))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(vehicle.displayName), \(settings.formatMileage(vehicle.currentMileage))")
                }
                .staggeredAppear(index: 0)

                // MARK: - Sale Details

                Section("Sale Details") {
                    DatePicker("Date Sold", selection: $soldDate, in: ...Date.now, displayedComponents: .date)
                        .accessibilityLabel("Date sold")
                        .accessibilityIdentifier("sellVehicleDate")
                }
                .staggeredAppear(index: 1)

                // MARK: - Ownership Stats

                Section {
                    // Ownership duration stat
                    HStack {
                        Label("Owned For", systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                        Spacer()
                        Text(ownershipDuration)
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(theme.accent)
                    }
                    .statPop(index: 0)

                    HStack {
                        Label("Services Logged", systemImage: "wrench.and.screwdriver")
                            .font(.subheadline)
                        Spacer()
                        Text("\(vehicle.safeServiceRecords.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .statPop(index: 1)

                    HStack {
                        Label("Service Cost", systemImage: "dollarsign.circle")
                            .font(.subheadline)
                        Spacer()
                        Text(settings.formatCost(totalServiceCost))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .statPop(index: 2)

                    HStack {
                        Label("Fuel Cost", systemImage: "fuelpump")
                            .font(.subheadline)
                        Spacer()
                        Text(settings.formatCost(totalFuelCost))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .statPop(index: 3)

                    HStack {
                        Label("Total Ownership Cost", systemImage: "chart.bar.fill")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(settings.formatCost(totalServiceCost + totalFuelCost))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(theme.accent)
                    }
                    .statPop(index: 4)
                } header: {
                    Text("Ownership Summary")
                        .font(.system(.headline, design: .rounded))
                }
                .staggeredAppear(index: 2)

                // MARK: - Info Notice

                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.Status.info.shade500)
                            .font(.title3)
                            .accessibilityHidden(true)
                        Text("Your service history will be preserved. The vehicle will move to 'Sold Vehicles' and won't appear in your active garage.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Your service history will be preserved. The vehicle will move to sold vehicles.")
                }
                .staggeredAppear(index: 3)

                // MARK: - Sell Button

                Section {
                    Button(role: .destructive) {
                        HapticManager.shared.deleteWarning()
                        confirmSell = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Mark as Sold", systemImage: "tag.fill")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .pressable()
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .accessibilityLabel("Mark vehicle as sold")
                    .accessibilityHint("Moves the vehicle to sold vehicles list")
                }
                .staggeredAppear(index: 4)
            }
            .smoothSheetTransition()
            .navigationTitle("Sell Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("sellVehicleCancel")
                        .accessibilityLabel("Cancel selling vehicle")
                }
            }
            .alert("Mark Vehicle as Sold?", isPresented: $confirmSell) {
                Button("Sell", role: .destructive) {
                    vehicle.soldDate = soldDate
                    vehicle.isArchived = true
                    vehicle.lastUpdated = .now
                    DataManager.trySave(context)
                    HapticManager.shared.warning()
                    didComplete = true
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("'\(vehicle.displayName)' will be moved to sold vehicles. All history is preserved.")
            }
            .onChange(of: didComplete) { _, completed in
                if completed {
                    HapticManager.shared.success()
                }
            }
        }
    }
}
