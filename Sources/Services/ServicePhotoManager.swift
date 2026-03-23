import SwiftUI
import PhotosUI

// MARK: - Photo Save Result

enum PhotoSaveResult {
    case success(fileName: String)
    case failure(reason: String)
}

struct ServicePhotoManager {
    static let shared = ServicePhotoManager()

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "service_photos")
    }

    init() {
        do {
            try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        } catch {
            print("[WrenchLog] Failed to create photos directory: \(error)")
        }
    }

    /// Save a photo with graceful error handling.
    /// Returns .success with the file name, or .failure with a reason.
    func savePhoto(_ data: Data, for recordId: UUID) -> PhotoSaveResult {
        let fileName = "\(recordId.uuidString)_\(UUID().uuidString.prefix(8)).jpg"
        let url = documentsURL.appending(path: fileName)

        // Compress photo to max 500KB
        let dataToWrite: Data
        if let image = UIImage(data: data) {
            let maxSize = 500 * 1024 // 500KB
            var quality: CGFloat = 0.8
            var compressed = image.jpegData(compressionQuality: quality) ?? data

            while compressed.count > maxSize && quality > 0.1 {
                quality -= 0.1
                compressed = image.jpegData(compressionQuality: quality) ?? data
            }
            dataToWrite = compressed
        } else {
            dataToWrite = data
        }

        // Check available disk space
        let requiredSpace = UInt64(dataToWrite.count * 2) // 2x safety margin
        if let availableSpace = availableDiskSpace(), availableSpace < requiredSpace {
            return .failure(reason: "Not enough storage space to save photo.")
        }

        do {
            try dataToWrite.write(to: url, options: .atomic)
            return .success(fileName: fileName)
        } catch {
            print("[WrenchLog] Photo write failed: \(error)")
            return .failure(reason: "Failed to save photo: \(error.localizedDescription)")
        }
    }

    func loadPhoto(named fileName: String) -> UIImage? {
        let url = documentsURL.appending(path: fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deletePhoto(named fileName: String) {
        let url = documentsURL.appending(path: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    func deletePhotos(for fileNames: [String]) {
        fileNames.forEach { deletePhoto(named: $0) }
    }

    // MARK: - Disk Space Check

    private func availableDiskSpace() -> UInt64? {
        let path = NSHomeDirectory()
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path),
              let space = attrs[.systemFreeSize] as? UInt64 else {
            return nil
        }
        return space
    }
}
