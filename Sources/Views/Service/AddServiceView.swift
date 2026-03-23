import SwiftUI
import SwiftData
import PhotosUI
import StoreKit

struct AddServiceView: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.appTheme) private var theme

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
    @State private var showCelebration = false
    @State private var showTypePicker = false

    // Validation & error state
    @State private var validationError: String?
    @State private var serviceTypeError: String?
    @State private var mileageFieldError: String?
    @State private var costFieldError: String?
    @State private var saveError: String?
    @State private var photoWarnings: [String] = []
    @State private var isSaving = false

    private let store = StoreManager.shared
    private let photoManager = ServicePhotoManager.shared
    private let haptic = HapticManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                // MARK: - Service Type (Grouped by Category)
                Section {
                    if store.isPro {
                        Toggle("Custom Service", isOn: $isCustom)
                            .accessibilityHint("Enable to enter a custom service type")
                    }

                    if isCustom && store.isPro {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Service name", text: $customTypeName)
                                .accessibilityLabel("Custom service name")
                                .onChange(of: customTypeName) { _, _ in serviceTypeError = nil; validationError = nil }
                            if let err = serviceTypeError {
                                Text(err)
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                    } else {
                        // Service type button with category preview
                        Button {
                            showTypePicker = true
                        } label: {
                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(selectedType.color)
                                    .frame(width: 4, height: 36)
                                    .padding(.trailing, 10)
                                Image(systemName: selectedType.uniqueIcon)
                                    .foregroundStyle(selectedType.color)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedType.rawValue)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(selectedType.category.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.leading, 8)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel("Service type: \(selectedType.rawValue)")
                        .accessibilityHint("Double tap to choose a different service type")
                    }
                } header: {
                    Text("Service Type")
                }

                // MARK: - Details
                Section("Details") {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                        .accessibilityLabel("Service date")
                        .accessibilityHint("When the service was performed")

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Mileage")
                            Spacer()
                            TextField(UserSettings.shared.distanceUnit.label, text: $mileage)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                                .accessibilityLabel("Odometer reading at service")
                                .accessibilityHint("Enter mileage when service was done")
                                .onChange(of: mileage) { _, _ in mileageFieldError = nil; validationError = nil }
                        }
                        if let err = mileageFieldError {
                            Text(err)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
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
                                    .accessibilityLabel("Service cost in \(UserSettings.shared.currency.symbol)")
                                    .onChange(of: cost) { _, _ in costFieldError = nil; validationError = nil }
                            }
                        }
                        if let err = costFieldError {
                            Text(err)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }

                // MARK: - Notes
                Section("Notes (optional)") {
                    TextField("Any additional details...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Service notes")
                }

                // MARK: - Photos (Pro feature)
                Section {
                    if store.isPro {
                        PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                            Label("Add Photos", systemImage: "camera.fill")
                                .foregroundStyle(theme.accent)
                        }
                        .accessibilityLabel("Add receipt photos")
                        .accessibilityHint("Attach up to 5 photos")

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
                                                    .accessibilityLabel("Remove photo \(index + 1)")
                                                }
                                                .accessibilityLabel("Receipt photo \(index + 1)")
                                        }
                                    }
                                }
                            }
                        }

                        // Photo save warnings
                        if !photoWarnings.isEmpty {
                            ForEach(photoWarnings, id: \.self) { warning in
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                    Text(warning)
                                        .font(.caption)
                                        .foregroundStyle(.orange)
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
                                    .accessibilityHidden(true)
                                Text("Pro feature — attach receipt photos")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityLabel("Receipt photos, Pro feature")
                        .accessibilityHint("Double tap to view Pro upgrade options")
                    }
                } header: {
                    Text("Receipt Photos")
                }

                // MARK: - Reminder hint
                if !isCustom && selectedType.defaultMileageInterval > 0 {
                    Section {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(theme.accent)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reminder will be set")
                                    .font(.subheadline.weight(.medium))
                                Text("Next: \(selectedType.defaultMileageInterval.formatted()) \(UserSettings.shared.distanceUnit.label) or \(selectedType.defaultMonthInterval) months")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                } // Form

                CelebrationOverlay(isShowing: $showCelebration)
            } // ZStack
            .navigationTitle("Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel logging service")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRecord() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.wrenchAmber)
                        .disabled((isCustom && customTypeName.trimmingCharacters(in: .whitespaces).isEmpty) || isSaving)
                        .accessibilityLabel("Save service record")
                        .accessibilityHint("Logs this service to your vehicle history")
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
            .sheet(isPresented: $showTypePicker) {
                ServiceTypePickerView(selectedType: $selectedType)
            }
            .alert("Save Failed", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil; isSaving = false }
            } message: {
                Text(saveError ?? "An unexpected error occurred.")
            }
        }
    }

    private func saveRecord() {
        // Clear previous field errors
        serviceTypeError = nil
        mileageFieldError = nil
        costFieldError = nil
        validationError = nil

        var hasError = false

        // Validate custom type name
        if isCustom && customTypeName.trimmingCharacters(in: .whitespaces).isEmpty {
            serviceTypeError = "Custom service name is required."
            hasError = true
        }

        // Validate mileage
        if let m = Int(mileage), m < 0 {
            mileageFieldError = "Mileage cannot be negative."
            hasError = true
        }

        // Validate cost
        if let c = Double(cost), c < 0 {
            costFieldError = "Cost cannot be negative."
            hasError = true
        }

        guard !hasError else {
            haptic.error()
            return
        }

        isSaving = true

        let record: ServiceRecord
        if isCustom {
            record = ServiceRecord(
                customType: customTypeName.trimmingCharacters(in: .whitespaces),
                date: date,
                mileage: max(0, Int(mileage) ?? 0),
                cost: max(0, Double(cost) ?? 0),
                notes: notes
            )
        } else {
            record = ServiceRecord(
                serviceType: selectedType,
                date: date,
                mileage: max(0, Int(mileage) ?? 0),
                cost: max(0, Double(cost) ?? 0),
                notes: notes
            )
        }

        // Save photos with error handling
        if store.isPro {
            photoWarnings = []
            for photoData in photoDataItems {
                switch photoManager.savePhoto(photoData, for: record.id) {
                case .success(let fileName):
                    record.photoFileNames.append(fileName)
                case .failure(let reason):
                    photoWarnings.append(reason)
                }
            }
        }

        record.vehicle = vehicle

        if let m = Int(mileage), m > vehicle.currentMileage {
            vehicle.currentMileage = m
        }
        vehicle.lastUpdated = .now

        context.insert(record)

        do {
            try DataManager.save(context)
        } catch {
            saveError = error.errorDescription
            haptic.error()
            SoundManager.playError()
            return
        }

        Task {
            if let vehicles = try? context.fetch(FetchDescriptor<Vehicle>()) {
                await ReminderManager.shared.scheduleReminders(for: vehicles)
            }
        }

        let totalServices = vehicle.serviceRecords.count
        if totalServices > 0 && totalServices % 10 == 0 {
            haptic.celebrate()
            SoundManager.playCelebration()
            showCelebration = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        } else {
            haptic.success()
            SoundManager.playSaveSuccess()
            dismiss()
        }

        let allServiceCount = (try? context.fetch(FetchDescriptor<ServiceRecord>()))?.count ?? 0
        if allServiceCount == 5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                requestReview()
            }
        }
    }
}

