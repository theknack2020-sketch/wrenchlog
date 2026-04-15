import Foundation
import SwiftData

/// Represents a stored document (insurance card, registration, inspection report, etc.)
/// attached to a vehicle. The actual file is stored in the app's documents directory;
/// this model tracks metadata.
@Model
final class VehicleDocument {
    var id: UUID = UUID()
    var title: String = ""
    var fileName: String = "" // filename in documents directory
    var documentTypeRaw: String = "Other" // DocumentType.rawValue
    var dateAdded: Date = Date.now
    var expirationDate: Date?
    var notes: String = ""
    var fileSizeBytes: Int = 0

    var vehicle: Vehicle?

    var documentType: DocumentType {
        DocumentType(rawValue: documentTypeRaw) ?? .other
    }

    init(
        title: String,
        fileName: String,
        documentType: DocumentType = .other,
        fileSizeBytes: Int = 0,
        notes: String = ""
    ) {
        id = UUID()
        self.title = title
        self.fileName = fileName
        documentTypeRaw = documentType.rawValue
        dateAdded = .now
        self.fileSizeBytes = fileSizeBytes
        self.notes = notes
    }
}

// MARK: - Document Type

enum DocumentType: String, Codable, CaseIterable, Identifiable {
    case insurance = "Insurance"
    case registration = "Registration"
    case title = "Title"
    case inspection = "Inspection"
    case warranty = "Warranty"
    case receipt = "Receipt"
    case other = "Other"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .insurance: "shield.checkered"
        case .registration: "doc.text.fill"
        case .title: "scroll.fill"
        case .inspection: "checkmark.shield.fill"
        case .warranty: "doc.badge.clock.fill"
        case .receipt: "receipt.fill"
        case .other: "doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .insurance: .catEngine
        case .registration: .catTires
        case .title: Color.amber.shade500
        case .inspection: .catInspection
        case .warranty: .catElectrical
        case .receipt: .catFilters
        case .other: .catCustom
        }
    }
}

import SwiftUI
