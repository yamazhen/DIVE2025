import Foundation

struct WeatherResponse {
    let weather: Weather
    let temp: Temp
}

class WeatherService {
    static let shared = WeatherService()
    private init() {}

    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            throw URLError(.badURL)
        }

        // Build endpoints
        let currentEndpoint = "/current?lat=\(lat)&lon=\(lon)&key=\(apiKey)"
        let tempEndpoint    = "/temp?lat=\(lat)&lon=\(lon)&key=\(apiKey)"

        // Fetch both in parallel
        async let current: Weather   = APIService.shared.request(endpoint: currentEndpoint)
        async let tempArray: [Temp]  = APIService.shared.request(endpoint: tempEndpoint)

        // Wait for both
        let (weather, temps) = try await (current, tempArray)

        // Take the first temp or throw an error if empty
        guard let firstTemp = temps.first else {
            throw URLError(.badServerResponse)
        }

        return WeatherResponse(weather: weather, temp: firstTemp)
    }
}
