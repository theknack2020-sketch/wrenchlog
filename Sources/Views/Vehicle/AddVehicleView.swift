import SwiftUI
import PhotosUI

struct AddVehicleView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: .now)
    @State private var mileage = ""
    @State private var licensePlate = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle Info") {
                    TextField("Make (e.g., Toyota)", text: $make)
                        .textInputAutocapitalization(.words)
                    TextField("Model (e.g., Camry)", text: $model)
                        .textInputAutocapitalization(.words)
                    Picker("Year", selection: $year) {
                        ForEach((1990...Calendar.current.component(.year, from: .now) + 1).reversed(), id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    TextField("Current Mileage", text: $mileage)
                        .keyboardType(.numberPad)
                }

                Section("Optional") {
                    TextField("License Plate", text: $licensePlate)
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
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveVehicle() }
                        .disabled(make.isEmpty || model.isEmpty)
                        .fontWeight(.semibold)
                }
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

    private func saveVehicle() {
        let vehicle = Vehicle(
            make: make.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            year: year,
            mileage: Int(mileage) ?? 0
        )
        vehicle.licensePlate = licensePlate
        vehicle.photoData = photoData
        context.insert(vehicle)
        try? context.save()
        dismiss()
    }
}
