import PhotosUI
import SwiftData
import SwiftUI

struct EditVehicleView: View {
    @Bindable var vehicle: Vehicle
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: Int = 2024
    @State private var mileage: String = ""
    @State private var licensePlate: String = ""
    @State private var vin: String = ""
    @State private var selectedColor: VehicleColor?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoChanged = false

    // VIN decode state
    @State private var isDecodingVIN = false
    @State private var vinDecodeError: String?
    @State private var vinDecodeSuccess = false

    private let vehiclePhotoManager = VehiclePhotoManager.shared
    private let nhtsaService = NHTSAService.shared

    // Validation & error state
    @State private var validationError: String?
    @State private var mileageWarning: String?
    @State private var showDuplicateWarning = false
    @State private var saveError: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Make", text: $make)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Vehicle make")
                        .onChange(of: make) { _, _ in validationError = nil }
                    TextField("Model", text: $model)
                        .textInputAutocapitalization(.words)
                        .accessibilityLabel("Vehicle model")
                        .onChange(of: model) { _, _ in validationError = nil }
                    Picker("Year", selection: $year) {
                        ForEach((1950 ... Calendar.current.component(.year, from: .now) + 1).reversed(), id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    TextField("Current Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Current odometer reading")
                        .onChange(of: mileage) { _, newValue in
                            validationError = nil
                            if let m = Int(newValue), m < vehicle.currentMileage, vehicle.currentMileage > 0 {
                                mileageWarning = "Lower than current (\(vehicle.currentMileage.formatted())). Are you sure?"
                            } else {
                                mileageWarning = nil
                            }
                        }
                } header: {
                    Text("Vehicle Info")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if let error = validationError {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        if let warning = mileageWarning {
                            Text(warning)
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }
                    }
                }

                // Vehicle Color
                Section("Vehicle Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                        ForEach(VehicleColor.allCases) { vc in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    selectedColor = selectedColor == vc ? nil : vc
                                }
                                HapticManager.shared.selection()
                            } label: {
                                Circle()
                                    .fill(vc.color)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(vc.needsBorder ? Color.secondary.opacity(0.3) : .clear, lineWidth: 1)
                                    }
                                    .overlay {
                                        if selectedColor == vc {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(vc == .black || vc == .navy ? .white : .primary)
                                        }
                                    }
                                    .scaleEffect(selectedColor == vc ? 1.1 : 1.0)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(vc.rawValue)
                            .accessibilityAddTraits(selectedColor == vc ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Details") {
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                        .accessibilityLabel("License plate number")

                    // VIN field with decode button
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            TextField("VIN (17 characters)", text: $vin)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .accessibilityLabel("Vehicle identification number")
                                .accessibilityHint("Enter 17-character VIN to auto-fill vehicle details")
                                .onChange(of: vin) { _, _ in
                                    vinDecodeError = nil
                                    vinDecodeSuccess = false
                                }

                            Button {
                                Task { await decodeVIN() }
                            } label: {
                                Group {
                                    if isDecodingVIN {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Label("Decode", systemImage: "barcode.viewfinder")
                                            .font(.caption.weight(.semibold))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    vinDecodeButtonEnabled
                                        ? theme.accent.opacity(0.15)
                                        : Color.secondary.opacity(0.08),
                                    in: Capsule()
                                )
                                .foregroundStyle(vinDecodeButtonEnabled ? theme.accent : .secondary)
                            }
                            .disabled(!vinDecodeButtonEnabled)
                            .accessibilityLabel("Decode VIN")
                            .accessibilityHint(vinDecodeButtonEnabled ? "Looks up vehicle details from the VIN" : "Enter a valid 17-character VIN first")
                        }

                        if vinDecodeSuccess {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                Text("Vehicle details filled from VIN")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .accessibilityLabel("VIN decoded successfully. Vehicle details auto-filled.")
                        }

                        if let error = vinDecodeError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .accessibilityLabel("VIN decode error: \(error)")
                        }
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 14) {
                            if let data = photoData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                                    .accessibilityLabel("Current vehicle photo")
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [theme.accent.opacity(0.15), theme.accent.opacity(0.05)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 80, height: 80)
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera.fill")
                                            .font(.title3)
                                            .foregroundStyle(theme.accent)
                                        Text("Add")
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(theme.accent)
                                    }
                                }
                                .accessibilityHidden(true)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(photoData == nil ? "Vehicle Photo" : "Change Photo")
                                    .font(.subheadline.weight(.medium))
                                Text("Helps identify your vehicle at a glance")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityLabel(photoData == nil ? "Add vehicle photo" : "Change vehicle photo")
                }

                // Last updated info
                Section {
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(vehicle.lastUpdated, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(maxWidth: sizeClass == .regular ? 500 : .infinity)
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                    .accessibilityIdentifier("editVehicleCancel")
                    .accessibilityLabel("Cancel editing")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.shared.buttonTap()
                        validateAndSave()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.accent)
                    .disabled(make.trimmingCharacters(in: .whitespaces).isEmpty || model.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("editVehicleSave")
                    .accessibilityLabel("Save changes")
                    .accessibilityHint("Saves updated vehicle information")
                }
            }
            .onAppear {
                make = vehicle.make
                model = vehicle.model
                year = vehicle.year
                mileage = "\(vehicle.currentMileage)"
                licensePlate = vehicle.licensePlate
                vin = vehicle.vin
                selectedColor = vehicle.vehicleColor

                // Load existing photo: prefer file-based, fall back to legacy blob
                if let img = vehiclePhotoManager.loadVehiclePhoto(named: vehicle.vehiclePhotoFileName) {
                    photoData = img.jpegData(compressionQuality: 0.8)
                } else {
                    photoData = vehicle.photoData
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        photoData = data
                        photoChanged = true
                    }
                }
            }
            .alert("Possible Duplicate", isPresented: $showDuplicateWarning) {
                Button("Save Anyway") { performSave() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("A \(year) \(make) \(model) already exists in your garage. Save anyway?")
            }
            .alert("Save Failed", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "An unexpected error occurred.")
            }
        }
    }

    private func validateAndSave() {
        let result = VehicleValidator.validate(make: make, model: model, year: year, mileage: mileage)
        guard result.isValid else {
            validationError = result.firstError
            HapticManager.shared.error()
            return
        }

        // Check for duplicates (excluding self)
        if DataManager.duplicateVehicleExists(make: make, model: model, year: year, excludingId: vehicle.id, in: context) {
            showDuplicateWarning = true
            return
        }

        performSave()
    }

    private func performSave() {
        vehicle.make = make.trimmingCharacters(in: .whitespaces)
        vehicle.model = model.trimmingCharacters(in: .whitespaces)
        vehicle.year = year
        vehicle.currentMileage = max(0, Int(mileage) ?? vehicle.currentMileage)
        vehicle.licensePlate = licensePlate
        vehicle.vin = vin
        vehicle.colorRaw = selectedColor?.rawValue ?? ""

        // Save photo via file-based manager only if user picked a new one
        if photoChanged, let data = photoData {
            // Delete old file if it exists
            if !vehicle.vehiclePhotoFileName.isEmpty {
                vehiclePhotoManager.deleteVehiclePhoto(named: vehicle.vehiclePhotoFileName)
            }
            if let fileName = vehiclePhotoManager.saveVehiclePhoto(data, vehicleId: vehicle.id) {
                vehicle.vehiclePhotoFileName = fileName
            }
        }
        vehicle.photoData = nil // Migrate away from blob storage
        vehicle.lastUpdated = .now

        do {
            try DataManager.save(context)
            HapticManager.shared.saveSuccess()
            SoundManager.playSaveSuccess()
            dismiss()
        } catch {
            saveError = error.errorDescription
            HapticManager.shared.error()
            SoundManager.playError()
        }
    }

    // MARK: - VIN Decode

    private var vinDecodeButtonEnabled: Bool {
        !isDecodingVIN && nhtsaService.isValidVIN(vin)
    }

    private func decodeVIN() async {
        isDecodingVIN = true
        vinDecodeError = nil
        vinDecodeSuccess = false

        do {
            let result = try await nhtsaService.decodeVIN(vin)

            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                if !result.make.isEmpty { make = result.make }
                if !result.model.isEmpty { model = result.model }
                if result.year > 0 { year = result.year }
                vinDecodeSuccess = true
            }

            HapticManager.shared.success()
            SoundManager.playSaveSuccess()
        } catch {
            vinDecodeError = error.localizedDescription
            HapticManager.shared.error()
        }

        isDecodingVIN = false
    }
}
