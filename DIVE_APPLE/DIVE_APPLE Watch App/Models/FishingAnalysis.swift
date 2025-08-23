import Foundation

// MARK: - Fishing Analysis Response Models
struct FishingAnalysis: Codable {
    let fishingScore: Double
    let bestTimeToday: String
    let recommendedSpecies: [String]
    let topLocation: FishingLocation
    let conditions: FishingConditions
    let insights: FishingInsights
}

struct FishingLocation: Codable {
    let name: String
    let reason: String
    let distance: String?
}

struct FishingConditions: Codable {
    let tideStatus: String
    let weatherStatus: String
    let waterTemp: String?
    let moonPhase: String?
}

struct FishingInsights: Codable {
    let summary: String
    let tips: [String]
    let warnings: [String]?
}

// MARK: - JSON Schema for Gemini
extension FishingAnalysis {
    static let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "fishingScore": [
                "type": "number",
                "description": "Fishing success probability (0-10 scale)",
                "minimum": 0,
                "maximum": 10
            ],
            "bestTimeToday": [
                "type": "string",
                "description": "Best fishing time window today (e.g., '2-4 PM', 'Early morning')"
            ],
            "recommendedSpecies": [
                "type": "array",
                "items": [
                    "type": "string"
                ],
                "description": "Top 3 fish species likely to bite today",
                "maxItems": 3
            ],
            "topLocation": [
                "type": "object",
                "properties": [
                    "name": [
                        "type": "string",
                        "description": "Name of the best fishing location"
                    ],
                    "reason": [
                        "type": "string",
                        "description": "Why this location is best today (brief)"
                    ],
                    "distance": [
                        "type": "string",
                        "description": "Distance from current location (optional)"
                    ]
                ],
                "required": ["name", "reason"]
            ],
            "conditions": [
                "type": "object",
                "properties": [
                    "tideStatus": [
                        "type": "string",
                        "description": "Current tide situation (e.g., 'Rising tide', 'High tide in 2 hours')"
                    ],
                    "weatherStatus": [
                        "type": "string",
                        "description": "Weather impact on fishing (e.g., 'Cloudy - excellent', 'Windy - challenging')"
                    ],
                    "waterTemp": [
                        "type": "string",
                        "description": "Water temperature and its impact (optional)"
                    ],
                    "moonPhase": [
                        "type": "string",
                        "description": "Moon phase and fishing impact (optional)"
                    ]
                ],
                "required": ["tideStatus", "weatherStatus"]
            ],
            "insights": [
                "type": "object",
                "properties": [
                    "summary": [
                        "type": "string",
                        "description": "Brief overall fishing outlook for today (1-2 sentences)"
                    ],
                    "tips": [
                        "type": "array",
                        "items": [
                            "type": "string"
                        ],
                        "description": "2-3 specific fishing tips for today's conditions",
                        "maxItems": 3
                    ],
                    "warnings": [
                        "type": "array",
                        "items": [
                            "type": "string"
                        ],
                        "description": "Any safety or condition warnings (optional)",
                        "maxItems": 2
                    ]
                ],
                "required": ["summary", "tips"]
            ]
        ],
        "required": ["fishingScore", "bestTimeToday", "recommendedSpecies", "topLocation", "conditions", "insights"]
    ]
}