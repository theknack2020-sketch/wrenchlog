import Foundation

// MARK: - VIN Decode Result

/// Decoded vehicle information from NHTSA VIN decoder API.
struct VINDecodeResult: Sendable, Equatable {
    let make: String
    let model: String
    let year: Int
    let bodyClass: String
    let engineInfo: String
    let fuelType: String
    let doors: String
    let driveType: String
    let plantInfo: String
    let errorCode: String
    let errorText: String

    /// Whether the decode returned a valid result (errorCode "0" means success).
    var isValid: Bool { errorCode == "0" }
}

// MARK: - Recall Info

/// A single NHTSA safety recall record.
struct RecallInfo: Identifiable, Sendable, Equatable {
    let id: String
    let campaignNumber: String
    let component: String
    let summary: String
    let consequence: String
    let remedy: String
    let reportReceivedDate: String
}

// MARK: - NHTSA Errors

/// Errors specific to NHTSA API interactions.
enum NHTSAError: LocalizedError, Sendable {
    case invalidVIN
    case networkError(underlying: String)
    case decodingError
    case vinNotFound(errorText: String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidVIN:
            "That doesn't look like a valid VIN. Check for 17 alphanumeric characters (no I, O, or Q)."
        case .networkError(let detail):
            "Couldn't reach NHTSA. \(detail)"
        case .decodingError:
            "Received an unexpected response. Try again in a moment."
        case .vinNotFound(let text):
            "VIN lookup failed: \(text)"
        case .timeout:
            "The request took too long. Check your connection and try again."
        }
    }
}

// MARK: - NHTSA Service

/// Singleton service for NHTSA VIN decoding and recall lookups.
/// Uses URLSession with no third-party dependencies.
@MainActor
final class NHTSAService: Sendable {
    static let shared = NHTSAService()

    /// In-memory cache for decoded VINs to avoid redundant network calls.
    private var vinCache: [String: VINDecodeResult] = [:]

    private let session: URLSession
    private static let requestTimeout: TimeInterval = 15

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Self.requestTimeout
        config.timeoutIntervalForResource = Self.requestTimeout
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    // MARK: - VIN Validation

