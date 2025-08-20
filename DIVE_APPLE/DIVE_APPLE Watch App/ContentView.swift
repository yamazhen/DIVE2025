//
//  ContentView.swift
//  DIVE_APPLE Watch App
//
//  Created by Zhen on 20/08/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LocationCard()
            TideCard()
            WeatherAlertCard()
            HealthMonitorCard()
            EmergencyCard()
        }.tabViewStyle(PageTabViewStyle())
    }
}

#Preview {
    ContentView()
}
