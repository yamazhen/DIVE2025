import Foundation

class ForecastService {
    static let shared = ForecastService()
    private init() {}

    func fetchForecast(lat: Double, lon: Double) async throws -> [Forecast] {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            throw URLError(.badURL)
        }
        let endpoint = "/forecast?lat=\(lat)&lon=\(lon)&key=\(apiKey)"
        return try await APIService.shared.request(endpoint: endpoint)
    }
}
