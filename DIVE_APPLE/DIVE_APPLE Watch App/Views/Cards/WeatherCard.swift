//  WeatherCard.swift
//  DIVE_APPLE
//
//  Created by Nodirbek Bokiev on 8/21/25.
//

import SwiftUI

struct WeatherCard: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var weather: Weather?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading weather...").font(.caption2)
            } else if let error = errorMessage {
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                    Button("Retry") { Task { await loadWeatherData() } }
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            } else if let w = weather {
                if let current = w.weather.first {
                    VStack(spacing: 6) {
                        Text(w.info.city)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🌤 \(current.sky)")
                                Text("🌡 \(current.temp) °C")
                                Text("💧 Humidity: \(current.humidity)%")
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("💨 \(current.winddir) \(current.windspd)m/s")
                                Text("🌊 Wave: \(current.pago)m")
                                if let rain = Double(current.rain), rain > 0 {
                                    Text("☔️ Rain: \(rain)mm")
                                }
                            }
                        }
                        .font(.caption2)
                    }
                } else {
                    Text("No weather data")
                        .font(.caption)
                }
            } else {
                Text("No weather loaded").font(.caption)
            }
        }
        .task {
            await loadWeatherData()
        }
    }

    private func loadWeatherData() async {
        isLoading = true
        errorMessage = nil

        let lat = locationManager.latitude != 0.0 ? locationManager.latitude : 35.1796
        let lon = locationManager.longitude != 0.0 ? locationManager.longitude : 129.0756

        do {
            weather = try await WeatherService.shared.fetchWeather(lat: lat, lon: lon)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
