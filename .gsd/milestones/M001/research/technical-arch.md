# Technical Architecture Research — WrenchLog

## Summary

SwiftData + SwiftUI provides a solid foundation for WrenchLog's data model, photo storage, PDF generation, and reminder system. The key patterns are: `@Model` with `@Relationship(deleteRule: .cascade)` for one-to-many hierarchies, `@Attribute(.externalStorage)` for photo data, `ImageRenderer` for PDF export, `UNUserNotificationCenter` for local notification reminders, and custom `ScrollView`-based timeline views for service history. No third-party dependencies required.

---

## 1. SwiftData Models

### 1.1 Vehicle (root entity)

```swift
@Model
final class Vehicle {
    var id: UUID
    var make: String
    var model: String
    var year: Int
    var nickname: String?
    var licensePlate: String?
    var vin: String?
    var currentMileage: Int  // updated when user logs service or fuel
    var unitSystem: UnitSystem  // .imperial or .metric
    @Attribute(.externalStorage) var photo: Data?
    var createdAt: Date
    var updatedAt: Date

    // One-to-many relationships — cascade delete
    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.vehicle)
    var serviceRecords: [ServiceRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \FuelLog.vehicle)
    var fuelLogs: [FuelLog] = []

    @Relationship(deleteRule: .cascade, inverse: \Reminder.vehicle)
    var reminders: [Reminder] = []
}
```

**Key decisions:**
- `currentMileage` stored on Vehicle, updated via service/fuel entries. This avoids querying all records to find the latest odometer reading.
- `UnitSystem` is a `Codable` enum stored inline — SwiftData handles enum serialization natively.

### 1.2 ServiceRecord

```swift
@Model
final class ServiceRecord {
    var id: UUID
    var vehicle: Vehicle?  // inverse of Vehicle.serviceRecords
    var serviceType: ServiceType  // enum: oilChange, brakes, tires, battery, etc.
    var customServiceName: String?  // when serviceType == .custom
    var date: Date
    var mileage: Int
    var cost: Decimal  // Decimal for currency precision
    var currency: Currency  // enum: .usd, .eur, .gbp
    var shop: String?
    var notes: String?
    var createdAt: Date

    // Photos stored as separate entities (workaround for .externalStorage array bug)
    @Relationship(deleteRule: .cascade, inverse: \ServicePhoto.serviceRecord)
    var photos: [ServicePhoto] = []
}
```

### 1.3 ServicePhoto (separate entity for photo storage)

```swift
@Model
final class ServicePhoto {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var serviceRecord: ServiceRecord?  // inverse
    var createdAt: Date
}
```

**Why a separate entity instead of `[Data]` on ServiceRecord:**
- `@Attribute(.externalStorage)` on a single `Data` property works correctly — SwiftData stores only a ~38-byte reference in SQLite and puts the binary in an adjacent file.
- On arrays of `Data`, `.externalStorage` does NOT work properly — the entire array gets serialized as a single blob, defeating the purpose. Multiple developers have confirmed this: arrays of images stored inline can grow to 8+ MB in the SQLite blob.
- The workaround is a separate `ServicePhoto` entity with a one-to-many relationship. Each photo gets its own `.externalStorage`-backed `Data` property, keeping the main database lean.

### 1.4 FuelLog

```swift
@Model
final class FuelLog {
    var id: UUID
    var vehicle: Vehicle?
    var date: Date
    var mileage: Int
    var fuelAmount: Double  // gallons or liters
    var fuelUnit: FuelUnit  // .gallons, .liters
    var pricePerUnit: Decimal
    var totalCost: Decimal
    var currency: Currency
    var isFillUp: Bool  // full tank fill — needed for MPG calculation
    var notes: String?
    var createdAt: Date

    // Computed: cost per mile/km (not stored — derived from mileage delta)
}
```

**MPG/L-per-100km calculation:** Requires two consecutive fill-up entries. Algorithm: `(current.mileage - previous.mileage) / current.fuelAmount`. Only valid when `isFillUp == true` for both entries. Store the computed value as a transient property, not persisted.

### 1.5 Reminder

