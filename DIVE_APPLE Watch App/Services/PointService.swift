import Foundation

class PointService {
    static let shared = PointService()
    private init() {}

    func fetchPoints(lat: Double, lon: Double) async throws -> PointResponse {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            throw URLError(.badURL)
        }

        let endpoint = "/point?lat=\(lat)&lon=\(lon)&key=\(apiKey)"

        // Fetch raw data
        let data = try await APIService.shared.requestRaw(endpoint: endpoint)

        // Convert to string and clean weird chars (optional - might help with other issues)
        guard var jsonString = String(data: data, encoding: String.Encoding.utf8) else {
            throw URLError(.cannotDecodeRawData)
        }

        // Clean any additional unwanted characters but keep the BOM characters in keys
        // since we're handling them with CodingKeys
        jsonString = jsonString.replacingOccurrences(
            of: #"[\u{200B}-\u{200F}\u{202A}-\u{202E}]"#,
            with: "",
            options: String.CompareOptions.regularExpression
        )

        // Back to Data
        guard let cleanData = jsonString.data(using: String.Encoding.utf8) else {
            throw URLError(.cannotDecodeRawData)
        }

        // Decode model - REMOVED convertFromSnakeCase since we handle keys manually
        let decoder = JSONDecoder()
        return try decoder.decode(PointResponse.self, from: cleanData)
    }
}