    /// Validates a VIN string: 17 alphanumeric characters, excluding I, O, Q.
    func isValidVIN(_ vin: String) -> Bool {
        let trimmed = vin.trimmingCharacters(in: .whitespaces).uppercased()
        guard trimmed.count == 17 else { return false }
        let allowed = CharacterSet.alphanumerics.subtracting(CharacterSet(charactersIn: "IOQioq"))
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    // MARK: - VIN Decode

    /// Decodes a VIN using the NHTSA vPIC extended decode API.
    /// Results are cached in memory for the session lifetime.
    func decodeVIN(_ vin: String) async throws -> VINDecodeResult {
        let normalizedVIN = vin.trimmingCharacters(in: .whitespaces).uppercased()

        guard isValidVIN(normalizedVIN) else {
            throw NHTSAError.invalidVIN
        }

        // Return cached result if available
        if let cached = vinCache[normalizedVIN] {
            return cached
        }

        let urlString = "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValuesExtended/\(normalizedVIN)?format=json"
        guard let url = URL(string: urlString) else {
            throw NHTSAError.networkError(underlying: "Invalid URL for VIN decode.")
        }

        let data: Data
        do {
            let (responseData, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NHTSAError.networkError(underlying: "Server returned an error. Try again.")
            }
            data = responseData
        } catch is NHTSAError {
            throw NHTSAError.timeout
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw NHTSAError.timeout
        } catch let urlError as URLError {
            throw NHTSAError.networkError(underlying: urlError.localizedDescription)
        } catch {
            throw NHTSAError.networkError(underlying: error.localizedDescription)
        }

        let result = try parseVINDecodeResponse(data)

        if result.isValid {
            vinCache[normalizedVIN] = result
        }

        return result
    }

    // MARK: - Recall Check

    /// Fetches open recalls for a vehicle by make, model, and year.
    /// Returns results sorted by report date descending.
    func fetchRecalls(make: String, model: String, year: Int) async throws -> [RecallInfo] {
        let encodedMake = make.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? make
        let encodedModel = model.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? model
        let urlString = "https://api.nhtsa.gov/recalls/recallsByVehicle?make=\(encodedMake)&model=\(encodedModel)&modelYear=\(year)"

        guard let url = URL(string: urlString) else {
            throw NHTSAError.networkError(underlying: "Invalid URL for recall lookup.")
        }

        let data: Data
        do {
            let (responseData, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NHTSAError.networkError(underlying: "Server returned an error. Try again.")
            }
            data = responseData
        } catch is NHTSAError {
            throw NHTSAError.timeout
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw NHTSAError.timeout
        } catch let urlError as URLError {
            throw NHTSAError.networkError(underlying: urlError.localizedDescription)
        } catch {
            throw NHTSAError.networkError(underlying: error.localizedDescription)
        }

        return try parseRecallResponse(data)
    }

    // MARK: - JSON Parsing

    private func parseVINDecodeResponse(_ data: Data) throws -> VINDecodeResult {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["Results"] as? [[String: Any]],
              let first = results.first else {
            throw NHTSAError.decodingError
        }

        let errorCode = stringValue(first, "ErrorCode")
        let errorText = stringValue(first, "ErrorText")

        // ErrorCode "0" = clean decode. Anything with digits only but != "0" is a partial/failed decode.
        let cleanedErrorCode = errorCode.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? errorCode
        if cleanedErrorCode != "0" && !cleanedErrorCode.isEmpty {
            // Check if there's still usable data (make + model present)
            let make = stringValue(first, "Make")
            let model = stringValue(first, "Model")
            if make.isEmpty && model.isEmpty {
                throw NHTSAError.vinNotFound(errorText: errorText.isEmpty ? "No vehicle data found for this VIN." : errorText)
            }
        }

        let yearString = stringValue(first, "ModelYear")
        let year = Int(yearString) ?? 0

        return VINDecodeResult(
            make: stringValue(first, "Make"),
            model: stringValue(first, "Model"),
            year: year,
            bodyClass: stringValue(first, "BodyClass"),
            engineInfo: buildEngineInfo(first),
            fuelType: stringValue(first, "FuelTypePrimary"),
            doors: stringValue(first, "Doors"),
            driveType: stringValue(first, "DriveType"),
            plantInfo: buildPlantInfo(first),
            errorCode: cleanedErrorCode,
            errorText: errorText
        )
    }

    private func parseRecallResponse(_ data: Data) throws -> [RecallInfo] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            throw NHTSAError.decodingError
        }

        let recalls = results.compactMap { item -> RecallInfo? in
            let campaignNumber = stringValue(item, "NHTSACampaignNumber")
            guard !campaignNumber.isEmpty else { return nil }
            return RecallInfo(
                id: campaignNumber,
                campaignNumber: campaignNumber,
                component: stringValue(item, "Component"),
                summary: stringValue(item, "Summary"),
                consequence: stringValue(item, "Consequence"),
                remedy: stringValue(item, "Remedy"),
                reportReceivedDate: stringValue(item, "ReportReceivedDate")
            )
        }

        // Sort by date descending (format: "DD/MM/YYYY" from NHTSA)
        return recalls.sorted { lhs, rhs in
            parseNHTSADate(lhs.reportReceivedDate) > parseNHTSADate(rhs.reportReceivedDate)
        }
    }

    // MARK: - Helpers

    private func stringValue(_ dict: [String: Any], _ key: String) -> String {
        (dict[key] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    private func buildEngineInfo(_ dict: [String: Any]) -> String {
        let displacement = stringValue(dict, "DisplacementL")
        let cylinders = stringValue(dict, "EngineCylinders")
        let config = stringValue(dict, "EngineConfiguration")
        let hp = stringValue(dict, "EngineHP")

        var parts: [String] = []
        if !displacement.isEmpty { parts.append("\(displacement)L") }
        if !cylinders.isEmpty { parts.append("\(cylinders)-cyl") }
        if !config.isEmpty { parts.append(config) }
        if !hp.isEmpty { parts.append("\(hp) HP") }
        return parts.joined(separator: " ")
    }

    private func buildPlantInfo(_ dict: [String: Any]) -> String {
        let city = stringValue(dict, "PlantCity")
        let country = stringValue(dict, "PlantCountry")
        if !city.isEmpty && !country.isEmpty { return "\(city), \(country)" }
        if !country.isEmpty { return country }
        return city
    }

    /// Parses NHTSA date strings ("DD/MM/YYYY") into a comparable Date.
    private func parseNHTSADate(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string) ?? .distantPast
    }
}