```swift
@Model
final class Reminder {
    var id: UUID
    var vehicle: Vehicle?
    var serviceType: ServiceType
    var customServiceName: String?
    var reminderType: ReminderType  // .mileage, .date, .both
    var targetMileage: Int?
    var targetDate: Date?
    var recurringMileageInterval: Int?  // e.g., every 5000 miles
    var recurringDateInterval: Int?  // in days
    var isCompleted: Bool
    var notificationID: String?  // UNNotification identifier for cancellation
    var createdAt: Date
}
```

### 1.6 Supporting Enums

```swift
enum ServiceType: String, Codable, CaseIterable {
    case oilChange, brakes, tires, battery, airFilter, transmission
    case coolant, sparkPlugs, wiperBlades, alignment, inspection
    case custom

    var displayName: String { /* localized string */ }
    var defaultMileageInterval: Int? { /* e.g., oilChange -> 5000 */ }
    var defaultDateInterval: Int? { /* in days, e.g., oilChange -> 180 */ }
}

enum UnitSystem: String, Codable {
    case imperial  // miles, gallons, USD
    case metric    // km, liters, EUR
}

enum FuelUnit: String, Codable {
    case gallons, liters
}

enum Currency: String, Codable {
    case usd, eur, gbp
    var symbol: String { /* $, €, £ */ }
}

enum ReminderType: String, Codable {
    case mileage, date, both
}
```

---

## 2. Relationship Patterns

### One-to-Many with Cascade Delete

SwiftData uses `@Relationship(deleteRule: .cascade, inverse:)` to define parent-child relationships. When a `Vehicle` is deleted, all its `ServiceRecord`s, `FuelLog`s, and `Reminder`s are automatically deleted.

**Pattern from Apple docs:**
```swift
@Relationship(deleteRule: .cascade, inverse: \Animal.category)
var animals = [Animal]()
```

The `inverse` parameter forms a bidirectional link. The child entity declares the parent as an optional property (`var vehicle: Vehicle?`), and SwiftData manages both sides automatically.

### Query Patterns

```swift
// In a view — all service records for a vehicle, sorted by date
@Query(sort: \ServiceRecord.date, order: .reverse)
var allRecords: [ServiceRecord]

// Filtered by vehicle (use predicate)
init(vehicle: Vehicle) {
    let vehicleID = vehicle.id
    _records = Query(
        filter: #Predicate<ServiceRecord> { $0.vehicle?.id == vehicleID },
        sort: \ServiceRecord.date,
        order: .reverse
    )
}
```

### ModelContainer Setup

```swift
@main
struct WrenchLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Vehicle.self,
            ServiceRecord.self,
            ServicePhoto.self,
            FuelLog.self,
            Reminder.self
        ])
    }
}
```

SwiftData infers the full schema graph from relationships, so technically passing just `Vehicle.self` would work — but being explicit is safer for migration planning.

---

## 3. Photo Attachments

### Strategy: `@Attribute(.externalStorage)` + Separate Entity

**How `.externalStorage` works:**
- SwiftData stores the `Data` in a file adjacent to the SQLite database, keeping only a filename reference in the main store.
- For single `Data` properties, this works transparently — ~38 bytes in SQLite per image.
- For `Data` arrays, it does NOT work (known issue) — the full array serializes into the blob column.

**Solution: `ServicePhoto` entity**
Each photo is a separate `@Model` with its own `@Attribute(.externalStorage) var imageData: Data`. This ensures every image is stored externally and the ServiceRecord table stays lean.

### Image Pipeline

```swift
// 1. PhotosPicker selection
.photosPicker(
    isPresented: $showPhotoPicker,
    selection: $selectedItems,
    maxSelectionCount: 5,
    matching: .images
)

// 2. Convert to Data with downsampling
func processPhoto(_ item: PhotosPickerItem) async -> Data? {
    guard let data = try? await item.loadTransferable(type: Data.self) else { return nil }
    // Downsample to max 1200px wide for storage efficiency
    return downsample(data: data, maxPixelSize: 1200)
}

// 3. Save as ServicePhoto entity
let photo = ServicePhoto(
    id: UUID(),
    imageData: processedData,
    createdAt: .now
)
serviceRecord.photos.append(photo)
```

### Downsampling (critical for storage)

Raw photos from PhotosPicker can be 4-12 MB each. Downsampling to 1200px using `CGImageSource` reduces this to ~200-400 KB with no visible quality loss for receipt/photo documentation.

