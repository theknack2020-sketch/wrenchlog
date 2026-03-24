import Foundation
import SwiftData

@Model
final class MaintenanceChecklistItem {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var createdDate: Date = Date.now
    var completedDate: Date?
    var vehicle: Vehicle?

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdDate = .now
    }
}
