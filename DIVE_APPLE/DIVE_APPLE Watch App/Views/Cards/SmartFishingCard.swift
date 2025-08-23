import SwiftUI

struct SmartFishingCard: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var fishingAnalysis: FishingAnalysis?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDetailSheet = false
    @State private var lastAnalysisTime: Date?
    
    var body: some View {
        VStack {
            if isLoading {
                Image(systemName: "brain")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("AI 분석 중...")
                    .font(.caption2)
                    .foregroundColor(.gray)
            } else if let error = errorMessage {
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                    Button("재시도") { 
                        Task { await loadFishingAnalysis() } 
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
            } else if let analysis = fishingAnalysis {
                Button {
                    showDetailSheet = true
                } label: {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                        .symbolEffect(.pulse)
                                    Text("AI 낚시")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    
                                    if let lastTime = lastAnalysisTime {
                                        let minutesAgo = Int(Date().timeIntervalSince(lastTime) / 60)
                                        if minutesAgo < 60 {
                                            Text("(\(minutesAgo)분 전)")
                                                .font(.system(size: 8))
                                                .foregroundColor(.gray.opacity(0.6))
                                        }
                                    }
                                }
                                
                                HStack(alignment: .lastTextBaseline, spacing: 2) {
                                    Text("\(String(format: "%.1f", analysis.fishingScore))")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(scoreColor(analysis.fishingScore))
                                    Text("/10")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .stroke(scoreColor(analysis.fishingScore).opacity(0.3), lineWidth: 2)
                                    .frame(width: 35, height: 35)
                                
                                Circle()
                                    .trim(from: 0, to: analysis.fishingScore / 10)
                                    .stroke(scoreColor(analysis.fishingScore), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .frame(width: 35, height: 35)
                                    .rotationEffect(.degrees(-90))
                                
                                Text(getScoreEmoji(analysis.fishingScore))
                                    .font(.caption)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                                    .frame(width: 10)
                                Text("시간:")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                                Text(analysis.bestTimeToday)
                                    .font(.system(size: 10))
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                Spacer()
                            }
                            
                            if !analysis.recommendedSpecies.isEmpty {
                                HStack {
                                    Image(systemName: "fish.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                        .frame(width: 10)
                                    Text("어종:")
                                        .font(.system(size: 10))
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                    Text(analysis.recommendedSpecies.prefix(2).joined(separator: ", "))
                                        .font(.system(size: 10))
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    Spacer()
                                }
                            }
                            
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                                    .frame(width: 10)
                                Text("장소:")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                                Text(analysis.topLocation.name)
                                    .font(.system(size: 10))
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                        
                        HStack {
                            Text("자세히 보기")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.8))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                    .padding(12)
                }
                .buttonStyle(PlainButtonStyle())
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(scoreColor(analysis.fishingScore).opacity(0.3), lineWidth: 1)
                        )
                )
                .sheet(isPresented: $showDetailSheet) {
                    FishingDetailSheet(analysis: analysis)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "brain")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("AI 낚시 분석")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await loadFishingAnalysisIfNeeded()
        }
    }
    
    private func loadFishingAnalysisIfNeeded() async {
        if let lastTime = lastAnalysisTime,
           fishingAnalysis != nil,
           Date().timeIntervalSince(lastTime) < 3600 { // 3600 seconds = 1 hour
            return
        }
        
        await loadFishingAnalysis()
    }
    
    private func loadFishingAnalysis() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let lat = locationManager.latitude != 0.0 ? locationManager.latitude : 35.1796
            let lon = locationManager.longitude != 0.0 ? locationManager.longitude : 129.0756
            
            async let weatherData = try WeatherService.shared.fetchWeather(lat: lat, lon: lon)
            async let tideData = try TideService.shared.fetchTideData(lat: lat, lon: lon)
            async let pointData = try PointService.shared.fetchPoints(lat: lat, lon: lon)
            
            let (weather, tides, points) = try await (weatherData, tideData, pointData)
            
            let prompt = createFishingAnalysisPrompt(
                weather: weather,
                tides: tides,
                points: points.fishing_point,
                lat: lat,
                lon: lon
            )
            
            let response = try await GeminiService.shared.generateContent(prompt: prompt)
            
            guard let firstCandidate = response.candidates.first,
                  let firstPart = firstCandidate.content.parts.first,
                  let responseText = firstPart.text else {
                throw GeminiError.noContentReceived
            }
            
            let analysis = try parseAIResponse(responseText)
            
            await MainActor.run {
                self.fishingAnalysis = analysis
                self.lastAnalysisTime = Date()
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "AI 분석 실패: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    private func createFishingAnalysisPrompt(
        weather: WeatherResponse,
        tides: [Tide],
        points: [Point],
        lat: Double,
        lon: Double
    ) -> String {
        let currentWeather = weather.weather.weather.first
        let currentTide = tides.first
        
        var prompt = """
        You are an expert fishing guide AI analyzing current conditions for optimal fishing success.
        
        CURRENT CONDITIONS:
        Location: Latitude \(lat), Longitude \(lon)
        
        Weather:
        - Temperature: \(currentWeather?.temp ?? "N/A")°C
        - Sky: \(currentWeather?.sky ?? "N/A") (code: \(currentWeather?.sky_code ?? "N/A"))
        - Wind: \(currentWeather?.winddir ?? "N/A") direction, \(currentWeather?.windspd ?? "N/A")m/s
        - Wave Height: \(currentWeather?.pago ?? "N/A")m
        - Humidity: \(currentWeather?.humidity ?? "N/A")%
        - Rain: \(currentWeather?.rain ?? "0")mm
        
        Sea Temperature: \(weather.temp.obs_wt)°C
        
        Tide Information:
        """
        
        if let tide = currentTide {
            prompt += """
            - Date: \(tide.pThisDate)
            - Location: \(tide.pSelArea)
            - Moon phase: \(tide.pMul)
            - Tide times: \(tide.pTime1), \(tide.pTime2), \(tide.pTime3), \(tide.pTime4)
            """
        }
        
        prompt += "\n\nAvailable Fishing Points:\n"
        for (index, point) in points.prefix(5).enumerated() {
            prompt += """
            \(index + 1). \(point.point_nm)
               - Depth: \(point.dpwt)
               - Bottom: \(point.material)
               - Target Fish: \(point.target)
               - Address: \(point.addr)
            
            """
        }
        
        prompt += """
        
        ANALYSIS REQUIREMENTS:
        1. Calculate a fishing success score (0-10) based on all conditions
        2. Identify the best fishing time window today
        3. Recommend top 3 fish species likely to bite
        4. Select the best fishing location and explain why
        5. Analyze current tide and weather impact
        6. Provide actionable insights and tips
        7. Include any safety warnings if conditions are challenging
        
        Consider factors like:
        - Tide timing and moon phase effects on fish behavior
        - Weather conditions (barometric pressure, wind, temperature)
        - Seasonal fish activity patterns
        - Water temperature impact on species
        - Location-specific advantages
        
        IMPORTANT: Respond ONLY with valid JSON in this exact format (respond in Korean for user-facing text):
        {
          "fishingScore": 8.5,
          "bestTimeToday": "오후 2-4시",
          "recommendedSpecies": ["농어", "숭어", "가자미"],
          "topLocation": {
            "name": "포인트명",
            "reason": "선택 이유",
            "distance": "거리 (선택사항)"
          },
          "conditions": {
            "tideStatus": "조석 상황",
            "weatherStatus": "날씨 영향",
            "waterTemp": "수온 정보 (선택사항)",
            "moonPhase": "달 정보 (선택사항)"
          },
          "insights": {
            "summary": "오늘 낚시 전망 요약",
            "tips": ["팁1", "팁2", "팁3"],
            "warnings": ["주의사항1", "주의사항2"]
          }
        }
        """
        
        return prompt
    }
    
    private func parseAIResponse(_ responseText: String) throws -> FishingAnalysis {
        let cleanedText = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw GeminiError.invalidJSON
        }
        
        do {
            let analysis = try JSONDecoder().decode(FishingAnalysis.self, from: jsonData)
            return analysis
        } catch {
            print("JSON Parsing Error: \(error)")
            print("Response text: \(cleanedText)")
            throw GeminiError.invalidJSON
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 8...10: return .green
        case 6..<8: return .orange
        case 4..<6: return .yellow
        default: return .red
        }
    }
    
    private func getScoreEmoji(_ score: Double) -> String {
        switch score {
        case 9...10: return "🎣"
        case 7..<9: return "🐟"
        case 5..<7: return "🌊"
        case 3..<5: return "⚠️"
        default: return "❌"
        }
    }
}

