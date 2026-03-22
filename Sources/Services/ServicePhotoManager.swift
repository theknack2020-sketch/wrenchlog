import SwiftUI
import PhotosUI

struct ServicePhotoManager {
    static let shared = ServicePhotoManager()

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "service_photos")
    }

    init() {
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
    }

    func savePhoto(_ data: Data, for recordId: UUID) -> String {
        let fileName = "\(recordId.uuidString)_\(UUID().uuidString.prefix(8)).jpg"
        let url = documentsURL.appending(path: fileName)
        try? data.write(to: url)
        return fileName
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
}
