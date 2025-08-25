import Foundation

class GeminiService {
    static let shared = GeminiService()
    private init() {}

    private let baseURL =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

    func generateContent(prompt: String) async throws -> GeminiResponse {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_KEY") as? String else {
            throw GeminiError.missingAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw GeminiError.invalidURL
        }

        let request = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: prompt)
                    ]
                )
            ]
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw GeminiError.encodingError
        }

        return try await performRequest(urlRequest)
    }

    func generateStructuredContent<T: Codable>(
        prompt: String,
        responseType: T.Type,
        schema: [String: Any]
    ) async throws -> T {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_KEY") as? String else {
            throw GeminiError.missingAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw GeminiError.invalidURL
        }

        let request = GeminiStructuredRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: prompt)
                    ]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                responseMimeType: "application/json",
                responseSchema: schema
            )
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw GeminiError.encodingError
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw GeminiError.apiError(httpResponse.statusCode)
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

            guard let firstCandidate = geminiResponse.candidates.first,
                let firstPart = firstCandidate.content.parts.first,
                let jsonText = firstPart.text
            else {
                throw GeminiError.noContentReceived
            }

            guard let jsonData = jsonText.data(using: .utf8) else {
                throw GeminiError.invalidJSON
            }

            let structuredResponse = try JSONDecoder().decode(responseType, from: jsonData)
            return structuredResponse

        } catch {
            if error is GeminiError {
                throw error
            } else {
                throw GeminiError.networkError(error.localizedDescription)
            }
        }
    }

    func analyzeWithVision(prompt: String, imageData: Data, mimeType: String = "image/jpeg")
        async throws -> GeminiResponse
    {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_KEY") as? String else {
            throw GeminiError.missingAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw GeminiError.invalidURL
        }

        let base64Image = imageData.base64EncodedString()

        let request = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: prompt),
                        GeminiPart(
                            inlineData: GeminiInlineData(
                                mimeType: mimeType,
                                data: base64Image
                            )
                        ),
                    ]
                )
            ]
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw GeminiError.encodingError
        }

        return try await performRequest(urlRequest)
    }

    private func performRequest(_ urlRequest: URLRequest) async throws -> GeminiResponse {
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw GeminiError.apiError(httpResponse.statusCode)
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            return geminiResponse

        } catch {
            if error is GeminiError {
                throw error
            } else {
                throw GeminiError.networkError(error.localizedDescription)
            }
        }
    }
}

