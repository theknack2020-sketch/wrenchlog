import SwiftUI
import SwiftData
import PhotosUI

struct AddVehicleView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var mileage = ""
    @State private var licensePlate = ""
    @State private var selectedColor: VehicleColor?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    // Validation & error state
    @State private var validationError: String?
    @State private var makeError: String?
    @State private var modelError: String?
    @State private var mileageError: String?
    @State private var showDuplicateWarning = false
    @State private var saveError: String?
    @State private var isSaving = false

    private var isFormValid: Bool {
        let result = VehicleValidator.validate(make: make, model: model, year: year, mileage: mileage)
        return result.isValid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Make (e.g., Toyota)", text: $make)
                            .textInputAutocapitalization(.words)
                            .accessibilityLabel("Vehicle make")
                            .accessibilityHint("Enter the manufacturer name")
                            .onChange(of: make) { _, _ in makeError = nil; validationError = nil }
                        if let err = makeError {
                            Text(err)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    .listRowBackground(
                        makeError != nil
                            ? Color.red.opacity(0.06)
                            : Color(.secondarySystemGroupedBackground)
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Model (e.g., Camry)", text: $model)
                            .textInputAutocapitalization(.words)
                            .accessibilityLabel("Vehicle model")
                            .onChange(of: model) { _, _ in modelError = nil; validationError = nil }
                        if let err = modelError {
                            Text(err)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    .listRowBackground(
                        modelError != nil
                            ? Color.red.opacity(0.06)
                            : Color(.secondarySystemGroupedBackground)
                    )
                    Picker("Year", selection: $year) {
                        ForEach((1950...Calendar.current.component(.year, from: .now) + 1).reversed(), id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    .accessibilityLabel("Model year: \(String(year))")
                    .onChange(of: year) { _, _ in HapticManager.shared.selection() }
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Current Mileage", text: $mileage)
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Current odometer reading")
                            .accessibilityHint("Enter current mileage in \(UserSettings.shared.distanceUnit.label)")
                            .onChange(of: mileage) { _, _ in mileageError = nil; validationError = nil }
                        if let err = mileageError {
                            Text(err)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                    .listRowBackground(
                        mileageError != nil
                            ? Color.red.opacity(0.06)
                            : Color(.secondarySystemGroupedBackground)
                    )
                } header: {
                    Text("Vehicle Info")
                }

                // Vehicle Color
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vehicle Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

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
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                        .accessibilityLabel("License plate number")

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let data = photoData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .accessibilityLabel("Selected vehicle photo")
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(theme.accent.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "camera.fill")
                                        .foregroundStyle(theme.accent)
                                }
                                .accessibilityHidden(true)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(photoData == nil ? "Add Photo" : "Change Photo")
                                    .font(.subheadline)
                                Text("A photo of your vehicle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityLabel(photoData == nil ? "Add vehicle photo" : "Change vehicle photo")
                } header: {
                    Text("Optional")
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                    .accessibilityLabel("Cancel adding vehicle")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.shared.buttonTap()
                        validateAndSave()
                    }
                        .disabled(!isFormValid || isSaving)
                        .fontWeight(.semibold)
                        .foregroundStyle(isFormValid ? Color.wrenchAmber : .secondary)
                        .accessibilityLabel("Save vehicle")
                        .accessibilityHint(isFormValid ? "Saves the vehicle to your garage" : "Enter make and model first")
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            .alert("Possible Duplicate", isPresented: $showDuplicateWarning) {
                Button("Save Anyway") { performSave() }
                Button("Cancel", role: .cancel) { isSaving = false }
            } message: {
                Text("A \(year) \(make) \(model) already exists in your garage. Save anyway?")
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

    private func validateAndSave() {
        // Clear previous errors
        makeError = nil
        modelError = nil
        mileageError = nil

        // Run per-field validation
        let trimmedMake = make.trimmingCharacters(in: .whitespaces)
        let trimmedModel = model.trimmingCharacters(in: .whitespaces)

        var hasError = false

        if trimmedMake.isEmpty {
            makeError = "Vehicle make is required."
            hasError = true
        } else if trimmedMake.count < 2 {
            makeError = "Make must be at least 2 characters."
            hasError = true
        }

        if trimmedModel.isEmpty {
            modelError = "Vehicle model is required."
            hasError = true
        }

        if let m = Int(mileage), m < 0 {
            mileageError = "Mileage cannot be negative."
            hasError = true
        } else if !mileage.isEmpty && Int(mileage) == nil {
            mileageError = "Mileage must be a whole number."
            hasError = true
        }

        guard !hasError else {
            HapticManager.shared.error()
            return
        }

        isSaving = true

        // Check for duplicates
        if DataManager.duplicateVehicleExists(make: make, model: model, year: year, in: context) {
            showDuplicateWarning = true
            return
        }

        performSave()
    }

    private func performSave() {
        let vehicle = Vehicle(
            make: make.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            year: year,
            mileage: max(0, Int(mileage) ?? 0)
        )
        vehicle.licensePlate = licensePlate
        vehicle.photoData = photoData
        vehicle.colorRaw = selectedColor?.rawValue ?? ""
        context.insert(vehicle)

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
}
