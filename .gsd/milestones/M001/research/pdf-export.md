# PDF Report Export — Research

## Summary

Three viable approaches exist for generating professional vehicle service history PDFs on iOS 17+: **UIGraphicsPDFRenderer** (programmatic drawing), **ImageRenderer + SwiftUI views** (design in SwiftUI, render to PDF), and a **hybrid** combining both. The recommended approach for WrenchLog is the **hybrid pattern** — design each page section as a SwiftUI view, render via `ImageRenderer` into a `CGContext`-managed multi-page PDF. This gives us SwiftUI's layout power for design iteration while retaining precise control over pagination, metadata, and page composition.

## Why PDF Export Matters for WrenchLog

- **Resale value documentation**: A clean, branded service history PDF is the single most valuable artifact a car owner can produce when selling. Dealers charge for this; we give it for free (or as premium).
- **Privacy differentiator**: Competitors (CARFAX, Drivvo) require cloud accounts. WrenchLog generates the PDF entirely on-device — no data leaves the phone.
- **Premium feature anchor**: ServiceLog charges $24.99/yr or $69.99 lifetime. A polished PDF export is the kind of feature that justifies a price tier.

---

## Approach Comparison

### 1. UIGraphicsPDFRenderer (Programmatic Drawing)

**How it works**: Create a renderer with page bounds, call `pdfData { context in ... }`, draw text/images/shapes using Core Graphics and NSAttributedString within each page.

**Pros**:
- Full control over every pixel — coordinates, fonts, line widths
- Handles multi-page pagination naturally (`context.beginPage()`)
- Lightweight — no SwiftUI view hierarchy needed
- Built-in metadata support via `UIGraphicsPDFRendererFormat.documentInfo`
- PDF text remains selectable/searchable (real text, not rasterized)
- Available since iOS 11

**Cons**:
- Verbose — every element requires manual coordinate math
- No live preview — must export to see changes
- Maintaining alignment between code and visual output is tedious
- Images require manual `UIImage.draw(in:)` placement
- Tables/grids need manual row/column calculation

**Best for**: Simple, text-heavy documents with precise layout needs (invoices, receipts).

**Key pattern**:
```swift
let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4
let format = UIGraphicsPDFRendererFormat()
format.documentInfo = [
    kCGPDFContextTitle as String: "Vehicle Service History",
    kCGPDFContextAuthor as String: "WrenchLog"
]
let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
let data = renderer.pdfData { context in
    context.beginPage()
    // Draw text
    let title = "Service History Report"
    let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 24)
    ]
    title.draw(at: CGPoint(x: 50, y: 50), withAttributes: attrs)
    // Draw image
    if let image = UIImage(named: "vehicle-photo") {
        image.draw(in: CGRect(x: 50, y: 100, width: 200, height: 150))
    }
    // New page
    context.beginPage()
    // ... more content
}
```

### 2. ImageRenderer (SwiftUI View → PDF)

**How it works**: Build a SwiftUI view representing a PDF page, create an `ImageRenderer`, call `render { size, context in ... }` to draw the view into a `CGContext` PDF page.

**Pros**:
- Design pages using SwiftUI — HStack, VStack, Text, Image, Charts all work
- Text and shapes remain vector (not rasterized) — scales beautifully
- Can preview the page layout as a normal SwiftUI view during development
- Much less code than manual drawing
- Available since iOS 16

**Cons**:
- Multi-page requires managing separate renderers or page-sized views
- Must be called on `@MainActor`
- Cannot render UIKit-wrapped views (WKWebView, MKMapView show placeholders)
- Pagination of dynamic content is not automatic — you must split content into page-sized chunks yourself
- `proposedSize` must be set explicitly for consistent page dimensions

**Best for**: Visually rich pages where design iteration speed matters.

**Key pattern**:
```swift
@MainActor
func renderPDF(pages: [AnyView]) -> URL {
    let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
    let url = URL.documentsDirectory.appending(path: "service-history.pdf")
    
    guard let pdf = CGContext(url as CFURL, mediaBox: &pageRect, nil) else {
        return url
    }
    
    for page in pages {
        pdf.beginPDFPage(nil)
        let renderer = ImageRenderer(content:
            page.frame(width: 612, height: 792)
        )
        renderer.render { size, context in
            context(pdf)
        }
        pdf.endPDFPage()
    }
    
    pdf.closePDF()
    return url
}
```

### 3. PDFKit (PDFDocument / PDFPage)

**How it works**: `PDFDocument` and `PDFPage` from the PDFKit framework. Primarily for **viewing and manipulating** existing PDFs — not for creation from scratch.

**Pros**:
- Great for displaying the generated PDF in-app (`PDFView`)
- Can insert/remove/reorder pages from existing PDFs
- Annotation support (text, ink, highlight)
- Password protection via `write(to:withOptions:)`