struct FishingDetailSheet: View {
    let analysis: FishingAnalysis
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("AI 낚시 분석")
                            .font(.headline)
                            .fontWeight(.bold)
                        HStack {
                            Text("낚시 지수: \(String(format: "%.1f", analysis.fishingScore))/10")
                                .font(.subheadline)
                                .foregroundColor(scoreColor(analysis.fishingScore))
                        }
                    }
                    Spacer()
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                DetailSection(
                    icon: "clock.fill",
                    title: "최적 시간",
                    content: analysis.bestTimeToday,
                    color: .green
                )
                
                DetailSection(
                    icon: "location.fill",
                    title: "추천 장소",
                    content: "\(analysis.topLocation.name)\n\(analysis.topLocation.reason)",
                    color: .blue
                )
                
                if !analysis.recommendedSpecies.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "fish.fill")
                                .foregroundColor(.orange)
                            Text("추천 어종")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        ForEach(analysis.recommendedSpecies, id: \.self) { species in
                            HStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                Text(species)
                                    .font(.caption)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cloud.sun.fill")
                            .foregroundColor(.cyan)
                        Text("현재 조건")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("조석: \(analysis.conditions.tideStatus)")
                            .font(.caption)
                        Text("날씨: \(analysis.conditions.weatherStatus)")
                            .font(.caption)
                        if let temp = analysis.conditions.waterTemp {
                            Text("수온: \(temp)")
                                .font(.caption)
                        }
                        if let moon = analysis.conditions.moonPhase {
                            Text("달: \(moon)")
                                .font(.caption)
                        }
                    }
                    .padding(.leading, 20)
                }
                
                if !analysis.insights.tips.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("낚시 팁")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        ForEach(analysis.insights.tips, id: \.self) { tip in
                            HStack(alignment: .top) {
                                Text("•")
                                    .foregroundColor(.yellow)
                                Text(tip)
                                    .font(.caption)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                if let warnings = analysis.insights.warnings, !warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("주의사항")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        ForEach(warnings, id: \.self) { warning in
                            HStack(alignment: .top) {
                                Text("⚠️")
                                Text(warning)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                DetailSection(
                    icon: "doc.text.fill",
                    title: "종합 분석",
                    content: analysis.insights.summary,
                    color: .purple
                )
            }
            .padding()
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 8...10: return .green
        case 6..<8: return .orange  
        case 4..<6: return .yellow
        default: return .red
        }
    }
    
    private struct DetailSection: View {
        let icon: String
        let title: String
        let content: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 20)
            }
        }
    }
}
