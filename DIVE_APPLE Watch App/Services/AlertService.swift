import Foundation
import WatchKit

enum AlertType: String {
    case typhoon = "typhoon"
    case climateAnomaly = "climate_anomaly"
    case highTide = "high_tide"
}

struct Alert {
    let id: String
    let type: AlertType
    let title: String
    let message: String
    let timestamp: Date

    init(type: AlertType, title: String, message: String) {
        self.id = UUID().uuidString
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = Date()
    }
}

struct AlertThresholds {
    var windSpeedMax: Double = 15.0  // m/s for anomaly
    var temperatureMin: Double = 5.0  // °C
    var temperatureMax: Double = 35.0  // °C
    var waveHeightMax: Double = 3.0  // m
    var tideAlertHours: Double = 2.0  // hours before high tide
}

class AlertService: ObservableObject {
    static let shared = AlertService()

    @Published var activeAlerts: [Alert] = []
    @Published var thresholds = AlertThresholds()
    @Published var isMonitoring = false

    private var alertCooldowns: [AlertType: Date] = [:]
    private let cooldownDuration: TimeInterval = 3600  // 1 hour

    private init() {
        loadThresholds()
    }

    func startMonitoring() {
        isMonitoring = true
        scheduleBackgroundRefresh()
    }

    func stopMonitoring() {
        isMonitoring = false
    }

    func checkAllAlerts(lat: Double, lon: Double) async {
        guard isMonitoring else { return }

        do {
            // Check real typhoon data from KMA
            let typhoonAlerts = try await TyphoonService.shared.checkNearbyTyphoons(userLat: lat, userLon: lon)
            for alert in typhoonAlerts {
                await addAlert(alert)
            }
            
            let weatherResponse = try await WeatherService.shared.fetchWeather(lat: lat, lon: lon)
            await checkClimateAnomalyAlert(weather: weatherResponse.weather)

            let tides = try await TideService.shared.fetchTideData(lat: lat, lon: lon)
            await checkHighTideAlert(tides: tides)

        } catch {
            print("Error checking alerts: \(error)")
        }
    }

    func checkTyphoonAlert(weather: Weather) async {
        guard let latestWeather = weather.weather.first,
            let windSpeed = Double(latestWeather.windspd),
            let waveHeight = Double(latestWeather.pago),
            !isInCooldown(.typhoon)
        else { return }

        if windSpeed > 25.0 && waveHeight > 6.0 {
            let alert = Alert(
                type: .typhoon,
                title: "⚠ TYPHOON WARNING ⚠",
                message: "Typhoon conditions detected! Wind: \(windSpeed)m/s, Waves: \(waveHeight)m"
            )
            await addAlert(alert)
        }
    }

    func checkClimateAnomalyAlert(weather: Weather) async {
        guard let latestWeather = weather.weather.first,
            !isInCooldown(.climateAnomaly)
        else { return }

        var anomalies: [String] = []

        if let temp = Double(latestWeather.temp) {
            if temp < thresholds.temperatureMin {
                anomalies.append("Low temp: \(temp)°C")
            } else if temp > thresholds.temperatureMax {
                anomalies.append("High temp: \(temp)°C")
            }
        }

        if let windSpeed = Double(latestWeather.windspd),
            windSpeed > thresholds.windSpeedMax
        {
            anomalies.append("High wind: \(windSpeed)m/s")
        }

        if let waveHeight = Double(latestWeather.pago),
            waveHeight > thresholds.waveHeightMax
        {
            anomalies.append("High waves: \(waveHeight)m")
        }

        if !anomalies.isEmpty {
            let alert = Alert(
                type: .climateAnomaly,
                title: "⚠ Climate Anomaly ⚠",
                message: anomalies.joined(separator: ", ")
            )
            await addAlert(alert)
        }
    }

    func checkHighTideAlert(tides: [Tide]) async {
        guard !tides.isEmpty, !isInCooldown(.highTide) else { return }

        let tide = tides[0]
        let tideTimes = [tide.pTime1, tide.pTime2, tide.pTime3, tide.pTime4]
        let now = Date()

        for timeString in tideTimes {
            if let tideTime = parseTideTime(timeString) {
                let timeUntilTide = tideTime.timeIntervalSince(now)
                let hoursUntilTide = timeUntilTide / 3600

                if hoursUntilTide > 0 && hoursUntilTide <= thresholds.tideAlertHours {
                    let alert = Alert(
                        type: .highTide,
                        title: "≈ High Tide Alert ≈",
                        message:
                            "High tide approaching in \(String(format: "%.1f", hoursUntilTide)) hours"
                    )
                    await addAlert(alert)
                    break
                }
            }
        }
    }

    private func parseTideTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let calendar = Calendar.current
        let today = Date()

        if let time = formatter.date(from: timeString) {
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(
                bySettingHour: components.hour ?? 0,
                minute: components.minute ?? 0,
                second: 0, of: today)
        }
        return nil
    }

    @MainActor
    private func addAlert(_ alert: Alert) {
        activeAlerts.append(alert)
        alertCooldowns[alert.type] = Date()
        triggerNotification(for: alert)
    }

    private func isInCooldown(_ alertType: AlertType) -> Bool {
        guard let lastAlert = alertCooldowns[alertType] else { return false }
        return Date().timeIntervalSince(lastAlert) < cooldownDuration
    }

    func triggerNotification(for alert: Alert) {
        let alertAction = WKAlertAction(title: "OK", style: .default) {}

        WKExtension.shared().rootInterfaceController?.presentAlert(
            withTitle: alert.title,
            message: alert.message,
            preferredStyle: .alert,
            actions: [alertAction]
        )

        WKInterfaceDevice.current().play(.notification)
    }

    private func scheduleBackgroundRefresh() {
        let refreshDate = Date(timeIntervalSinceNow: 3600)  // 1 hour
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: refreshDate, userInfo: nil
        ) { error in
            if let error = error {
                print("Failed to schedule background refresh: \(error)")
            }
        }
    }

    func dismissAlert(_ alertId: String) {
        activeAlerts.removeAll { $0.id == alertId }
    }
    
    func resetCooldowns() {
        alertCooldowns.removeAll()
    }

    private func loadThresholds() {
        if let data = UserDefaults.standard.data(forKey: "AlertThresholds"),
            let decoded = try? JSONDecoder().decode(AlertThresholds.self, from: data)
        {
            thresholds = decoded
        }
    }

    func saveThresholds() {
        if let encoded = try? JSONEncoder().encode(thresholds) {
            UserDefaults.standard.set(encoded, forKey: "AlertThresholds")
        }
    }
}

extension AlertThresholds: Codable {}

