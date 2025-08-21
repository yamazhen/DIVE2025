//
//  ContentView.swift
//  DIVE_APPLE Watch App
//
//  Created by Zhen on 20/08/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var alertManager = AlertManager()

    var body: some View {
        TabView {
            LocationCard()
            TideCard()
            WeatherCard()
            HealthMonitorCard()
            EmergencyCard()
        }
        .tabViewStyle(PageTabViewStyle())
        .environmentObject(alertManager) // inject globally
        .alert(alertManager.title,
               isPresented: Binding(
                    get: { alertManager.message != nil },
                    set: { _ in alertManager.clear() }
               )
        ) {
            Button("OK", role: .cancel) { alertManager.clear() }
        } message: {
            Text(alertManager.message ?? "")
        }
    }
}

#Preview {
    ContentView()
}
