import SwiftUI
import PhotosUI

struct EditVehicleView: View {
    @Bindable var vehicle: Vehicle
    @Environment(\.dismiss) private var dismiss

    @State private var make: String = ""
    @State private var model: String = ""
    @State private var year: Int = 2024
    @State private var mileage: String = ""
    @State private var licensePlate: String = ""
    @State private var vin: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Info") {
                    TextField("Make", text: $make)
                        .textInputAutocapitalization(.words)
                    TextField("Model", text: $model)
                        .textInputAutocapitalization(.words)
                    Picker("Year", selection: $year) {
                        ForEach((1990...Calendar.current.component(.year, from: .now) + 1).reversed(), id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    TextField("Current Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                }

                Section("Details") {
                    TextField("License Plate", text: $licensePlate)
                        .textInputAutocapitalization(.characters)
                    TextField("VIN", text: $vin)
                        .textInputAutocapitalization(.characters)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let data = photoData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(Color.wrenchAmber)
                            }
                            Text(photoData == nil ? "Add Photo" : "Change Photo")
                        }
                    }
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                        .disabled(make.isEmpty || model.isEmpty)
                }
            }
            .onAppear {
                make = vehicle.make
                model = vehicle.model
                year = vehicle.year
                mileage = "\(vehicle.currentMileage)"
                licensePlate = vehicle.licensePlate
                vin = vehicle.vin
                photoData = vehicle.photoData
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private func saveChanges() {
        vehicle.make = make.trimmingCharacters(in: .whitespaces)
        vehicle.model = model.trimmingCharacters(in: .whitespaces)
        vehicle.year = year
        vehicle.currentMileage = Int(mileage) ?? vehicle.currentMileage
        vehicle.licensePlate = licensePlate
        vehicle.vin = vin
        vehicle.photoData = photoData
        dismiss()
    }
}