**Cons**:
- Cannot create a PDF from scratch — needs Core Graphics for initial creation
- Not a generation tool, but a manipulation/display tool

**Best for**: Displaying the final PDF, merging documents, adding annotations post-generation.

**Key pattern (display)**:
```swift
struct PDFPreviewView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {}
}
```

---

## Recommended: Hybrid Approach

Combine **ImageRenderer** for page design with **CGContext** for multi-page orchestration and **PDFKit** for in-app preview.

### Architecture

```
┌─────────────────────────────────────────────┐
│             PDFReportGenerator               │
│  @MainActor class                            │
├─────────────────────────────────────────────┤
│  Input: Vehicle, [ServiceRecord], Settings   │
│  Output: URL (saved PDF file)                │
├─────────────────────────────────────────────┤
│  Pages:                                      │
│   1. CoverPageView (SwiftUI)                 │
│   2. ServiceTimelineView (SwiftUI)           │
│   3. CostSummaryView (SwiftUI)               │
│   4. ReceiptThumbnailsView (SwiftUI)         │
│                                              │
│  Orchestrator:                               │
│   CGContext manages page sequence             │
│   ImageRenderer renders each view            │
│   PDFKit wraps for preview/share             │
└─────────────────────────────────────────────┘
```

### Implementation Pattern

```swift
import SwiftUI
import PDFKit

@MainActor
final class PDFReportGenerator {
    
    // MARK: - Page Dimensions
    enum PageSize {
        case a4, letter
        
        var rect: CGRect {
            switch self {
            case .a4:     return CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
            case .letter: return CGRect(x: 0, y: 0, width: 612, height: 792)
            }
        }
    }
    
    // MARK: - Generate
    func generate(
        vehicle: Vehicle,
        services: [ServiceRecord],
        receipts: [UIImage],
        pageSize: PageSize = .a4
    ) -> URL {
        let rect = pageSize.rect
        let url = Self.outputURL(for: vehicle)
        
        var mediaBox = rect
        guard let pdf = CGContext(url as CFURL, mediaBox: &mediaBox, [
            kCGPDFContextTitle as String: "Service History — \(vehicle.displayName)",
            kCGPDFContextAuthor as String: "WrenchLog",
            kCGPDFContextCreator as String: "WrenchLog iOS"
        ] as CFDictionary) else {
            return url
        }
        
        // Page 1: Cover
        renderPage(pdf: pdf, rect: rect) {
            CoverPageView(vehicle: vehicle, serviceCount: services.count)
        }
        
        // Pages 2+: Service Timeline (paginated)
        let timelinePages = paginateServices(services, pageHeight: rect.height)
        for page in timelinePages {
            renderPage(pdf: pdf, rect: rect) {
                ServiceTimelinePageView(services: page, pageSize: rect.size)
            }
        }
        
        // Cost Summary
        renderPage(pdf: pdf, rect: rect) {
            CostSummaryView(services: services, pageSize: rect.size)
        }
        
        // Receipt Thumbnails (grid, paginated)
        if !receipts.isEmpty {
            let receiptPages = paginateReceipts(receipts, pageSize: rect.size)
            for page in receiptPages {
                renderPage(pdf: pdf, rect: rect) {
                    ReceiptGridView(images: page, pageSize: rect.size)
                }
            }
        }
        
        pdf.closePDF()
        return url
    }
    
    // MARK: - Render a single SwiftUI view as a PDF page
    private func renderPage<V: View>(
        pdf: CGContext,
        rect: CGRect,
        @ViewBuilder content: () -> V
    ) {
        pdf.beginPDFPage(nil)
        let renderer = ImageRenderer(content:
            content()
                .frame(width: rect.width, height: rect.height)
        )
        renderer.scale = 2.0  // Retina quality
        renderer.render { size, draw in
            draw(pdf)
        }
        pdf.endPDFPage()
    }
    
    // MARK: - Pagination helpers
    private func paginateServices(
        _ services: [ServiceRecord],
        pageHeight: CGFloat
    ) -> [[ServiceRecord]] {
        // Estimate ~80pt per service row, ~60pt header/footer margin
        let usableHeight = pageHeight - 120
        let rowHeight: CGFloat = 80
        let perPage = max(1, Int(usableHeight / rowHeight))
        return stride(from: 0, to: services.count, by: perPage).map {
            Array(services[$0..<min($0 + perPage, services.count)])
        }
    }
    
    private func paginateReceipts(
        _ receipts: [UIImage],
        pageSize: CGSize
    ) -> [[UIImage]] {
        // 2x3 grid = 6 per page
        let perPage = 6
        return stride(from: 0, to: receipts.count, by: perPage).map {
            Array(receipts[$0..<min($0 + perPage, receipts.count)])
        }
    }
    
    // MARK: - File URL
    private static func outputURL(for vehicle: Vehicle) -> URL {
        let name = vehicle.displayName
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        let dateStr = ISO8601DateFormatter().string(from: Date())
            .prefix(10)
        return FileManager.default.temporaryDirectory
            .appending(path: "wrenchlog-\(name)-\(dateStr).pdf")
    }
}
```

