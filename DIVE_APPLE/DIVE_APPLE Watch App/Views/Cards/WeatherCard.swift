import SwiftUI

struct WeatherCard: View {
    @EnvironmentObject var locationManager: LocationManager
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var weather: Weather?
    @State private var temp: Temp?
    @State private var forecast: [Forecast] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showWeekly = false

    // ✅ helper: decide scale factor based on screen width
    private var scaleFactor: CGFloat {
        let width = WKInterfaceDevice.current().screenBounds.width
        // Ultra ~ 205px wide, 45mm ~ 198px, 40mm ~ 162px
        if width <= 162 { return 1 }  // smallest
        if width <= 184 { return 1 }   // 41/44mm
        return 1.0                       // keep full size on Ultra / large
    }

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
            } else if let w = weather, let current = w.weather.first {
                Button { withAnimation { showWeekly.toggle()} } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(w.info.city)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Capsule())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            Image(systemName: skyCodeToSymbol(current.sky_code))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .symbolRenderingMode(.multicolor)
                                .symbolEffect(.bounce)

                            Spacer()

                            Text("\(current.temp)°C")
                                .font(.system(size: 40, weight: .semibold))
                                .minimumScaleFactor(0.5) // ✅ shrink text if needed
                                .lineLimit(1)
                        }

                        if let seaTemp = temp?.obs_wt {
                            Text("Sea Temp: \(seaTemp)°C")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        } else {
                            Text("Sea Temp: -- °C")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .animation(.bouncy)
                        }

                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "wind")
                                    .symbolRenderingMode(.multicolor)
                                Label("\(current.windspd)m/s", systemImage: directionSymbol(current.winddir))
                                   
                                Spacer()
                                Label("\(current.pago)m", systemImage: "water.waves")
                                    
                            }
                            HStack {
                                Label("\(current.humidity)%",
                                      systemImage: "humidity")
                                Spacer()
                                if let rain = Double(current.rain), rain > 0 {
                                    Label("\(rain)mm",
                                          systemImage: "cloud.heavyrain.fill")
                                } else if let pm = current.pm25 {
                                    Label("PM2.5: \(pm)",
                                          systemImage: "aqi.medium")
                                } else {
                                    Label("No rain", systemImage: "drop")
                                }
                            }
                        }
                        .font(.caption2) // smaller base font than caption2
                        .minimumScaleFactor(0.8) // scale down if needed
                        .lineLimit(1) // prevent wrapping
                    }
                    .padding()
                    .scaleEffect(scaleFactor, anchor: .topLeading) // ✅ adaptive scaling
                }
                .buttonStyle(PlainButtonStyle())
                .sheet(isPresented: $showWeekly) {
                    ForecastSheet(forecasts: forecast.sevenDayForecast())
                }

            } else {
                Image(systemName: "exclamationmark.square.fill")
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.bounce, options: .nonRepeating)
                Text("No weather loaded").font(.caption)
            }
        }
        .task { await loadWeatherData() }
    }

    private func loadWeatherData() async {
        isLoading = true
        errorMessage = nil

        let lat = locationManager.latitude != 0.0 ? locationManager.latitude : 35.1796
        let lon = locationManager.longitude != 0.0 ? locationManager.longitude : 129.0756

        do {
            let response = try await WeatherService.shared.fetchWeather(lat: lat, lon: lon)
            self.weather = response.weather
            self.temp = response.temp
            self.forecast = try await ForecastService.shared.fetchForecast(lat: lat, lon: lon)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

func skyCodeToSymbol(_ code: String) -> String {
    switch code {
    case "1":  return "sun.max.fill"              // Clear
    case "2":  return "cloud.sun.fill"            // Few Clouds
    case "3":  return "cloud.fill"                // Cloudy
    case "4":  return "cloud.rain.fill"           // Rain
    case "5":  return "cloud.snow.fill"           // Snow
    case "6":  return "cloud.sleet.fill"          // Snow Rain (sleet)
    case "7":  return "cloud.heavyrain.fill"      // Shower
    case "8":  return "cloud.snow.fill"           // Snow Shower
    case "9":  return "cloud.fog.fill"            // Fog
    case "10": return "cloud.bolt.rain.fill"      // Thunderstorm
    case "11": return "sun.haze.fill"             // Gradually Cloudy
    case "12": return "cloud.bolt.fill"           // Cloudy then Thunderstorm
    case "13": return "cloud.rain.fill"           // Cloudy then Rain
    case "14": return "cloud.snow.fill"           // Cloudy then Snow
    case "15": return "cloud.sleet.fill"          // Cloudy then Snow Rain
    case "16": return "cloud.sun.fill"            // Cloudy then Clear
    case "17": return "cloud.bolt.sun.fill"       // Thunderstorm then Clear
    case "18": return "cloud.sun.rain.fill"       // Rain then Clear
    case "19": return "cloud.sun.snow.fill"       // Snow then Clear
    case "20": return "cloud.sleet.fill"          // Snow Rain then Clear
    case "21": return "smoke.fill"                // Many Clouds
    case "22": return "aqi.low"                   // Dust Storm (closest match)
    default:   return "questionmark.circle.fill"  // Unknown
    }
}

extension Array where Element == Forecast {
    func sevenDayForecast() -> [Forecast] {
        // Group forecasts by day (prefix 8 = "yyyyMMdd")
        let grouped = Dictionary(grouping: self) { String($0.ymdt.prefix(8)) }
        let sortedDays = grouped.keys.sorted()

        // pick the first forecast of each day
        let daily = sortedDays.compactMap { grouped[$0]?.first }

        return Array(daily.prefix(7))
    }
}

struct ForecastSheet: View {
    let forecasts: [Forecast]

    var body: some View {
        List(forecasts, id: \.id) { f in
            VStack(alignment: .leading, spacing: 6) {
                // First line: Day + Sky + Temp
                HStack {
                    Text(formatDate(f.ymdt))
                        .font(.footnote)
                        .minimumScaleFactor(0.8)

                    Spacer()
                    Image(systemName: skyCodeToSymbol(f.skycode))
                        .symbolRenderingMode(.multicolor)
                    Text("\(f.temp)°C")
                        .font(.title3) // smaller than .title
                        .fontWeight(.medium)
                        .minimumScaleFactor(0.6)
                }

                // Second line: Winddir | Windspd | Humidity
                HStack {
                    Image(systemName:"wind")
                    Label("\(f.windspd)m/s", systemImage: directionSymbol(f.winddir))
                    Spacer()
                    Label("\(f.humidity)%", systemImage: "humidity")
                }
                .font(.caption2)
                .foregroundColor(.gray)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
    }

    private func formatDate(_ ymdt: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHH"
        if let date = formatter.date(from: ymdt) {
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        return ymdt
    }
}

func directionSymbol(_ dir: String) -> String {
    switch dir.uppercased() {
    case "N":  return  "arrow.up"
    case "NE": return "arrow.up.right"
    case "E":  return  "arrow.right"
    case "SE": return  "arrow.down.right"
    case "S":  return  "arrow.down"
    case "SW": return  "arrow.down.left"
    case "W":  return "arrow.left"
    case "NW": return  "arrow.up.left"
    default:   return  "location" // fallback if unknown
    }
}
