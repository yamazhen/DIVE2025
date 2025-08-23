import Foundation

class WeatherService {
    static let shared = WeatherService()
    private init() {}

    func fetchWeather(lat: Double, lon: Double) async throws -> Weather {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            throw URLError(.badURL)
        }
        let endpoint = "/current?lat=\(lat)&lon=\(lon)&key=\(apiKey)"
        return try await APIService.shared.request(endpoint: endpoint)
    }
}
