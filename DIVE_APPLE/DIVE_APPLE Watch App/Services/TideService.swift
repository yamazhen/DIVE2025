import Foundation

class TideService {
    static let shared = TideService()
    private init() {}

    func fetchTideData(lat: Double, lon: Double) async throws -> [Tide] {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            throw URLError(.badURL)
        }
        let endpoint = "/tide?lat=\(lat)&lon=\(lon)&key=\(apiKey)"
        return try await APIService.shared.request(endpoint: endpoint)
    }
}
