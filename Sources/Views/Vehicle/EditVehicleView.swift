import SwiftUI
import SwiftData
import PhotosUI

struct EditVehicleView: View {
    @Bindable var vehicle: Vehicle
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme

    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: Int = 2024
    @State private var mileage: String = ""
    @State private var licensePlate: String = ""
    @State private var vin: String = ""
    @State private var selectedColor: VehicleColor?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    // Validation & error state
    @State private var validationError: String?
    @State private var mileageWarning: String?
    @State private var showDuplicateWarning = false
    @State private var saveError: String?

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
                        ForEach((1950...Calendar.current.component(.year, from: .now) + 1).reversed(), id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    TextField("Current Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Current odometer reading")
                        .onChange(of: mileage) { _, newValue in
                            validationError = nil
                            if let m = Int(newValue), m < vehicle.currentMileage && vehicle.currentMileage > 0 {
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
                    TextField("VIN", text: $vin)
                        .textInputAutocapitalization(.characters)
                        .accessibilityLabel("Vehicle identification number")
                        .accessibilityHint("17-character VIN code")

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let data = photoData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .accessibilityLabel("Current vehicle photo")
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
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        dismiss()
                    }
                    .accessibilityLabel("Cancel editing")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.shared.buttonTap()
                        validateAndSave()
                    }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.wrenchAmber)
                        .disabled(make.trimmingCharacters(in: .whitespaces).isEmpty || model.trimmingCharacters(in: .whitespaces).isEmpty)
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
                photoData = vehicle.photoData
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
        vehicle.photoData = photoData
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
}
