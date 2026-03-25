import CoreSpotlight
import MobileCoreServices

struct SpotlightService {
    @MainActor
    static func indexVehicles(_ vehicles: [Vehicle]) {
        var items: [CSSearchableItem] = []
        for vehicle in vehicles where !vehicle.isArchived {
            let attrs = CSSearchableItemAttributeSet(contentType: .text)
            attrs.title = vehicle.displayName
            attrs.contentDescription = "\(vehicle.safeServiceRecords.count) services · \(UserSettings.shared.formatMileage(vehicle.currentMileage))"
            attrs.keywords = [vehicle.make, vehicle.model, String(vehicle.year), "WrenchLog"]

            let item = CSSearchableItem(
                uniqueIdentifier: "vehicle-\(vehicle.id.uuidString)",
                domainIdentifier: "com.theknack.wrenchlog.vehicles",
                attributeSet: attrs
            )
            items.append(item)
        }
        CSSearchableIndex.default().indexSearchableItems(items)
    }

    static func removeAll() {
        CSSearchableIndex.default().deleteAllSearchableItems()
    }
}
