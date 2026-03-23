import SwiftData

// MARK: - Schema V1 (Baseline)

/// Baseline schema matching the initial App Store release.
enum WrenchLogSchemaV1: VersionedSchema {
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Vehicle.self, ServiceRecord.self, FuelLog.self, MaintenanceChecklistItem.self]
    }
}

// MARK: - Schema V2 (Documents model)

/// V2 adds VehicleDocument model for storing vehicle documents.
enum WrenchLogSchemaV2: VersionedSchema {
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Vehicle.self, ServiceRecord.self, FuelLog.self, MaintenanceChecklistItem.self, VehicleDocument.self]
    }
}

// MARK: - Schema V3 (Vehicle purchase & photo fields)

/// V3 adds purchase info, file-based photo, and documents relationship to Vehicle.
enum WrenchLogSchemaV3: VersionedSchema {
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Vehicle.self, ServiceRecord.self, FuelLog.self, MaintenanceChecklistItem.self, VehicleDocument.self]
    }
}

// MARK: - Migration Plan

enum WrenchLogMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WrenchLogSchemaV1.self, WrenchLogSchemaV2.self, WrenchLogSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: WrenchLogSchemaV1.self,
        toVersion: WrenchLogSchemaV2.self
    )

    /// V2→V3: adds purchaseDate, purchasePrice, vehiclePhotoFileName to Vehicle,
    /// and documents relationship. All have defaults, so lightweight migration works.
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: WrenchLogSchemaV2.self,
        toVersion: WrenchLogSchemaV3.self
    )
}
