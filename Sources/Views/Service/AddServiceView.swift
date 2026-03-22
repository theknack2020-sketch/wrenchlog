import SwiftUI
import SwiftData
import PhotosUI

struct AddServiceView: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ServiceType = .oilChange
    @State private var customTypeName = ""
    @State private var isCustom = false
    @State private var date = Date.now
    @State private var mileage = ""
    @State private var cost = ""
    @State private var notes = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoDataItems: [Data] = []
    @State private var showProPrompt = false

    private let store = StoreManager.shared
    private let photoManager = ServicePhotoManager.shared

    var body: some View {
        NavigationStack {
            Form {
                // Service type
                Section("Service Type") {
                    if store.isPro {
                        Toggle("Custom Service", isOn: $isCustom)
                    }

                    if isCustom && store.isPro {
                        TextField("Service name", text: $customTypeName)
                    } else {
                        Picker("Type", selection: $selectedType) {
                            ForEach(ServiceCategory.allCases.filter { $0 != .custom }) { category in
                                Section(category.rawValue) {
                                    ForEach(ServiceType.types(for: category)) { type in
                                        Label(type.rawValue, systemImage: type.icon)
                                            .tag(type)
                                    }
                                }
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }

                // Details
                Section("Details") {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)

                    HStack {
                        Text("Mileage")
                        Spacer()
                        TextField(UserSettings.shared.distanceUnit.label, text: $mileage)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    HStack {
                        Text("Cost")
                        Spacer()
                        HStack(spacing: 2) {
                            Text(UserSettings.shared.currency.symbol)
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $cost)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                }

                // Notes
                Section("Notes (optional)") {
                    TextField("Any additional details...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Photos (Pro feature)
                Section("Receipt Photos") {
                    if store.isPro {
                        PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                            Label("Add Photos", systemImage: "camera.fill")
                                .foregroundStyle(Color.wrenchAmber)
                        }

                        if !photoDataItems.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(photoDataItems.indices, id: \.self) { index in
                                        if let img = UIImage(data: photoDataItems[index]) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(alignment: .topTrailing) {
                                                    Button {
                                                        photoDataItems.remove(at: index)
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.caption)
                                                            .foregroundStyle(.white, .red)
                                                    }
                                                    .offset(x: 4, y: -4)
                                                }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Button {
                            showProPrompt = true
                        } label: {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.secondary)
                                Text("Pro feature — attach receipt photos")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Reminder hint
                if !isCustom && selectedType.defaultMileageInterval > 0 {
                    Section {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(Color.wrenchAmber)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reminder will be set")
                                    .font(.subheadline.weight(.medium))
                                Text("Next: \(selectedType.defaultMileageInterval.formatted()) \(UserSettings.shared.distanceUnit.label) or \(selectedType.defaultMonthInterval) months")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRecord() }
                        .fontWeight(.semibold)
                        .disabled(isCustom && customTypeName.isEmpty)
                }
            }
            .onAppear {
                mileage = vehicle.currentMileage > 0 ? "\(vehicle.currentMileage)" : ""
            }
            .onChange(of: selectedPhotos) { _, items in
                Task {
                    photoDataItems = []
                    for item in items {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            photoDataItems.append(data)
                        }
                    }
                }
            }
            .sheet(isPresented: $showProPrompt) {
                ProUpgradeView()
            }
        }
    }

    private func saveRecord() {
        let record: ServiceRecord
        if isCustom {
            record = ServiceRecord(
                customType: customTypeName.trimmingCharacters(in: .whitespaces),
                date: date,
                mileage: Int(mileage) ?? 0,
                cost: Double(cost) ?? 0,
                notes: notes
            )
        } else {
            record = ServiceRecord(
                serviceType: selectedType,
                date: date,
                mileage: Int(mileage) ?? 0,
                cost: Double(cost) ?? 0,
                notes: notes
            )
        }

        // Save photos
        if store.isPro {
            for photoData in photoDataItems {
                let fileName = photoManager.savePhoto(photoData, for: record.id)
                record.photoFileNames.append(fileName)
            }
        }

        record.vehicle = vehicle

        // Update vehicle mileage if higher
        if let m = Int(mileage), m > vehicle.currentMileage {
            vehicle.currentMileage = m
        }

        context.insert(record)
        try? context.save()

        // Reschedule reminders
        Task {
            if let vehicles = try? context.fetch(FetchDescriptor<Vehicle>()) {
                await ReminderManager.shared.scheduleReminders(for: vehicles)
            }
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
