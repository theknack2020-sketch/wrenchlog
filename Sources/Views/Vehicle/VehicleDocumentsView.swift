import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import QuickLook

// MARK: - Vehicle Documents View

struct VehicleDocumentsView: View {
    @Bindable var vehicle: Vehicle
    @State private var showAddDocument = false
    @State private var showDeleteConfirm = false
    @State private var documentToDelete: VehicleDocument?
    @State private var previewURL: URL?
    @State private var showPreview = false

    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme

    private let photoManager = VehiclePhotoManager.shared
    private let haptic = HapticManager.shared

    var sortedDocuments: [VehicleDocument] {
        vehicle.safeDocuments.sorted { $0.dateAdded > $1.dateAdded }
    }

    var body: some View {
        List {
            if sortedDocuments.isEmpty {
                Section {
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.1))
                                .frame(width: 100, height: 100)
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(theme.accent)
                                .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5))
                        }
                        .accessibilityHidden(true)
                        VStack(spacing: 8) {
                            Text("No Documents")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                            Text("Store insurance, registration, and receipts here.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Button {
                            showAddDocument = true
                        } label: {
                            Label("Add Document", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(theme.accent)
                        }
                        .pressable()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                // Group by document type
                let grouped = Dictionary(grouping: sortedDocuments, by: { $0.documentType })
                let sortedTypes = grouped.keys.sorted { $0.rawValue < $1.rawValue }

                ForEach(sortedTypes, id: \.self) { type in
                    Section(type.rawValue) {
                        ForEach(grouped[type] ?? []) { doc in
                            documentRow(doc)
                        }
                        .onDelete { indexSet in
                            if let idx = indexSet.first, let docs = grouped[type] {
                                documentToDelete = docs[idx]
                                showDeleteConfirm = true
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddDocument = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.accent)
                }
                .accessibilityIdentifier("documentsAdd")
                .accessibilityLabel("Add document")
            }
        }
        .sheet(isPresented: $showAddDocument) {
            AddDocumentView(vehicle: vehicle)
        }
        .sheet(isPresented: $showPreview) {
            if let url = previewURL {
                DocumentPreviewView(url: url)
            }
        }
        .confirmationDialog("Delete Document?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let doc = documentToDelete {
                    photoManager.deleteDocument(named: doc.fileName)
                    withAnimation { context.delete(doc) }
                    try? context.save()
                    haptic.warning()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let doc = documentToDelete {
                Text("Delete '\(doc.title)'? This cannot be undone.")
            }
        }
    }

    @ViewBuilder
    private func documentRow(_ doc: VehicleDocument) -> some View {
        Button {
            if let url = photoManager.documentURL(named: doc.fileName) {
                previewURL = url
                showPreview = true
            }
        } label: {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(doc.documentType.color.opacity(0.1))
                        .frame(width: 44, height: 44)

                    if photoManager.isPDF(doc.fileName) {
                        Image(systemName: "doc.text.fill")
                            .font(.title3)
                            .foregroundStyle(doc.documentType.color)
                    } else if let img = photoManager.loadDocumentImage(named: doc.fileName) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: doc.documentType.icon)
                            .font(.title3)
                            .foregroundStyle(doc.documentType.color)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(doc.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        Text(doc.dateAdded, format: .dateTime.month(.abbreviated).day().year())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if doc.fileSizeBytes > 0 {
                            Text("· \(formattedFileSize(doc.fileSizeBytes))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    if let expiry = doc.expirationDate {
                        let isExpired = expiry < Date()
                        HStack(spacing: 3) {
                            Image(systemName: isExpired ? "exclamationmark.triangle.fill" : "calendar")
                                .font(.caption2)
                            Text(isExpired ? "Expired" : "Expires \(expiry, format: .dateTime.month(.abbreviated).day().year())")
                                .font(.caption2)
                        }
                        .foregroundStyle(isExpired ? .red : .secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(doc.documentType.rawValue): \(doc.title)")
    }

    private func formattedFileSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return "\(bytes / 1024) KB"
        } else {
            let mb = Double(bytes) / (1024 * 1024)
            return String(format: "%.1f MB", mb)
        }
    }
}

// MARK: - Add Document View

struct AddDocumentView: View {
    let vehicle: Vehicle
    @State private var title = ""
    @State private var documentType: DocumentType = .other
    @State private var notes = ""
    @State private var hasExpiration = false
    @State private var expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: .now) ?? .now

    // Photo picker
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    // File picker
    @State private var showFilePicker = false
    @State private var fileData: Data?
    @State private var fileName = ""

    @State private var sourceChoice: DocumentSource?
    @FocusState private var isFocused: Bool

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    private let photoManager = VehiclePhotoManager.shared

    enum DocumentSource: String, CaseIterable, Identifiable {
        case photo = "Photo"
        case file = "File"
        var id: String { rawValue }
    }

    private var hasFile: Bool {
        photoData != nil || fileData != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Document Type") {
                    Picker("Type", selection: $documentType) {
                        ForEach(DocumentType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .onChange(of: documentType) { _, newType in
                        if title.isEmpty || DocumentType.allCases.contains(where: { $0.rawValue == title }) {
                            title = newType.rawValue
                        }
                    }
                }

                Section("Details") {
                    TextField("Document Title", text: $title)
                        .accessibilityLabel("Document title")

                    TextField("Notes (optional)", text: $notes)
                        .accessibilityLabel("Notes")

                    Toggle("Has Expiration Date", isOn: $hasExpiration)
                    if hasExpiration {
                        DatePicker("Expiration", selection: $expirationDate, displayedComponents: .date)
                    }
                }

                Section("Attach File") {
                    // Photo picker
                    PhotosPicker(selection: $selectedPhoto, matching: .any(of: [.images])) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .foregroundStyle(theme.accent)
                                .frame(width: 28)
                            Text("Choose from Photos")
                                .font(.subheadline)
                            Spacer()
                            if photoData != nil && fileData == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    // File picker
                    Button {
                        showFilePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(theme.accent)
                                .frame(width: 28)
                            Text("Choose File (PDF, Image)")
                                .font(.subheadline)
                            Spacer()
                            if fileData != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    // Preview
                    if let data = fileData ?? photoData, let img = UIImage(data: data) {
                        HStack {
                            Spacer()
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else if fileData != nil {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.title2)
                                .foregroundStyle(theme.accent)
                            Text(fileName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("addDocumentCancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveDocument() }
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty || !hasFile)
                        .accessibilityIdentifier("addDocumentSave")
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        photoData = data
                        fileData = nil
                        fileName = "photo.jpg"
                        if title.isEmpty || DocumentType.allCases.contains(where: { $0.rawValue == title }) {
                            title = documentType.rawValue
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                DocumentPickerView { data, name in
                    fileData = data
                    fileName = name
                    photoData = nil
                    if title.isEmpty || DocumentType.allCases.contains(where: { $0.rawValue == title }) {
                        title = name
                    }
                }
            }
            .onAppear {
                title = documentType.rawValue
            }
        }
    }

    private func saveDocument() {
        let data = fileData ?? photoData
        guard let data else { return }

        let name = fileName.isEmpty ? "document.jpg" : fileName
        guard let (savedName, size) = photoManager.saveDocument(data, originalName: name, vehicleId: vehicle.id) else { return }

        let doc = VehicleDocument(
            title: title.trimmingCharacters(in: .whitespaces),
            fileName: savedName,
            documentType: documentType,
            fileSizeBytes: size,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        doc.expirationDate = hasExpiration ? expirationDate : nil
        doc.vehicle = vehicle

        context.insert(doc)
        try? context.save()
        HapticManager.shared.success()
        SoundManager.playSaveSuccess()
        dismiss()
    }
}

// MARK: - Document Picker (UIKit Bridge)

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPick: (Data, String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .image, .jpeg, .png, .heic]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (Data, String) -> Void
        init(onPick: @escaping (Data, String) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else { return }
            onPick(data, url.lastPathComponent)
        }
    }
}

// MARK: - Document Preview (Quick Look)

struct DocumentPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator { Coordinator(url: url) }

    func makeUIViewController(context: Context) -> UINavigationController {
        let ql = QLPreviewController()
        ql.dataSource = context.coordinator
        return UINavigationController(rootViewController: ql)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as QLPreviewItem
        }
    }
}
