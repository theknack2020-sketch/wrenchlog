import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(filter: #Predicate<Vehicle> { !$0.isArchived },
           sort: \Vehicle.dateAdded, order: .reverse)
    private var vehicles: [Vehicle]

    @State private var showAddVehicle = false
    @State private var showProPrompt = false
    @State private var selectedVehicle: Vehicle?
    @State private var vehicleToDelete: Vehicle?
    @State private var showDeleteConfirm = false
    @Environment(\.modelContext) private var context

    private let store = StoreManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if vehicles.isEmpty {
                    emptyState
                } else {
                    vehicleList
                }
            }
            .navigationTitle("WrenchLog")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if !store.isPro && vehicles.count >= 1 {
                            showProPrompt = true
                        } else {
                            showAddVehicle = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.wrenchAmber)
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
            .alert("Delete Vehicle?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let vehicle = vehicleToDelete {
                        vehicle.isArchived = true
                        do {
                            try context.save()
                        } catch {
                            print("[WrenchLog] Failed to archive vehicle: \(error)")
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let v = vehicleToDelete {
                    Text("'\(v.displayName)' and all its service records will be removed.")
                }
            }
            .onAppear {
                Task {
                    await ReminderManager.shared.scheduleReminders(for: vehicles)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.wrenchAmber)
                .accessibilityHidden(true)

            Text("Add Your First Vehicle")
                .font(.title2.weight(.bold))

            Text("Track maintenance, set reminders,\nand keep your car healthy.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddVehicle = true
            } label: {
                Label("Add Vehicle", systemImage: "plus")
                    .font(.headline)
                    .frame(width: 200, height: 50)
                    .foregroundStyle(.white)
                    .background(Color.wrenchAmber, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var vehicleList: some View {
        List {
            ForEach(vehicles) { vehicle in
                VehicleRow(vehicle: vehicle)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedVehicle = vehicle }
            }
            .onDelete { indexSet in
                if let index = indexSet.first {
                    vehicleToDelete = vehicles[index]
                    showDeleteConfirm = true
                }
            }

            // Pro upsell
            if !store.isPro && vehicles.count >= 1 {
                Section {
                    Button { showProPrompt = true } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(Color.wrenchAmber)
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
    }
}

struct VehicleRow: View {
    let vehicle: Vehicle
    private let settings = UserSettings.shared

    var overdueCount: Int {
        let calendar = Calendar.current
        var count = 0
        for serviceType in ServiceType.allCases {
            guard serviceType.defaultMonthInterval > 0 else { continue }
            if let last = vehicle.serviceRecords
                .filter({ $0.serviceTypeRaw == serviceType.rawValue })
                .sorted(by: { $0.date > $1.date }).first {
                let nextDue = calendar.date(byAdding: .month, value: serviceType.defaultMonthInterval, to: last.date) ?? Date()
                if nextDue < Date() { count += 1 }
            }
        }
        return count
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wrenchAmber.opacity(0.15))
                    .frame(width: 56, height: 56)

                if let data = vehicle.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("\(vehicle.displayName) photo")
                } else {
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .foregroundStyle(Color.wrenchAmber)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.displayName)
                    .font(.subheadline.weight(.semibold))

                HStack(spacing: 6) {
                    Text(settings.formatMileage(vehicle.currentMileage))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if overdueCount > 0 {
                        Text("\(overdueCount) overdue")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.wrenchRed.opacity(0.15), in: Capsule())
                            .foregroundStyle(.red)
                            .accessibilityLabel("\(overdueCount) overdue services")
                    }
                }
            }

            Spacer()

            let count = vehicle.serviceRecords.count
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.wrenchAmber.opacity(0.15), in: Capsule())
                    .foregroundStyle(Color.wrenchAmber)
                    .accessibilityLabel("\(count) services logged")
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