### SwiftUI Page Views

```swift
// MARK: - Cover Page
struct CoverPageView: View {
    let vehicle: Vehicle
    let serviceCount: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 120)
            
            // App branding
            Image("wrenchlog-logo")
                .resizable()
                .frame(width: 80, height: 80)
            
            Text("Vehicle Service History")
                .font(.system(size: 28, weight: .bold))
                .padding(.top, 24)
            
            // Vehicle info card
            VStack(spacing: 12) {
                Text(vehicle.displayName)
                    .font(.system(size: 22, weight: .semibold))
                
                if let vin = vehicle.vin {
                    Text("VIN: \(vin)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 40) {
                    LabeledValue(label: "Year", value: "\(vehicle.year)")
                    LabeledValue(label: "Records", value: "\(serviceCount)")
                    if let mileage = vehicle.currentMileage {
                        LabeledValue(label: "Mileage", 
                                   value: "\(mileage.formatted()) mi")
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.08))
            )
            .padding(.top, 40)
            
            Spacer()
            
            // Footer
            VStack(spacing: 4) {
                Text("Generated by WrenchLog")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(Date(), style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 50)
    }
}

// MARK: - Service Timeline Row
struct ServiceTimelinePageView: View {
    let services: [ServiceRecord]
    let pageSize: CGSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Service Timeline")
                .font(.system(size: 18, weight: .bold))
                .padding(.bottom, 16)
            
            // Table header
            HStack {
                Text("Date").frame(width: 80, alignment: .leading)
                Text("Service").frame(maxWidth: .infinity, alignment: .leading)
                Text("Mileage").frame(width: 70, alignment: .trailing)
                Text("Cost").frame(width: 70, alignment: .trailing)
            }
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)
            
            Divider()
            
            // Rows
            ForEach(services) { service in
                HStack {
                    Text(service.date, format: .dateTime.month(.abbreviated).day().year())
                        .frame(width: 80, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.title)
                            .font(.system(size: 11, weight: .medium))
                        if let notes = service.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(service.mileage?.formatted() ?? "—")
                        .frame(width: 70, alignment: .trailing)
                    
                    Text(service.cost, format: .currency(code: "USD"))
                        .frame(width: 70, alignment: .trailing)
                }
                .font(.system(size: 10))
                .padding(.vertical, 8)
                
                Divider()
            }
            
            Spacer()
        }
        .padding(50)
    }
}

// MARK: - Cost Summary
struct CostSummaryView: View {
    let services: [ServiceRecord]
    let pageSize: CGSize
    
    var totalCost: Decimal {
        services.reduce(0) { $0 + $1.cost }
    }
    
    var costByCategory: [(String, Decimal)] {
        Dictionary(grouping: services, by: { $0.category.rawValue })
            .mapValues { $0.reduce(0) { $0 + $1.cost } }
            .sorted { $0.value > $1.value }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Cost Summary")
                .font(.system(size: 18, weight: .bold))
            
            // Total
            HStack {
                Text("Total Maintenance Cost")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(totalCost, format: .currency(code: "USD"))
                    .font(.system(size: 20, weight: .bold))
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(.blue.opacity(0.08)))
            
            // By category
            Text("Breakdown by Category")
                .font(.system(size: 13, weight: .semibold))
            
            ForEach(costByCategory, id: \.0) { category, amount in
                HStack {
                    Circle()
                        .fill(colorForCategory(category))
                        .frame(width: 8, height: 8)
                    Text(category)
                        .font(.system(size: 11))
                    Spacer()
                    Text(amount, format: .currency(code: "USD"))
                        .font(.system(size: 11, weight: .medium))
                }
            }
            
            Spacer()
        }
        .padding(50)
    }
}

// MARK: - Receipt Thumbnails Grid
struct ReceiptGridView: View {
    let images: [UIImage]
    let pageSize: CGSize
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Attached Receipts")
                .font(.system(size: 18, weight: .bold))
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.gray.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
            
            Spacer()
        }
        .padding(50)
    }
}
```

### Sharing & Preview Integration

```swift
// Share via ShareLink (iOS 16+)
ShareLink(
    item: pdfURL,
    preview: SharePreview("Service History", image: Image("wrenchlog-icon"))
)

// Preview in-app via PDFKit
struct PDFPreviewSheet: View {
    let url: URL
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            PDFPreviewView(url: url)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: url)
                    }
                }
                .navigationTitle("Service History")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PDFPreviewView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(url: url)
        return view
    }
    
    func updateUIView(_ view: PDFView, context: Context) {
        view.document = PDFDocument(url: url)
    }
}
```

