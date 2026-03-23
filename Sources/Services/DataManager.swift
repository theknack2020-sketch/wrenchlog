import SwiftData
import SwiftUI

// MARK: - Persistence Error

/// Typed errors for SwiftData operations — surfaceable in UI.
enum PersistenceError: LocalizedError {
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case containerUnavailable
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            "Unable to save your data. Please try again."
        case .fetchFailed:
            "Unable to load your data. Restarting the app may help."
        case .deleteFailed:
            "Unable to delete the record. Please try again."
        case .containerUnavailable:
            "Data storage is unavailable. Please restart the app."
        case .unknown:
            "An unexpected error occurred. Please try again."
        }
    }
}

// MARK: - DataManager

/// Centralizes SwiftData operations with proper error handling.
@MainActor
struct DataManager {

    // MARK: - Safe Save

    /// Save the context, surfacing failures as `PersistenceError`.
    static func save(_ context: ModelContext) throws(PersistenceError) {
        do {
            try context.save()
        } catch {
            print("[WrenchLog] Save error: \(error)")
            throw .saveFailed(underlying: error)
        }
    }

    /// Save without throwing — returns success/failure.
    @discardableResult
    static func trySave(_ context: ModelContext) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            print("[WrenchLog] Save error: \(error)")
            return false
        }
    }

    // MARK: - Safe Fetch

    static func fetch<T: PersistentModel>(
        _ descriptor: FetchDescriptor<T>,
        from context: ModelContext
    ) throws(PersistenceError) -> [T] {
        do {
            return try context.fetch(descriptor)
        } catch {
            print("[WrenchLog] Fetch error: \(error)")
            throw .fetchFailed(underlying: error)
        }
    }

    // MARK: - Safe Delete

    static func delete<T: PersistentModel>(
        _ object: T,
        from context: ModelContext
    ) throws(PersistenceError) {
        context.delete(object)
        do {
            try context.save()
        } catch {
            print("[WrenchLog] Delete+save error: \(error)")
            throw .deleteFailed(underlying: error)
        }
    }

    // MARK: - Insert + Save

    static func insert<T: PersistentModel>(
        _ object: T,
        into context: ModelContext
    ) throws(PersistenceError) {
        context.insert(object)
        do {
            try context.save()
        } catch {
            print("[WrenchLog] Insert+save error: \(error)")
            throw .saveFailed(underlying: error)
        }
    }

    // MARK: - Duplicate Vehicle Detection

    /// Check whether a vehicle with matching make, model, and year already exists.
    static func duplicateVehicleExists(
        make: String,
        model: String,
        year: Int,
        excludingId: UUID? = nil,
        in context: ModelContext
    ) -> Bool {
        let trimmedMake = make.trimmingCharacters(in: .whitespaces).lowercased()
        let trimmedModel = model.trimmingCharacters(in: .whitespaces).lowercased()

        // SwiftData #Predicate doesn't support lowercased(), so we fetch and filter
        let descriptor = FetchDescriptor<Vehicle>()
        guard let vehicles = try? context.fetch(descriptor) else { return false }

        return vehicles.contains { v in
            v.make.lowercased() == trimmedMake &&
            v.model.lowercased() == trimmedModel &&
            v.year == year &&
            v.id != excludingId
        }
    }
}
