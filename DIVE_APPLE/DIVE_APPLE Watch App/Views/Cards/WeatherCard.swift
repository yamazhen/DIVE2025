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
                Image(systemName: "slowmo")
                .symbolEffect(.rotate.byLayer, options: .repeat(.continuous))
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
                                HStack {
                                    Image(systemName: "sun.max.fill") // choose icon based on current.sky
                                        .symbolRenderingMode(.multicolor)
                                        .symbolEffect(.bounce, options: .nonRepeating)
                                    Text(current.sky)
                                }
                                HStack {
                                    Image(systemName: "thermometer.high") // choose icon based on current.sky
                                        .symbolRenderingMode(.multicolor)
                                        .symbolEffect(.bounce, options: .nonRepeating)
                                    Text(":\(current.temp) °C")
                                }
                                HStack {
                                    Image(systemName: "humidity") // choose icon based on current.sky
                                        .symbolRenderingMode(.multicolor)
                                        .symbolEffect(.bounce, options: .nonRepeating)
                                    Text(":\(current.humidity)%")
                                }
                               
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "wind") // choose icon based on current.sky
                                        .symbolRenderingMode(.multicolor)
                                        .symbolEffect(.bounce, options: .nonRepeating)
                                    Text("\(current.winddir) \(current.windspd)m/s")
                                }
                                HStack {
                                    Image(systemName: "water.waves") // choose icon based on current.sky
                                        .symbolRenderingMode(.multicolor)
                                    .symbolEffect(.bounce, options: .nonRepeating)
                                    Text(" \(current.pago)m")
                                }
                                HStack {
                                    if let rain = Double(current.rain), rain > 0 {
                                        Image(systemName: "cloud.heavyrain.fill") // choose icon based on current.sky
                                            .symbolRenderingMode(.multicolor)
                                            .symbolEffect(.bounce, options: .nonRepeating)
                                        Text(" \(rain)mm")
                                    }
                                }
                            }
                        }
                        .font(.caption2)
                    }
                } else {
                    Image(systemName: "exclamationmark.square.fill")
                        .foregroundColor(.orange)
                    .symbolEffect(.bounce, options: .nonRepeating)
                    Text("No weather data").font(.caption)
                }
            } else {
                Image(systemName: "exclamationmark.square.fill") // choose icon based on current.sky
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.bounce, options: .nonRepeating)
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
