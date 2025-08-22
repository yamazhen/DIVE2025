//
//  Point.swift
//  DIVE_APPLE
//
//  Created by Nodirbek Bokiev on 8/21/25.
//

import Foundation

// MARK: - Top-level API response
struct PointResponse: Codable {
    let fishing_point: [Point]
    let info: PointInfo
}

// MARK: - Fishing Point (list item)
struct Point: Codable, Identifiable {
    var id: String { point_dt }   // use point_dt as unique id
    
    let name: String
    let point_nm: String
    let dpwt: String
    let material: String
    let tide_time: String
    let target: String
    let lat: String
    let lon: String
    let photo: String
    let addr: String
    let seaside: String
    let point_dt: String
}

// MARK: - Additional info (details)
struct PointInfo: Codable {
    let intro: String
    let forecast: String
    let ebbf: String
    let notice: String
    let wtemp_sp: String
    let wtemp_su: String
    let wtemp_fa: String
    let wtemp_wi: String
    let fish_sp: String
    let fish_su: String
    let fish_fa: String
    let fish_wi: String
}
