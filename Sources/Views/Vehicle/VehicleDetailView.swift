import SwiftUI
import SwiftData

struct VehicleDetailView: View {
    @Bindable var vehicle: Vehicle
    @State private var showAddService = false
    @State private var showEditVehicle = false
    @State private var showEditMileage = false
    @State private var showCostAnalytics = false
    @State private var showPDFShare = false
    @State private var showProPrompt = false
    @State private var newMileage = ""
    @State private var pdfData: Data?
    @Environment(\.modelContext) private var context
    private let settings = UserSettings.shared
    private let store = StoreManager.shared
    private let photoManager = ServicePhotoManager.shared

    var sortedRecords: [ServiceRecord] {
        vehicle.serviceRecords.sorted { $0.date > $1.date }
    }

    var totalCost: Double {
        vehicle.serviceRecords.reduce(0) { $0 + $1.cost }
    }

    var upcomingReminders: [(type: String, dueText: String, isOverdue: Bool)] {
        var reminders: [(String, String, Bool)] = []
        let calendar = Calendar.current

        for serviceType in ServiceType.allCases {
            guard serviceType.defaultMonthInterval > 0 else { continue }

            let lastRecord = vehicle.serviceRecords
                .filter { $0.serviceTypeRaw == serviceType.rawValue }
                .sorted { $0.date > $1.date }
                .first

            if let last = lastRecord {
                let nextDue = calendar.date(byAdding: .month, value: serviceType.defaultMonthInterval, to: last.date) ?? Date()
                let isOverdue = nextDue < Date()
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                let dueText = isOverdue ? "Overdue" : formatter.localizedString(for: nextDue, relativeTo: Date())
                reminders.append((serviceType.rawValue, dueText, isOverdue))
            }
        }
        return reminders.sorted { $0.2 && !$1.2 } // overdue first
    }

    var body: some View {
        List {
            // Vehicle header
            Section {
                VStack(spacing: 12) {
                    HStack {
                        if let data = vehicle.photoData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(vehicle.displayName)
                                .font(.title3.weight(.bold))
                            HStack(spacing: 8) {
                                if !vehicle.licensePlate.isEmpty {
                                    Text(vehicle.licensePlate)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(settings.formatMileage(vehicle.currentMileage))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button { showEditVehicle = true } label: {
                            Image(systemName: "pencil.circle")
                                .font(.title3)
                                .foregroundStyle(Color.wrenchAmber)
                        }
                    }

                    // Quick stats
                    HStack(spacing: 12) {
                        statCard(title: "Total Spent", value: settings.formatCost(totalCost), icon: "dollarsign.circle.fill", color: .wrenchAmber)
                        statCard(title: "Services", value: "\(vehicle.serviceRecords.count)", icon: "wrench.fill", color: .catEngine)

                        Button { showEditMileage = true } label: {
                            statCard(title: "Update", value: settings.formatMileage(vehicle.currentMileage), icon: "gauge.open.with.needle.33percent", color: .catTires)
                        }
                    }
                }
            }

            // Upcoming reminders
            if !upcomingReminders.isEmpty {
                Section("Upcoming Service") {
                    ForEach(upcomingReminders.prefix(5), id: \.type) { reminder in
                        HStack {
                            Circle()
                                .fill(reminder.isOverdue ? Color.wrenchRed : Color.wrenchGreen)
                                .frame(width: 8, height: 8)
                            Text(reminder.type)
                                .font(.subheadline)
                            Spacer()
                            Text(reminder.dueText)
                                .font(.caption)
                                .foregroundStyle(reminder.isOverdue ? .red : .secondary)
                        }
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
                    .onDelete { indexSet in
                        for index in indexSet {
                            let record = sortedRecords[index]
                            photoManager.deletePhotos(for: record.photoFileNames)
                            context.delete(record)
                        }
                        try? context.save()
                    }
                }
            }

            // Actions
            Section {
                // Cost analytics (Pro)
                Button {
                    if store.isPro {
                        showCostAnalytics = true
                    } else {
                        showProPrompt = true
                    }
                } label: {
                    HStack {
                        Label("Cost Analytics", systemImage: "chart.bar.fill")
                        if !store.isPro {
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(Color.wrenchAmber)
                        }
                    }
                    .foregroundStyle(Color.wrenchAmber)
                }

                // PDF export (Pro)
                Button {
                    if store.isPro {
                        exportPDF()
                    } else {
                        showProPrompt = true
                    }
                } label: {
                    HStack {
                        Label("Export PDF Report", systemImage: "doc.text.fill")
                        if !store.isPro {
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(Color.wrenchAmber)
                        }
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
        .sheet(isPresented: $showEditVehicle) {
            EditVehicleView(vehicle: vehicle)
        }
        .sheet(isPresented: $showProPrompt) {
            ProUpgradeView()
        }
        .sheet(isPresented: $showPDFShare) {
            if let data = pdfData {
                ShareSheetView(items: [data])
            }
        }
        .navigationDestination(isPresented: $showCostAnalytics) {
            CostAnalyticsView(vehicle: vehicle)
        }
        .alert("Update Mileage", isPresented: $showEditMileage) {
            TextField(settings.distanceUnit.label, text: $newMileage)
                .keyboardType(.numberPad)
            Button("Update") {
                if let m = Int(newMileage), m > 0 {
                    vehicle.currentMileage = m
                    Task {
                        if let vehicles = try? context.fetch(FetchDescriptor<Vehicle>()) {
                            await ReminderManager.shared.scheduleReminders(for: vehicles)
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Current: \(settings.formatMileage(vehicle.currentMileage))")
        }
    }

    private func exportPDF() {
        pdfData = PDFExportService.generatePDF(for: vehicle, settings: settings)
        if pdfData != nil {
            showPDFShare = true
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
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
}

// MARK: - Service Record Row with Photos

struct ServiceRecordRow: View {
    let record: ServiceRecord
    private let settings = UserSettings.shared
    private let photoManager = ServicePhotoManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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

            // Notes
            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .padding(.leading, 40)
            }

            // Photo thumbnails
            if !record.photoFileNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(record.photoFileNames, id: \.self) { fileName in
                            if let img = photoManager.loadPhoto(named: fileName) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
                .padding(.leading, 40)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Share Sheet (iPad safe)

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // iPad requires popover
        vc.popoverPresentationController?.sourceView = UIView()
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
