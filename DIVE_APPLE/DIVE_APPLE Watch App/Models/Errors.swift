import Foundation

enum TideError: LocalizedError {
    case noLocation
    case apiKeyMissing
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noLocation:
            return "Location unavailable"
        case .apiKeyMissing:
            return "Configuration error"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

}
