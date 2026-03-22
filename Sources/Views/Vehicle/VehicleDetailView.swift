import SwiftUI

struct VehicleDetailView: View {
    @Bindable var vehicle: Vehicle
    @State private var showAddService = false
    @State private var showSettings = false
    private let settings = UserSettings.shared

    var sortedRecords: [ServiceRecord] {
        vehicle.serviceRecords.sorted { $0.date > $1.date }
    }

    var totalCost: Double {
        vehicle.serviceRecords.reduce(0) { $0 + $1.cost }
    }

    var body: some View {
        List {
            // Vehicle header
            Section {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vehicle.displayName)
                                .font(.title3.weight(.bold))
                            if !vehicle.licensePlate.isEmpty {
                                Text(vehicle.licensePlate)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(settings.formatMileage(vehicle.currentMileage))
                                .font(.subheadline.weight(.semibold))
                            Text("\(vehicle.serviceRecords.count) services")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Quick stats
                    HStack(spacing: 16) {
                        statCard(title: "Total Spent", value: settings.formatCost(totalCost), icon: "dollarsign.circle.fill", color: .wrenchAmber)
                        statCard(title: "Services", value: "\(vehicle.serviceRecords.count)", icon: "wrench.fill", color: .catEngine)
                    }
                }
            }

            // Service history
            Section("Service History") {
                if sortedRecords.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.title)
                                .foregroundStyle(.tertiary)
                            Text("No services logged yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                } else {
                    ForEach(sortedRecords) { record in
                        ServiceRecordRow(record: record)
                    }
                }
            }
        }
        .navigationTitle("Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddService = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.wrenchAmber)
                }
            }
        }
        .sheet(isPresented: $showAddService) {
            AddServiceView(vehicle: vehicle)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ServiceRecordRow: View {
    let record: ServiceRecord
    private let settings = UserSettings.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.icon)
                .font(.body)
                .foregroundStyle(record.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.displayServiceType)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    Text(record.date, format: .dateTime.month(.abbreviated).day().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if record.mileage > 0 {
                        Text("· \(settings.formatMileage(record.mileage))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if record.cost > 0 {
                Text(settings.formatCost(record.cost))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Color.wrenchAmber)
            }
        }
        .padding(.vertical, 2)
    }
}
