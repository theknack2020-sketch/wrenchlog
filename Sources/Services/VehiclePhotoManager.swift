import UIKit

/// Manages vehicle photos and documents stored in the app's documents directory.
/// Photos are compressed to max 500KB. Documents (PDFs, images) are stored as-is or compressed if images.
struct VehiclePhotoManager {
    static let shared = VehiclePhotoManager()

    private static let maxPhotoBytes = 500 * 1024 // 500KB
    private static let maxPhotoDimension: CGFloat = 1200

    // MARK: - Image Cache

    private nonisolated(unsafe) static let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 20
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        return cache
    }()

    // MARK: - Directories

    private var vehiclePhotosURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "vehicle_photos")
    }

    private var vehicleDocumentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "vehicle_documents")
    }

    init() {
        try? FileManager.default.createDirectory(at: vehiclePhotosURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: vehicleDocumentsURL, withIntermediateDirectories: true)
    }

    // MARK: - Vehicle Photo

    /// Saves a vehicle photo to disk, compressing to max 500KB and resizing if needed.
    /// Returns the filename on success.
    func saveVehiclePhoto(_ data: Data, vehicleId: UUID) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let resized = downsizeIfNeeded(image, maxDimension: Self.maxPhotoDimension)
        guard let compressed = compressToMaxSize(resized, maxBytes: Self.maxPhotoBytes) else { return nil }

        let fileName = "vehicle_\(vehicleId.uuidString).jpg"
        let url = vehiclePhotosURL.appending(path: fileName)
        do {
            try compressed.write(to: url)
            return fileName
        } catch {
            return nil
        }
    }

    /// Loads a vehicle photo by filename. Uses in-memory cache for repeated access.
    func loadVehiclePhoto(named fileName: String) -> UIImage? {
        guard !fileName.isEmpty else { return nil }
        let key = fileName as NSString
        if let cached = Self.imageCache.object(forKey: key) {
            return cached
        }
        let url = vehiclePhotosURL.appending(path: fileName)
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        Self.imageCache.setObject(image, forKey: key, cost: data.count)
        return image
    }

    /// Deletes a vehicle photo by filename and evicts it from cache.
    func deleteVehiclePhoto(named fileName: String) {
        guard !fileName.isEmpty else { return }
        Self.imageCache.removeObject(forKey: fileName as NSString)
        let url = vehiclePhotosURL.appending(path: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Vehicle Documents

    /// Saves a document (PDF or image) to disk. Images are compressed; PDFs stored as-is.
    /// Returns (fileName, fileSizeBytes) on success.
    func saveDocument(_ data: Data, originalName: String, vehicleId: UUID) -> (String, Int)? {
        let ext = (originalName as NSString).pathExtension.lowercased()
        let uniqueId = UUID().uuidString.prefix(8)
        let safeName = sanitizeFileName(originalName)
        let fileName = "doc_\(vehicleId.uuidString.prefix(8))_\(uniqueId)_\(safeName)"
        let url = vehicleDocumentsURL.appending(path: fileName)

        let dataToWrite: Data
        if ["jpg", "jpeg", "png", "heic", "heif"].contains(ext) {
            // Compress images
            if let image = UIImage(data: data) {
                let resized = downsizeIfNeeded(image, maxDimension: Self.maxPhotoDimension)
                dataToWrite = compressToMaxSize(resized, maxBytes: Self.maxPhotoBytes) ?? data
            } else {
                dataToWrite = data
            }
        } else {
            dataToWrite = data
        }

        do {
            try dataToWrite.write(to: url)
            return (fileName, dataToWrite.count)
        } catch {
            return nil
        }
    }

    /// Returns the full URL for a document, for sharing or previewing.
    func documentURL(named fileName: String) -> URL? {
        guard !fileName.isEmpty else { return nil }
        let url = vehicleDocumentsURL.appending(path: fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Loads a document as UIImage if it's an image file. Uses in-memory cache.
    func loadDocumentImage(named fileName: String) -> UIImage? {
        guard let url = documentURL(named: fileName) else { return nil }
        let key = ("doc_" + fileName) as NSString
        if let cached = Self.imageCache.object(forKey: key) {
            return cached
        }
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        Self.imageCache.setObject(image, forKey: key, cost: data.count)
        return image
    }

    /// Deletes a document file from disk.
    func deleteDocument(named fileName: String) {
        guard !fileName.isEmpty else { return }
        let url = vehicleDocumentsURL.appending(path: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    /// Whether a filename looks like a PDF.
    func isPDF(_ fileName: String) -> Bool {
        fileName.lowercased().hasSuffix(".pdf")
    }

    // MARK: - Cache Management

    /// Clears the in-memory image cache. Call on memory warnings or when photos are bulk-deleted.
    func clearCache() {
        Self.imageCache.removeAllObjects()
    }

    // MARK: - Compression Helpers

    /// Downsizes an image if either dimension exceeds maxDimension.
    private func downsizeIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let scale: CGFloat
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Compresses a UIImage to JPEG, iterating quality down until under maxBytes.
    private func compressToMaxSize(_ image: UIImage, maxBytes: Int) -> Data? {
        var quality: CGFloat = 0.8
        var data = image.jpegData(compressionQuality: quality)

        while let d = data, d.count > maxBytes, quality > 0.1 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality)
        }

        return data
    }

    /// Sanitizes a filename for safe filesystem usage.
    private func sanitizeFileName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
        let sanitized = name.unicodeScalars.filter { allowed.contains($0) }.map { Character($0) }
        let result = String(sanitized)
        return result.isEmpty ? "document" : result
    }
}
