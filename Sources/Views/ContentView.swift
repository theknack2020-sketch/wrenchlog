import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(filter: #Predicate<Vehicle> { !$0.isArchived },
           sort: \Vehicle.dateAdded, order: .reverse)
    private var vehicles: [Vehicle]

    @State private var showAddVehicle = false
    @State private var selectedVehicle: Vehicle?

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
                    Button { showAddVehicle = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.wrenchAmber)
                    }
                }
            }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView()
            }
            .navigationDestination(item: $selectedVehicle) { vehicle in
                VehicleDetailView(vehicle: vehicle)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "car.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.wrenchAmber)

            Text("No Vehicles Yet")
                .font(.title2.weight(.bold))

            Text("Add your first vehicle to start\ntracking maintenance.")
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
                for index in indexSet {
                    let vehicle = vehicles[index]
                    vehicle.isArchived = true
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

    var body: some View {
        HStack(spacing: 14) {
            // Vehicle icon/photo
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
                } else {
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .foregroundStyle(Color.wrenchAmber)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.displayName)
                    .font(.subheadline.weight(.semibold))

                Text(settings.formatMileage(vehicle.currentMileage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Service count badge
            let count = vehicle.serviceRecords.count
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.wrenchAmber.opacity(0.15), in: Capsule())
                    .foregroundStyle(Color.wrenchAmber)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
