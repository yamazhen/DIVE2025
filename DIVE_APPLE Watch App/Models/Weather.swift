struct Weather: Codable {
    let weather: [WeatherEntry]
    let info: WeatherInfo
}

struct WeatherEntry: Codable {
    let aplYmdt: String     // Forecast time
    let sky: String         // "맑음", "구름많음", etc.
    let sky_code: String    // Code for sky condition
    let rain: String        // 1-hour precipitation
    let temp: String        // Temperature (C)
    let winddir: String     // Wind direction
    let windspd: String     // Wind speed
    let pago: String        // Wave height
    let humidity: String    // Humidity %
    
    // Optional extra fields in your JSON
    let pm25_s: String?     // Fine dust status
    let pm10_s: String?     // Coarse dust status
    let pm10: String?       // PM10 value
    let pm25: String?       // PM2.5 value
}

struct WeatherInfo: Codable {
    let city: String
    let cityCode: String
}