// MARK: - Grouped Service Type Picker

struct ServiceTypePickerView: View {
    @Binding var selectedType: ServiceType
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var searchText = ""

    private var filteredCategories: [(category: ServiceCategory, types: [ServiceType])] {
        ServiceCategory.allCases
            .filter { $0 != .custom }
            .compactMap { category in
                var types = ServiceType.types(for: category)
                if !searchText.isEmpty {
                    let q = searchText.lowercased()
                    types = types.filter { $0.rawValue.lowercased().contains(q) }
                }
                return types.isEmpty ? nil : (category: category, types: types)
            }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCategories, id: \.category) { group in
                    Section {
                        ForEach(group.types) { type in
                            Button {
                                selectedType = type
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: type.uniqueIcon)
                                        .font(.body)
                                        .foregroundStyle(type.color)
                                        .frame(width: 28)
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(type.rawValue)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)
                                        if type.defaultMileageInterval > 0 {
                                            Text("Every \(type.defaultMileageInterval.formatted()) \(UserSettings.shared.distanceUnit.label)")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }

                                    Spacer()

                                    if selectedType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(theme.accent)
                                    }
                                }
                            }
                            .accessibilityLabel(type.rawValue)
                            .accessibilityAddTraits(selectedType == type ? .isSelected : [])
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Image(systemName: group.category.icon)
                                .font(.caption)
                                .foregroundStyle(group.category.color)
                            Text(group.category.rawValue)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search service types")
            .navigationTitle("Service Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