```swift
func downsample(data: Data, maxPixelSize: CGFloat) -> Data? {
    let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
    guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }
    let downsampleOptions: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true
    ]
    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else { return nil }
    let uiImage = UIImage(cgImage: cgImage)
    return uiImage.jpegData(compressionQuality: 0.8)
}
```

### Display Pattern

```swift
if let data = photo.imageData, let uiImage = UIImage(data: data) {
    Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
}
```

---

## 4. PDF Report Generation

### Using `ImageRenderer`

SwiftUI's `ImageRenderer` (iOS 16+) can render any SwiftUI view into a PDF context. The resulting PDF maintains resolution-independence for text, shapes, and SF Symbols.

### Architecture

```
ServiceReportView (SwiftUI)  →  ImageRenderer  →  CGContext (PDF)  →  Data  →  ShareLink
```

### Report View (designed for print)

```swift
struct ServiceReportView: View {
    let vehicle: Vehicle
    let records: [ServiceRecord]
    let dateRange: ClosedRange<Date>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Service Report")
                    .font(.title.bold())
                Spacer()
                Text("WrenchLog")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Vehicle info
            VehicleHeaderSection(vehicle: vehicle)

            // Summary stats
            CostSummarySection(records: records)

            // Service records table
            ForEach(records) { record in
                ServiceRecordRow(record: record)
            }
        }
        .padding(40)  // print margins
        .frame(width: 612)  // US Letter width in points
    }
}
```

### PDF Generation

```swift
func generatePDF(vehicle: Vehicle, records: [ServiceRecord]) -> URL? {
    let reportView = ServiceReportView(vehicle: vehicle, records: records, dateRange: range)
    let renderer = ImageRenderer(content: reportView)
    renderer.scale = 2.0  // retina quality

    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
        "WrenchLog-\(vehicle.make)-\(vehicle.model)-Report.pdf"
    )

    renderer.render { size, renderer in
        // US Letter: 612 x 792 points
        var mediaBox = CGRect(origin: .zero, size: CGSize(width: 612, height: max(size.height, 792)))

        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }

        pdfContext.beginPDFPage(nil)
        renderer(pdfContext)
        pdfContext.endPDFPage()
        pdfContext.closePDF()
    }

    return url
}
```

### Multi-page PDFs

For reports longer than one page, the single-render approach won't paginate automatically. Two options:

1. **Split the content:** Calculate content height, break into page-sized chunks, render each as a separate PDF page.
2. **Use UIKit's `UIPrintPageRenderer`:** More control over pagination but requires bridging from SwiftUI.

Recommended: Start with single-page summary reports. For detailed multi-page reports, pre-calculate page breaks based on record count (~15 records per page at standard font sizes).

### Sharing

```swift
ShareLink(item: pdfURL) {
    Label("Export PDF", systemImage: "square.and.arrow.up")
}
```

---

## 5. Mileage-Based Reminders

### Challenge

iOS local notifications (`UNUserNotificationCenter`) support time-based triggers (`UNTimeIntervalNotificationTrigger`, `UNCalendarNotificationTrigger`) but NOT mileage-based triggers. There's no system API for "notify when odometer reaches X."

### Strategy: Hybrid Approach

**Date-based reminders:** Straightforward — schedule with `UNCalendarNotificationTrigger`.

**Mileage-based reminders:** Check on every mileage-updating event (service log, fuel log) and trigger notification if threshold crossed.

```swift
class ReminderManager {
    static let shared = ReminderManager()
    private let center = UNUserNotificationCenter.current()

    // Called after every mileage update
    func checkMileageReminders(for vehicle: Vehicle, context: ModelContext) {
        let currentMileage = vehicle.currentMileage
        let pendingReminders = vehicle.reminders.filter {
            !$0.isCompleted &&
            ($0.reminderType == .mileage || $0.reminderType == .both) &&
            $0.targetMileage != nil &&
            currentMileage >= ($0.targetMileage! - 500)  // warn 500 mi/km early
        }

        for reminder in pendingReminders {
            if currentMileage >= reminder.targetMileage! {
                scheduleImmediateNotification(for: reminder, vehicle: vehicle)
            } else {
                // Within warning zone — schedule a "coming up" notification
                scheduleWarningNotification(for: reminder, vehicle: vehicle, remaining: reminder.targetMileage! - currentMileage)
            }
        }
    }

    // Date-based reminder
    func scheduleDateReminder(_ reminder: Reminder, vehicle: Vehicle) {
        guard let targetDate = reminder.targetDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "Service Due — \(vehicle.nickname ?? vehicle.model)"
        content.body = "\(reminder.serviceType.displayName) is due"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request)
        reminder.notificationID = reminder.id.uuidString
    }

    // Recurring reminders: after completing a service, auto-create next reminder
    func createNextRecurring(from completed: Reminder, currentMileage: Int, vehicle: Vehicle, context: ModelContext) {
        let next = Reminder(
            id: UUID(),
            serviceType: completed.serviceType,
            reminderType: completed.reminderType,
            targetMileage: completed.recurringMileageInterval.map { currentMileage + $0 },
            targetDate: completed.recurringDateInterval.map {
                Calendar.current.date(byAdding: .day, value: $0, to: .now)!
            },
            recurringMileageInterval: completed.recurringMileageInterval,
            recurringDateInterval: completed.recurringDateInterval,
            isCompleted: false,
            createdAt: .now
        )
        vehicle.reminders.append(next)
    }
}
```

