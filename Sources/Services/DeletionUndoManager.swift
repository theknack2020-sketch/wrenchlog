import Foundation

// MARK: - Deleted Record Snapshot

/// Lightweight snapshot of a deleted service record — enough to reconstruct it.
struct DeletedServiceRecordSnapshot {
    let serviceTypeRaw: String
    let categoryRaw: String
    let date: Date
    let mileage: Int
    let cost: Double
    let notes: String
    let photoFileNames: [String]
    let deletedAt: Date

    /// How long the undo window lasts (seconds).
    static let undoWindowDuration: TimeInterval = 10
}

/// Lightweight snapshot for a deleted fuel log.
struct DeletedFuelLogSnapshot {
    let date: Date
    let mileage: Int
    let volume: Double
    let totalCost: Double
    let pricePerUnit: Double
    let fuelTypeRaw: String
    let station: String
    let isFullTank: Bool
    let notes: String
    let volumeUnitRaw: String
    let deletedAt: Date

    static let undoWindowDuration: TimeInterval = 10
}

// MARK: - UndoManager for Deletions

/// Provides a brief undo window after deleting records.
/// Stores one snapshot per type (last deleted). Not a full undo stack.
@Observable @MainActor
final class DeletionUndoManager {
    static let shared = DeletionUndoManager()

    private(set) var lastDeletedService: DeletedServiceRecordSnapshot?
    private(set) var lastDeletedFuelLog: DeletedFuelLogSnapshot?

    /// True while an undo is available (within time window).
    var canUndoService: Bool {
        guard let snapshot = lastDeletedService else { return false }
        return Date().timeIntervalSince(snapshot.deletedAt) < DeletedServiceRecordSnapshot.undoWindowDuration
    }

    var canUndoFuelLog: Bool {
        guard let snapshot = lastDeletedFuelLog else { return false }
        return Date().timeIntervalSince(snapshot.deletedAt) < DeletedFuelLogSnapshot.undoWindowDuration
    }

    func storeDeletedService(_ record: DeletedServiceRecordSnapshot) {
        lastDeletedService = record
    }

    func storeDeletedFuelLog(_ log: DeletedFuelLogSnapshot) {
        lastDeletedFuelLog = log
    }

    func clearService() { lastDeletedService = nil }
    func clearFuelLog() { lastDeletedFuelLog = nil }

    /// Reconstruct and return a new ServiceRecord from the stored snapshot. Returns nil if expired.
    func reconstructService() -> (serviceTypeRaw: String, categoryRaw: String, date: Date, mileage: Int, cost: Double, notes: String, photoFileNames: [String])? {
        guard canUndoService, let s = lastDeletedService else { return nil }
        lastDeletedService = nil
        return (s.serviceTypeRaw, s.categoryRaw, s.date, s.mileage, s.cost, s.notes, s.photoFileNames)
    }

    func reconstructFuelLog() -> (date: Date, mileage: Int, volume: Double, totalCost: Double, pricePerUnit: Double, fuelTypeRaw: String, station: String, isFullTank: Bool, notes: String, volumeUnitRaw: String)? {
        guard canUndoFuelLog, let l = lastDeletedFuelLog else { return nil }
        lastDeletedFuelLog = nil
        return (l.date, l.mileage, l.volume, l.totalCost, l.pricePerUnit, l.fuelTypeRaw, l.station, l.isFullTank, l.notes, l.volumeUnitRaw)
    }

    private init() {}
}