---

## Key Technical Considerations

### Pagination Strategy
- `UIGraphicsPDFRenderer` pagination: Track `currentY`, call `context.beginPage()` when content would overflow.
- `ImageRenderer` pagination: Pre-split data into page-sized arrays. Each array renders as one page-sized SwiftUI view. This is simpler and more maintainable.

### @MainActor Requirement
`ImageRenderer` must run on the main thread. Mark generation functions `@MainActor`. For large reports, consider generating off-screen with `Task { @MainActor in ... }` to avoid blocking UI.

### Image Handling
- Receipt thumbnails: Resize to max 300x400 before embedding to keep PDF file size manageable.
- Vehicle photo on cover: Compress to JPEG 0.7 quality.
- Target: Full report with 6 receipts should stay under 5MB.

### PDF Metadata
```swift
let metadata: [String: Any] = [
    kCGPDFContextTitle as String: "Service History — 2020 Toyota Camry",
    kCGPDFContextAuthor as String: "WrenchLog",
    kCGPDFContextCreator as String: "WrenchLog iOS v1.0",
    kCGPDFContextSubject as String: "Vehicle maintenance documentation"
]
```

### Rendering Quality
Set `renderer.scale = 2.0` for retina-quality output. Default scale of 1.0 produces visibly lower quality text and images in the PDF.

### Localization
- Use `Locale.current` for currency formatting in cost summary
- Support both US Letter (612×792) and A4 (595×842) based on user locale
- Date formatting should follow user's regional settings

---

## PDF Document Structure for WrenchLog

```
Page 1:  Cover Page
         - WrenchLog branding
         - Vehicle: Year Make Model
         - VIN (if available)
         - Current mileage
         - Total service records count
         - Report generation date

Page 2+: Service Timeline
         - Chronological table: Date | Service | Mileage | Cost
         - Category icons/badges
         - Notes per service (truncated)
         - ~8-10 records per page

Page N:  Cost Summary
         - Total spend
         - Breakdown by category (pie chart or bar list)
         - Average cost per service
         - Cost per mile (if mileage tracked)

Page N+: Receipt Attachments
         - 2×3 grid of receipt thumbnails
         - Each thumbnail labeled with date + service name
```

---

## Implementation Priority

1. **Phase 1 (MVP)**: Cover page + service timeline table (UIGraphicsPDFRenderer, no SwiftUI dependency for initial speed)
2. **Phase 2**: Migrate to hybrid ImageRenderer approach, add cost summary page
3. **Phase 3**: Receipt thumbnails, in-app preview, ShareLink integration
4. **Phase 4**: PDF password protection, locale-aware paper size, vehicle photo on cover

---

## Sources

1. Hacking with Swift — UIGraphicsPDFRenderer: https://www.hackingwithswift.com/example-code/uikit/how-to-render-pdfs-using-uigraphicspdfrenderer
2. Hacking with Swift — SwiftUI view to PDF: https://www.hackingwithswift.com/quick-start/swiftui/how-to-render-a-swiftui-view-to-a-pdf
3. Kodeco — Creating a PDF in Swift with PDFKit: https://www.kodeco.com/4023941-creating-a-pdf-in-swift-with-pdfkit
4. Eden Momchilov — SwiftUI PDF with ImageRenderer: https://medium.com/@edenmomchilov/create-and-share-a-swiftui-generated-pdf-using-imagerenderer-549b6422d078
5. Jakir Hossain — Generate PDF using PDFKit in SwiftUI: https://medium.com/@jakir/generate-pdf-using-pdfkit-in-swiftui-31160d8a1182
6. SwiftUI Lab — SwiftUI Renderers and Their Tricks: https://swiftui-lab.com/swiftui-renders/
7. Swift with Majid — ImageRenderer in SwiftUI: https://swiftwithmajid.com/2023/04/18/imagerenderer-in-swiftui/
8. AppCoda — SwiftUI ImageRenderer PDF Documents: https://www.appcoda.com/swiftui-imagerenderer-pdf/
9. Apple Developer — UIGraphicsPDFRenderer: https://developer.apple.com/documentation/uikit/uigraphicspdfrenderer
10. Apple Developer — PDFKit: https://developer.apple.com/documentation/pdfkit
11. Nutrient (PSPDFKit) — Creating a PDF in Swift: https://pspdfkit.com/blog/2019/creating-pdf-in-swift/
12. DEV Community — iOS PDFKit creating PDF document: https://dev.to/artem_poluektov/ios-pdfkit-creating-pdf-document-in-swift-insertingdeleting-pages-4cdj
13. HC Lin — Multiple Page PDF Export: https://medium.com/@hsuanchunlin1983/multiple-page-pdf-export-from-text-in-swift-c4db8b1ced63
