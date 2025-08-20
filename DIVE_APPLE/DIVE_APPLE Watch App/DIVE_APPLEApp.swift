//
//  DIVE_APPLEApp.swift
//  DIVE_APPLE Watch App
//
//  Created by Zhen on 20/08/2025.
//

import SwiftUI

@main
struct DIVE_APPLE_Watch_AppApp: App {
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
        }
    }
}
