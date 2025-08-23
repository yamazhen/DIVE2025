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

        // Convert to string and clean weird chars
        guard var jsonString = String(data: data, encoding: String.Encoding.utf8) else {
            throw URLError(.cannotDecodeRawData)
        }

        jsonString = jsonString.replacingOccurrences(
            of: #"[\u{FEFF}\u{200B}-\u{200F}\u{202A}-\u{202E}]"#,
            with: "",
            options: String.CompareOptions.regularExpression
        )

        // Back to Data
        guard let cleanData = jsonString.data(using: String.Encoding.utf8) else {
            throw URLError(.cannotDecodeRawData)
        }

        // Decode model
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PointResponse.self, from: cleanData)
    }
}
