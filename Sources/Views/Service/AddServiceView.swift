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

    // New detail fields
    @State private var partsUsed: [String] = []
    @State private var newPartText = ""
    @State private var oilType = ""
    @State private var shopName = ""
    @State private var showOilTypePicker = false

    // Validation & error state
    @State private var validationError: String?
    @State private var serviceTypeError: String?
    @State private var mileageFieldError: String?
    @State private var costFieldError: String?
    @State private var saveError: String?
    @State private var photoWarnings: [String] = []
    @State private var isSaving = false
    @State private var shakeTrigger = 0
    @FocusState private var isFocused: Bool

    private let store = StoreManager.shared
    private let photoManager = ServicePhotoManager.shared
    private let haptic = HapticManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                // MARK: - Service Type (Grouped by Category)
                Section {
                    customServiceToggleRow

                    if isCustom {
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
                        .listRowBackground(
                            serviceTypeError != nil
                                ? Color.red.opacity(0.06)
                                : Color(.secondarySystemGroupedBackground)
                        )
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
                        .pressable()
                    }
                } header: {
                    Text("Service Type")
                        .font(.system(.headline, design: .rounded))
                }

                // MARK: - Details
                Section {
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
                    .listRowBackground(
                        mileageFieldError != nil
                            ? Color.red.opacity(0.06)
                            : Color(.secondarySystemGroupedBackground)
                    )

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
                    .listRowBackground(
                        costFieldError != nil
                            ? Color.red.opacity(0.06)
                            : Color(.secondarySystemGroupedBackground)
                    )
                }

                // MARK: - Notes
                Section("Notes (optional)") {
                    TextField("Any additional details...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Service notes")
                }

                // MARK: - Shop / Service Provider
                Section {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        TextField("Shop or mechanic name", text: $shopName)
                            .accessibilityLabel("Service provider name")
                            .accessibilityHint("Who performed the service")
                    }

                    if !recentShops.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentShops, id: \.self) { shop in
                                    Button {
                                        shopName = shop
                                    } label: {
                                        Text(shop)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(shopName == shop ? theme.accent.opacity(0.2) : Color(.systemGray6))
                                            .foregroundStyle(shopName == shop ? theme.accent : .primary)
                                            .clipShape(Capsule())
                                    }
                                    .accessibilityLabel("Select \(shop)")
                                    .accessibilityAddTraits(shopName == shop ? .isSelected : [])
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Text("Service Provider")
                }

                // MARK: - Parts Used
                Section {
                    // Suggested parts chips (from service type)
                    if !isCustom {
                        let suggestions = selectedType.recommendedParts.filter { !partsUsed.contains($0) }
                        if !suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Suggested parts")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                FlowLayout(spacing: 6) {
                                    ForEach(suggestions, id: \.self) { part in
                                        Button {
                                            withAnimation(.snappy(duration: 0.2)) {
                                                partsUsed.append(part)
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.caption2)
                                                Text(part)
                                                    .font(.caption)
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 5)
                                            .background(Color(.systemGray6))
                                            .foregroundStyle(.primary)
                                            .clipShape(Capsule())
                                        }
                                        .accessibilityLabel("Add \(part)")
                                    }
                                }
                            }
                        }
                    }

                    // Added parts
                    ForEach(partsUsed, id: \.self) { part in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text(part)
                                .font(.subheadline)
                            Spacer()
                            Button {
                                withAnimation(.snappy(duration: 0.2)) {
                                    partsUsed.removeAll { $0 == part }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .accessibilityLabel("Remove \(part)")
                        }
                    }

                    // Custom part entry
                    HStack {
                        Image(systemName: "wrench.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        TextField("Add custom part...", text: $newPartText)
                            .onSubmit { addCustomPart() }
                            .accessibilityLabel("Custom part name")
                        if !newPartText.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button {
                                addCustomPart()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(theme.accent)
                            }
                            .accessibilityLabel("Add part")
                        }
                    }
                } header: {
                    Text("Parts Used")
                } footer: {
                    Text("Track parts and products for warranty and reorder reference.")
                }

                // MARK: - Oil Type (contextual)
                if !isCustom && selectedType.involvesOil || isCustom {
                    Section {
                        Button {
                            showOilTypePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                    .accessibilityHidden(true)
                                if oilType.isEmpty {
                                    Text("Select oil type")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(oilType)
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel("Oil type: \(oilType.isEmpty ? "not set" : oilType)")
                        .accessibilityHint("Select the oil type or specification used")

                        if !oilType.isEmpty {
                            Button(role: .destructive) {
                                oilType = ""
                            } label: {
                                Text("Clear oil type")
                                    .font(.caption)
                            }
                            .accessibilityLabel("Clear selected oil type")
                        }
                    } header: {
                        Text("Oil / Fluid Type")
                    }
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
                        .accessibilityLabel("Reminder will be set. Next: \(selectedType.defaultMileageInterval.formatted()) \(UserSettings.shared.distanceUnit.label) or \(selectedType.defaultMonthInterval) months")
                    }
                }
                } // Form
                .scrollDismissesKeyboard(.interactively)

                CelebrationOverlay(isShowing: $showCelebration)
            } // ZStack
            .navigationTitle("Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
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
                ServiceTypePickerView(
                    selectedType: $selectedType,
                    isCustom: $isCustom,
                    customTypeName: $customTypeName
                )
            }
            .sheet(isPresented: $showOilTypePicker) {
                OilTypePickerView(selectedOilType: $oilType)
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .accessibilityIdentifier("addServiceCancel")
                .accessibilityLabel("Cancel logging service")
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { saveRecord() }
                .fontWeight(.semibold)
                .foregroundStyle(Color.wrenchAmber)
                .disabled(isSaving)
                .shake(trigger: shakeTrigger)
                .accessibilityIdentifier("addServiceSave")
                .accessibilityLabel("Save service record")
                .accessibilityHint("Logs this service to your vehicle history")
        }
    }

    /// Recent shop names from this vehicle's history for quick selection
    private var recentShops: [String] {
        let shops = vehicle.safeServiceRecords
            .map(\.shopName)
            .filter { !$0.isEmpty }
        // Deduplicate while preserving order (most recent first)
        var seen = Set<String>()
        return shops.reversed().filter { seen.insert($0).inserted }
    }

    private func addCustomPart() {
        let trimmed = newPartText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !partsUsed.contains(trimmed) else { return }
        withAnimation(.snappy(duration: 0.2)) {
            partsUsed.append(trimmed)
        }
        newPartText = ""
    }

    @ViewBuilder
    private var customServiceToggleRow: some View {
        if store.isPro {
            Toggle("Custom Service", isOn: $isCustom)
                .accessibilityHint("Enable to enter a custom service type")
        } else {
            Button {
                showProPrompt = true
            } label: {
                HStack {
                    Text("Custom Service")
                    Spacer()
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundStyle(Color.wrenchAmber)
                }
            }
            .accessibilityLabel("Custom service, Pro feature")
            .accessibilityHint("Upgrade to Pro to create custom service types")
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
            withAnimation(.default) { shakeTrigger += 1 }
            haptic.error()
            return
        }

        isSaving = true

        let record: ServiceRecord
        if isCustom {
            let trimmedCustom = customTypeName.trimmingCharacters(in: .whitespaces)
            record = ServiceRecord(
                customType: trimmedCustom,
                date: date,
                mileage: max(0, Int(mileage) ?? 0),
                cost: max(0, Double(cost) ?? 0),
                notes: notes,
                partsUsed: partsUsed,
                oilType: oilType,
                shopName: shopName.trimmingCharacters(in: .whitespaces)
            )
            // Persist custom type for future picker use
            var saved = UserDefaults.standard.stringArray(forKey: "wl_custom_service_types") ?? []
            if !saved.contains(trimmedCustom) {
                saved.append(trimmedCustom)
                UserDefaults.standard.set(saved, forKey: "wl_custom_service_types")
            }
        } else {
            record = ServiceRecord(
                serviceType: selectedType,
                date: date,
                mileage: max(0, Int(mileage) ?? 0),
                cost: max(0, Double(cost) ?? 0),
                notes: notes,
                partsUsed: partsUsed,
                oilType: oilType,
                shopName: shopName.trimmingCharacters(in: .whitespaces)
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

        // Calendar sync — add event if user has enabled it
        if CalendarStore.calendarSyncEnabled {
            let eventId = CalendarService.shared.addServiceEvent(
                serviceType: record.displayServiceType,
                vehicleName: vehicle.displayName,
                date: date,
                cost: max(0, Double(cost) ?? 0),
                shopName: shopName.trimmingCharacters(in: .whitespaces),
                notes: notes
            )
            if let eventId { record.calendarEventId = eventId }
        }

        let totalServices = vehicle.safeServiceRecords.count
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

        // Track action for soft paywall
        SoftPaywallTracker.shared.recordAction()

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
    @Binding var isCustom: Bool
    @Binding var customTypeName: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var searchText = ""
    @State private var newCustomType = ""
    private let store = StoreManager.shared

    private var savedCustomTypes: [String] {
        (UserDefaults.standard.stringArray(forKey: "wl_custom_service_types") ?? [])
            .sorted()
    }

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

    private var filteredCustomTypes: [String] {
        if searchText.isEmpty { return savedCustomTypes }
        let q = searchText.lowercased()
        return savedCustomTypes.filter { $0.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            List {
                standardCategorySections
                customTypesSection
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

    @ViewBuilder
    private var standardCategorySections: some View {
        ForEach(filteredCategories, id: \.category) { group in
            Section {
                ForEach(group.types) { type in
                    Button {
                        isCustom = false
                        customTypeName = ""
                        selectedType = type
                        dismiss()
                    } label: {
                        standardTypeRow(type)
                    }
                    .accessibilityLabel(type.rawValue)
                    .accessibilityAddTraits(!isCustom && selectedType == type ? .isSelected : [])
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

    private func standardTypeRow(_ type: ServiceType) -> some View {
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

            if !isCustom && selectedType == type {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(theme.accent)
            }
        }
    }

    @ViewBuilder
    private var customTypesSection: some View {
        if store.isPro {
            Section {
                ForEach(filteredCustomTypes, id: \.self) { typeName in
                    Button {
                        isCustom = true
                        customTypeName = typeName
                        dismiss()
                    } label: {
                        customTypeRow(typeName)
                    }
                    .accessibilityLabel(typeName)
                    .accessibilityAddTraits(isCustom && customTypeName == typeName ? .isSelected : [])
                }
                .onDelete { indexSet in
                    var types = savedCustomTypes
                    types.remove(atOffsets: indexSet)
                UserDefaults.standard.set(types, forKey: "wl_custom_service_types")
            }

            // Add new custom type inline
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(theme.accent)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                TextField("Add custom type…", text: $newCustomType)
                    .onSubmit { addAndSelectCustomType() }
                    .accessibilityLabel("New custom service type name")
                if !newCustomType.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Add") { addAndSelectCustomType() }
                        .foregroundStyle(theme.accent)
                        .accessibilityLabel("Add custom type")
                }
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: ServiceCategory.custom.icon)
                    .font(.caption)
                    .foregroundStyle(ServiceCategory.custom.color)
                Text("Custom")
            }
        }
        } // end if store.isPro
    }

    private func customTypeRow(_ typeName: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.body)
                .foregroundStyle(Color.catCustom)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(typeName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
            Spacer()
            if isCustom && customTypeName == typeName {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(theme.accent)
            }
        }
    }

    private func addAndSelectCustomType() {
        guard store.isPro else { return }
        let trimmed = newCustomType.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        // Persist to UserDefaults
        var types = UserDefaults.standard.stringArray(forKey: "wl_custom_service_types") ?? []
        if !types.contains(trimmed) {
            types.append(trimmed)
            UserDefaults.standard.set(types, forKey: "wl_custom_service_types")
        }
        // Select it
        isCustom = true
        customTypeName = trimmed
        dismiss()
    }
}

// MARK: - Oil Type Picker

struct OilTypePickerView: View {
    @Binding var selectedOilType: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var customOilType = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Common Oil Types") {
                    ForEach(ServiceType.commonOilTypes, id: \.self) { type in
                        Button {
                            selectedOilType = type
                            dismiss()
                        } label: {
                            HStack {
                                Text(type)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedOilType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.accent)
                                }
                            }
                        }
                        .accessibilityLabel(type)
                        .accessibilityAddTraits(selectedOilType == type ? .isSelected : [])
                    }
                }

                Section("Custom") {
                    HStack {
                        TextField("Enter oil type...", text: $customOilType)
                            .onSubmit {
                                let trimmed = customOilType.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                selectedOilType = trimmed
                                dismiss()
                            }
                        if !customOilType.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button("Add") {
                                selectedOilType = customOilType.trimmingCharacters(in: .whitespaces)
                                dismiss()
                            }
                            .foregroundStyle(theme.accent)
                        }
                    }
                }
            }
            .navigationTitle("Oil Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Flow Layout (for part suggestion chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var origins: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}

// MARK: - Calendar Preferences Store

struct CalendarStore {
    nonisolated(unsafe) private static let defaults = UserDefaults.standard

    static var calendarSyncEnabled: Bool {
        get { defaults.bool(forKey: "wl_calendar_sync_enabled") }
        set { defaults.set(newValue, forKey: "wl_calendar_sync_enabled") }
    }
}