### Permission Flow

```swift
func requestNotificationPermission() async -> Bool {
    let center = UNUserNotificationCenter.current()
    do {
        return try await center.requestAuthorization(options: [.alert, .badge, .sound])
    } catch {
        return false
    }
}
```

### Smart Defaults (Preloaded Service Intervals)

```swift
// R011: Preloaded common service types
static let defaultIntervals: [ServiceType: (miles: Int?, days: Int?)] = [
    .oilChange:    (miles: 5000,  days: 180),
    .tires:        (miles: 40000, days: 1460),  // ~4 years
    .brakes:       (miles: 30000, days: 1095),  // ~3 years
    .airFilter:    (miles: 15000, days: 365),
    .transmission: (miles: 60000, days: 1825),  // ~5 years
    .coolant:      (miles: 30000, days: 730),   // ~2 years
    .sparkPlugs:   (miles: 30000, days: 1095),
    .wiperBlades:  (miles: nil,   days: 365),
    .battery:      (miles: nil,   days: 1095),
    .inspection:   (miles: nil,   days: 365),
]
```

---

## 6. Calendar / Timeline Views for Service History

### Approach: Custom ScrollView Timeline (no UICalendarView)

SwiftUI's `TimelineView` is for time-based rendering updates (clocks, animations) — not for displaying a timeline of events. We need a custom vertical timeline.

### Timeline Component

```swift
struct ServiceTimelineView: View {
    let records: [ServiceRecord]

    // Group by month
    private var groupedByMonth: [(String, [ServiceRecord])] {
        let grouped = Dictionary(grouping: records) { record in
            record.date.formatted(.dateTime.year().month())
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedByMonth, id: \.0) { month, monthRecords in
                    // Month header
                    Text(month)
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 24)

                    // Timeline entries
                    ForEach(monthRecords) { record in
                        TimelineEntryView(record: record)
                    }
                }
            }
        }
    }
}

struct TimelineEntryView: View {
    let record: ServiceRecord

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line + dot
            VStack(spacing: 0) {
                Circle()
                    .fill(record.serviceType.color)
                    .frame(width: 12, height: 12)
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 2)
            }
            .frame(width: 12)

            // Content card
            VStack(alignment: .leading, spacing: 4) {
                Text(record.serviceType.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let cost = record.cost {
                    Text(cost, format: .currency(code: record.currency.rawValue))
                        .font(.caption)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
```

### Calendar Heatmap View (optional, v1.1)

For a calendar-style view showing which days had service events, use a pure SwiftUI grid:

```swift
struct CalendarView<DateView: View>: View {
    @Environment(\.calendar) var calendar
    let interval: DateInterval
    let content: (Date) -> DateView

    private var months: [Date] {
        calendar.generateDates(
            inside: interval,
            matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0)
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                ForEach(months, id: \.self) { month in
                    MonthView(month: month, content: content)
                }
            }
        }
    }
}
```

This pattern (from Swift with Majid) builds a vertically scrollable calendar using `DateInterval`, `Calendar.generateDates`, and a `@ViewBuilder` content closure. Each day cell can show a dot for service events.

### Cost Summary Charts

Using Swift Charts (iOS 16+):

