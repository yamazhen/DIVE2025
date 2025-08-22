//
//  PointService.swift
//  DIVE_APPLE
//
//  Created by Nodirbek Bokiev on 8/22/25.
//

import Foundation

class PointService {
    static let shared = PointService()
    private init() {}

    // Fetch fishing/diving points near a location
    func fetchPoints(lat: Double, lon: Double) async throws -> PointResponse {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String else {
            throw URLError(.badURL)
        }
        
        let endpoint = "/point?lat=\(lat)&lon=\(lon)&key=\(apiKey)"
        return try await APIService.shared.request(endpoint: endpoint)
    }
}
