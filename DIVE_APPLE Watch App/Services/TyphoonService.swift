import Foundation

struct KMATyphoonListResponse: Codable {
    let response: KMATyphoonResponse
}

struct KMATyphoonResponse: Codable {
    let header: KMATyphoonHeader
    let body: KMATyphoonBody
}

struct KMATyphoonHeader: Codable {
    let resultCode: String
    let resultMsg: String
}

struct KMATyphoonBody: Codable {
    let dataType: String
    let items: KMATyphoonItems
    let pageNo: Int
    let numOfRows: Int
    let totalCount: Int
}

struct KMATyphoonItems: Codable {
    let item: [KMATyphoonInfo]
}

struct KMATyphoonInfo: Codable {
    let announceSeq: Int
    let announceTime: String
    let typhoonSeq: Int
    let title: String
}

struct KMATyphoonForecastResponse: Codable {
    let response: KMATyphoonForecastResponseBody
}

struct KMATyphoonForecastResponseBody: Codable {
    let header: KMATyphoonHeader
    let body: KMATyphoonForecastBody
}

struct KMATyphoonForecastBody: Codable {
    let dataType: String
    let items: KMATyphoonForecastItems
    let pageNo: Int
    let numOfRows: Int
    let totalCount: Int
}

struct KMATyphoonForecastItems: Codable {
    let item: [KMATyphoonForecast]
}

struct KMATyphoonForecast: Codable {
    let dir: String // Direction
    let ed15: String // Error direction for 15m/s
    let er15: Int // Error radius for 15m/s
    let ed25: String // Error direction for 25m/s  
    let er25: Int // Error radius for 25m/s
    let fcLocKo: String // Location in Korean
    let lat: String // Latitude
    let lon: String // Longitude
    let ps: String // Central pressure (hPa)
    let rad15: String // Radius for 15m/s winds
    let rad25: String // Radius for 25m/s winds
    let radPr: String // Pressure radius
    let seq: String // Typhoon sequence
    let sp: String // Speed (km/h)
    let tm: String // Time
    let tmFc: String // Forecast time
    let ws: String // Wind speed (m/s)
}

class TyphoonService {
    static let shared = TyphoonService()
    private init() {}
    
    private let baseURL = "http://apis.data.go.kr/1360000/TyphoonInfoService"
    
    func checkNearbyTyphoons(userLat: Double, userLon: Double) async throws -> [Alert] {
        let typhoonList = try await fetchTyphoonList()
        var alerts: [Alert] = []
        
        let recentTyphoons = Array(typhoonList.prefix(2))
        
        for typhoonInfo in recentTyphoons {
            if let forecasts = try? await fetchTyphoonForecast(
                tmFc: typhoonInfo.announceTime,
                typSeq: typhoonInfo.typhoonSeq
            ) {
                if let latestForecast = forecasts.first {
                    if let alert = checkTyphoonProximity(
                        forecast: latestForecast, 
                        userLat: userLat, 
                        userLon: userLon,
                        typhoonSeq: typhoonInfo.typhoonSeq
                    ) {
                        alerts.append(alert)
                    }
                }
            }
        }
        
        return alerts
    }
    
    private func fetchTyphoonList() async throws -> [KMATyphoonInfo] {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "PUBLIC_API_KEY") as? String else {
            throw URLError(.badURL)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let currentDate = dateFormatter.string(from: Date())
        
        guard let encodedApiKey = apiKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        let urlString = "\(baseURL)/getTyphoonInfoList?serviceKey=\(encodedApiKey)&numOfRows=10&pageNo=1&dataType=JSON&tmFc=\(currentDate)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(KMATyphoonListResponse.self, from: data)
        
        return response.response.body.items.item.sorted { 
            $0.announceTime > $1.announceTime 
        }
    }
    
    private func fetchTyphoonForecast(tmFc: String, typSeq: Int) async throws -> [KMATyphoonForecast] {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "PUBLIC_API_KEY") as? String else {
            throw URLError(.badURL)
        }
        
        guard let encodedApiKey = apiKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw URLError(.badURL)
        }
        
        let urlString = "\(baseURL)/getTyphoonFcst?serviceKey=\(encodedApiKey)&numOfRows=10&pageNo=1&dataType=JSON&tmFc=\(tmFc)&typSeq=\(typSeq)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(KMATyphoonForecastResponse.self, from: data)
        
        return response.response.body.items.item.sorted { $0.tm > $1.tm }
    }
    
    private func checkTyphoonProximity(forecast: KMATyphoonForecast, userLat: Double, userLon: Double, typhoonSeq: Int) -> Alert? {
        guard let typhoonLat = Double(forecast.lat),
              let typhoonLon = Double(forecast.lon),
              let windSpeed = Double(forecast.ws),
              let pressure = Double(forecast.ps) else {
            return nil
        }
        
        let distance = calculateDistance(
            lat1: userLat, lon1: userLon,
            lat2: typhoonLat, lon2: typhoonLon
        )
        
        let criticalDistance: Double = 400 // km
        let warningDistance: Double = 600 // km
        let watchDistance: Double = 1000 // km
        
        var alertTitle: String
        var alertMessage: String
        
        if distance <= criticalDistance && windSpeed >= 25 {
            alertTitle = "⚠ 태풍 경보 ⚠"
            alertMessage = "제\(typhoonSeq)호 태풍이 \(Int(distance))km 거리 접근중!\n최대풍속: \(Int(windSpeed))m/s, 중심기압: \(Int(pressure))hPa\n위치: \(forecast.fcLocKo)"
        } else if distance <= warningDistance && windSpeed >= 20 {
            alertTitle = "⚠ 태풍 주의보 ⚠"
            alertMessage = "제\(typhoonSeq)호 태풍 주의보 발령\n거리: \(Int(distance))km, 풍속: \(Int(windSpeed))m/s\n위치: \(forecast.fcLocKo)"
        } else if distance <= watchDistance && windSpeed >= 15 {
            alertTitle = "⚠ 태풍 정보 ⚠"
            alertMessage = "제\(typhoonSeq)호 태풍 모니터링\n거리: \(Int(distance))km, 풍속: \(Int(windSpeed))m/s\n\(forecast.fcLocKo)"
        } else {
            return nil // No alert needed
        }
        
        return Alert(
            type: .typhoon,
            title: alertTitle,
            message: alertMessage
        )
    }
    
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0 // Earth radius in kilometers
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
}
