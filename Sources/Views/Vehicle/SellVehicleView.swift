import SwiftUI

struct SellVehicleView: View {
    @Bindable var vehicle: Vehicle
    @State private var soldDate = Date.now
    @State private var confirmSell = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let settings = UserSettings.shared

    var totalServiceCost: Double {
        vehicle.safeServiceRecords.reduce(0) { $0 + $1.cost }
    }

    var totalFuelCost: Double {
        vehicle.safeFuelLogs.reduce(0) { $0 + $1.totalCost }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.wrenchAmber.opacity(0.1))
                                .frame(width: 56, height: 56)
                            Image(systemName: "car.fill")
                                .font(.title2)
                                .foregroundStyle(Color.wrenchAmber)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vehicle.displayName)
                                .font(.headline)
                            Text(settings.formatMileage(vehicle.currentMileage))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Sale Details") {
                    DatePicker("Date Sold", selection: $soldDate, in: ...Date.now, displayedComponents: .date)
                }

                Section {
                    HStack {
                        Text("Services Logged")
                        Spacer()
                        Text("\(vehicle.safeServiceRecords.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Service Cost")
                        Spacer()
                        Text(settings.formatCost(totalServiceCost))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Fuel Cost")
                        Spacer()
                        Text(settings.formatCost(totalFuelCost))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Total Ownership Cost")
                        Spacer()
                        Text(settings.formatCost(totalServiceCost + totalFuelCost))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Color.wrenchAmber)
                    }
                    HStack {
                        Text("Owned Since")
                        Spacer()
                        Text(vehicle.dateAdded, format: .dateTime.month(.abbreviated).year())
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Ownership Summary")
                        .font(.system(.headline, design: .rounded))
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Your service history will be preserved. The vehicle will move to 'Sold Vehicles' and won't appear in your active garage.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
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
                    .accessibilityLabel("Mark vehicle as sold")
                    .accessibilityHint("Moves the vehicle to sold vehicles list")
                }
            }
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
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("'\(vehicle.displayName)' will be moved to sold vehicles. All history is preserved.")
            }
        }
    }
}