```swift
Chart {
    ForEach(monthlyCosts) { item in
        BarMark(
            x: .value("Month", item.month),
            y: .value("Cost", item.total)
        )
        .foregroundStyle(by: .value("Type", item.serviceType.displayName))
    }
}
.chartYAxis {
    AxisMarks(format: .currency(code: "USD"))
}
```

---

## 7. Architecture Summary

### Layer Structure

```
App Layer          WrenchLogApp.swift — ModelContainer setup
├── Views          Tab-based: Vehicles / Timeline / Reminders / Settings
│   ├── Vehicles   VehicleListView → VehicleDetailView → AddServiceSheet
│   ├── Timeline   ServiceTimelineView (grouped by month)
│   ├── Reminders  ReminderListView → AddReminderSheet
│   └── Settings   UnitToggle, Export, About
├── Services       ReminderManager, PDFGenerator, FuelCalculator
└── Models         Vehicle, ServiceRecord, ServicePhoto, FuelLog, Reminder + enums
```

### Key Patterns

| Pattern | Implementation |
|---------|---------------|
| Data persistence | SwiftData `@Model` + `@Query` |
| Relationships | `@Relationship(deleteRule: .cascade, inverse:)` |
| Photo storage | Separate `ServicePhoto` entity with `@Attribute(.externalStorage)` |
| Image pipeline | PhotosPicker → downsample via CGImageSource → JPEG Data → SwiftData |
| PDF export | `ImageRenderer` → `CGContext` PDF → `ShareLink` |
| Date reminders | `UNCalendarNotificationTrigger` |
| Mileage reminders | Check on every mileage update, schedule notification when threshold hit |
| Service timeline | Custom `LazyVStack` with timeline dot/line UI, grouped by month |
| Cost charts | Swift Charts `BarMark` grouped by service type |
| Unit system | `UnitSystem` enum propagated via `@AppStorage` |

### Dependencies

**Zero third-party.** Everything uses Apple frameworks:
- SwiftData (persistence)
- SwiftUI (UI)
- Swift Charts (cost visualization)
- UserNotifications (reminders)
- PhotosUI (image picker)
- CoreGraphics (PDF generation, image downsampling)
- StoreKit 2 (IAP — separate concern)

---

## 8. Known Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| `.externalStorage` array bug | Photos stored inline, bloated DB | Use separate `ServicePhoto` entity |
| SwiftData migration complexity | Schema changes in future versions | Keep models simple, plan `VersionedSchema` from v1 |
| Mileage reminders can't be system-triggered | User must open app to trigger check | Also schedule time-based fallback notifications ("Have you checked your mileage?") |
| PDF pagination for long reports | Content clipped to single page | Pre-calculate page breaks, render multiple pages |
| Large photo libraries | Memory pressure loading many images | Downsample on save, use `LazyVStack` for display, thumbnail cache |

---

## Sources

- [Apple SwiftData Documentation — Relationships & Cascade Delete](https://developer.apple.com/documentation/swiftdata/defining-data-relationships-with-enumerations-and-model-classes)
- [Apple SwiftData — External Storage Attribute](https://developer.apple.com/documentation/swiftdata/schema/attribute/option/externalstorage)
- [Hacking with Swift — SwiftData External File Storage](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-store-swiftdata-attributes-in-an-external-file)
- [Apple Developer Forums — Save Images in SwiftData](https://developer.apple.com/forums/thread/744744)
- [Apple Developer Forums — External Storage Array Bug](https://developer.apple.com/forums/thread/748267)
- [Apple SwiftUI — ImageRenderer PDF Generation](https://developer.apple.com/documentation/swiftui/imagerenderer)
- [Apple SwiftUI — PhotosPicker](https://developer.apple.com/documentation/swiftui/view/photospicker)
- [Hacking with Swift — Scheduling Local Notifications](https://www.hackingwithswift.com/books/ios-swiftui/scheduling-local-notifications)
- [Swift with Majid — Building Calendar in SwiftUI](https://swiftwithmajid.com/2020/05/06/building-calendar-without-uicollectionview-in-swiftui/)
- [Apple SwiftUI — Charts Framework](https://developer.apple.com/documentation/swiftui/food-truck-building-a-swiftui-multiplatform-app)
- [SwiftUI Agent Skill — Performance Patterns](https://github.com/avdlee/swiftui-agent-skill)
- [tanaschita.com — How to Store Images in SwiftData](https://tanaschita.com/20231127-swift-data-images/)
