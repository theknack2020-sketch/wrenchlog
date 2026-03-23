import Foundation

// MARK: - Validation Result

struct ValidationResult {
    let isValid: Bool
    let errors: [String]

    static let valid = ValidationResult(isValid: true, errors: [])

    static func invalid(_ errors: [String]) -> ValidationResult {
        ValidationResult(isValid: false, errors: errors)
    }

    /// First error message, or nil if valid.
    var firstError: String? { errors.first }
}

// MARK: - Vehicle Validation

struct VehicleValidator {
    static let yearRange = 1886...Calendar.current.component(.year, from: .now) + 1

    static func validate(
        make: String,
        model: String,
        year: Int,
        mileage: String
    ) -> ValidationResult {
        var errors: [String] = []

        let trimmedMake = make.trimmingCharacters(in: .whitespaces)
        let trimmedModel = model.trimmingCharacters(in: .whitespaces)

        if trimmedMake.isEmpty {
            errors.append("Vehicle make is required.")
        } else if trimmedMake.count < 2 {
            errors.append("Make must be at least 2 characters.")
        }

        if trimmedModel.isEmpty {
            errors.append("Vehicle model is required.")
        }

        if !yearRange.contains(year) {
            errors.append("Year must be between \(yearRange.lowerBound) and \(yearRange.upperBound).")
        }

        if let m = Int(mileage) {
            if m < 0 {
                errors.append("Mileage cannot be negative.")
            }
        } else if !mileage.isEmpty {
            errors.append("Mileage must be a whole number.")
        }

        return errors.isEmpty ? .valid : .invalid(errors)
    }

    /// Validate that a mileage update is not going backwards.
    static func validateMileageUpdate(
        newMileage: Int,
        currentMileage: Int
    ) -> ValidationResult {
        if newMileage < 0 {
            return .invalid(["Mileage cannot be negative."])
        }
        if newMileage < currentMileage && currentMileage > 0 {
            return .invalid(["New mileage (\(newMileage.formatted())) is less than current (\(currentMileage.formatted())). Odometers don't go backwards."])
        }
        return .valid
    }
}

// MARK: - Service Record Validation

struct ServiceRecordValidator {

    static func validate(
        mileage: String,
        cost: String,
        customTypeName: String = "",
        isCustom: Bool = false,
        vehicleCurrentMileage: Int = 0
    ) -> ValidationResult {
        var errors: [String] = []

        if isCustom && customTypeName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Custom service name is required.")
        }

        if let m = Int(mileage), m < 0 {
            errors.append("Mileage cannot be negative.")
        }

        if let c = Double(cost), c < 0 {
            errors.append("Cost cannot be negative.")
        }

        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

// MARK: - Fuel Log Validation

struct FuelLogValidator {

    static func validate(
        volume: String,
        totalCost: String,
        mileage: String,
        vehicleCurrentMileage: Int = 0
    ) -> ValidationResult {
        var errors: [String] = []

        if let vol = Double(volume) {
            if vol <= 0 { errors.append("Volume must be greater than zero.") }
        } else if volume.isEmpty {
            errors.append("Volume is required.")
        } else {
            errors.append("Volume must be a valid number.")
        }

        if let cost = Double(totalCost) {
            if cost < 0 { errors.append("Cost cannot be negative.") }
        } else if totalCost.isEmpty {
            errors.append("Total cost is required.")
        }

        if let m = Int(mileage), m < 0 {
            errors.append("Mileage cannot be negative.")
        }

        return errors.isEmpty ? .valid : .invalid(errors)
    }
}
