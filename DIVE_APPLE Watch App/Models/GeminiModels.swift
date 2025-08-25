import Foundation

// MARK: - Request Models
struct GeminiRequest: Codable {
    let contents: [GeminiContent]
}

struct GeminiStructuredRequest: Codable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
    let inlineData: GeminiInlineData?
    
    init(text: String) {
        self.text = text
        self.inlineData = nil
    }
    
    init(inlineData: GeminiInlineData) {
        self.text = nil
        self.inlineData = inlineData
    }
}

struct GeminiInlineData: Codable {
    let mimeType: String
    let data: String
}

struct GeminiGenerationConfig: Codable {
    let responseMimeType: String
    let responseSchema: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case responseMimeType = "response_mime_type"
        case responseSchema = "response_schema"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(responseMimeType, forKey: .responseMimeType)
        
        let schemaData = try JSONSerialization.data(withJSONObject: responseSchema)
        let schemaString = String(data: schemaData, encoding: .utf8) ?? "{}"
        let schemaObject = try JSONSerialization.jsonObject(with: schemaData)
        
        var schemaContainer = encoder.container(keyedBy: CodingKeys.self)
        try schemaContainer.encode(AnyCodable(schemaObject), forKey: .responseSchema)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        responseMimeType = try container.decode(String.self, forKey: .responseMimeType)
        
        let schemaValue = try container.decode(AnyCodable.self, forKey: .responseSchema)
        responseSchema = schemaValue.value as? [String: Any] ?? [:]
    }
    
    init(responseMimeType: String, responseSchema: [String: Any]) {
        self.responseMimeType = responseMimeType
        self.responseSchema = responseSchema
    }
}

// MARK: - Response Models
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
    let usageMetadata: GeminiUsageMetadata?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    let index: Int?
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiUsageMetadata: Codable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
}

struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
}

// MARK: - Helper for Any Codable
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Error Types
enum GeminiError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case encodingError
    case invalidResponse
    case apiError(Int)
    case networkError(String)
    case noContentReceived
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing GEMINI_KEY in configuration"
        case .invalidURL:
            return "Invalid Gemini API URL"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .apiError(let code):
            return "Gemini API error: \(code)"
        case .networkError(let description):
            return "Network error: \(description)"
        case .noContentReceived:
            return "No content received from Gemini"
        case .invalidJSON:
            return "Invalid JSON in response"
        }
    }
}
