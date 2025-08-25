import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

class APIService {
    static let shared = APIService()
    private var baseURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String else {
            fatalError("BASE_URL not found in config")
        }
        return "https://\(url)"
    }

    private init() {}

    // Normal typed request (decodes JSON into T)
    func request<T: Codable>(endpoint: String, method: HTTPMethod = .GET, body: Data? = nil)
        async throws -> T
    {
        let data = try await requestRaw(endpoint: endpoint, method: method, body: body)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // Raw request (returns raw Data for cleaning, etc.)
    func requestRaw(endpoint: String, method: HTTPMethod = .GET, body: Data? = nil)
        async throws -> Data
    {
        guard let url = URL(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}
