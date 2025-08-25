import SwiftUI
import MapKit

struct PointCard: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var points: [Point] = []
    @State private var info: PointInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPoint: Point?

    var body: some View {
        VStack {
            if isLoading {
                Image(systemName: "slowmo")
                    .symbolEffect(.rotate.byLayer, options: .repeat(.continuous))
            } else if let error = errorMessage {
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle").foregroundColor(.orange).font(
                        .caption)
                    Text(error).font(.caption2).multilineTextAlignment(.center)
                    Button("재시도") { Task { await loadPoints() } }.font(.caption2)
                        .foregroundColor(.blue)
                }
            } else if points.isEmpty {
                Text("조석 낚시 포인트 없음").font(.caption)
            } else {
                // Grid of fishing point cards -> Vertical list
                ScrollView {
                    LazyVStack(spacing: 20) { // <- now spacing works
                        ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                            SinglePointCard(point: point) {
                                selectedPoint = point
                            }
                        }
                    }
                    .padding(.horizontal, 16) // keep wide horizontal padding
                }.padding(.top, -20)

            }
        }
        .task {
            await loadPoints()
        }
        .sheet(item: $selectedPoint) { point in
            if let info = info {
                PointDetailView(point: point, info: info)
            } else {
                Text("사용 가능한 세부 정보 없음")
                    .padding()
            }
        }
    }

    private func loadPoints() async {
        isLoading = true
        errorMessage = nil

        let lat = locationManager.latitude != 0.0 ? locationManager.latitude : 35.1796
        let lon = locationManager.longitude != 0.0 ? locationManager.longitude : 129.0756

        do {
            let response = try await PointService.shared.fetchPoints(lat: lat, lon: lon)
            self.points = response.fishing_point
            self.info = response.info
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
struct SinglePointCard: View {
    let point: Point
    let onTap: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let cardWidth = width * 1
            let cardHeight = cardWidth * 1
            
            Button(action: onTap) {
                ZStack(alignment: .bottom) {
                    // Background image
                    if !point.photo.isEmpty {
                        let baseURL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String
                        AsyncImage(
                            url: baseURL.flatMap { URL(string: "https://\($0)/img/point_img/thumbnail/\(point.photo)") }
                        ) { img in
                            img.resizable()
                                .scaledToFill()
                                .frame(width: cardWidth, height: cardHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: cardWidth, height: cardHeight)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: cardWidth * 0.12)) // scale icon size too
                                        .foregroundColor(.gray)
                                )
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: cardWidth, height: cardHeight)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: cardWidth * 0.12))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Overlay text (point name)
                    Text(point.point_nm)
                        .font(.system(size: cardWidth * 0.12)) // scale text size
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(6)
                        .frame(maxWidth: .infinity)
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)
            .frame(width: cardWidth, height: cardHeight)
            .position(x: geo.size.width / 2, y: geo.size.height / 2) // center it
        }
        .frame(height: 180) // outer container ensures GeometryReader doesn’t take full height
    }
}

struct PointDetailView: View {
    let point: Point
    let info: PointInfo
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var region: MKCoordinateRegion = .init()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                
                // Point name chip (top left)
                HStack {
                    Text(point.point_nm)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())
                    
                    Spacer()
                }
                
                // Address
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .symbolEffect(.bounce)
                    Text(point.addr)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Important details line by line
                VStack(alignment: .leading, spacing: 6) {
                    // Depth
                    HStack(spacing: 6) {
                        Image(systemName: "water.waves")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .frame(width: 16)
                            .foregroundColor(.secondary)
                            .symbolEffect(.wiggle.byLayer)
                        Text("깊이: \(point.dpwt)")
                            .font(.caption2)
                    }
                    
                    // Sea bottom type
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.caption2)
                            .foregroundColor(.brown)
                            .frame(width: 16)
                            .symbolEffect(.scale.byLayer)
                        Text("아래: \(point.material.trimmingCharacters(in: .whitespacesAndNewlines))")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
                
                // Target fishes section
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "fish.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .symbolEffect(.bounce.down.byLayer, options: .repeat(.periodic(delay: 3.0)))
                            .frame(width: 16)
                        Text("어종")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    
                    // Parse and display fish with methods
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(parseTargetFish(point.target), id: \.name) { fish in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange.opacity(0.6))
                                    .frame(width: 4, height: 4)
                                
                                Text(fish.name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                HStack(spacing: 2) {
                                    ForEach(fish.methods.prefix(3), id: \.self) { method in
                                        Text(method)
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.gray.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Map section
                Map(position: .constant(.region(region))) {
                    // Fishing spot marker
                    if let spotLat = Double(point.lat), let spotLon = Double(point.lon) {
                        Marker("\(point.point_nm)", systemImage: "fish.fill",
                               coordinate: CLLocationCoordinate2D(latitude: spotLat, longitude: spotLon))
                            .tint(.red)
                    }
                    
                    // User location marker
                    Marker("나요", systemImage: "location.fill",
                           coordinate: CLLocationCoordinate2D(latitude: locationManager.latitude,
                                                              longitude: locationManager.longitude))
                        .tint(.blue)
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onAppear {
                    if let region = makeRegion(point: point,
                                               userLat: locationManager.latitude,
                                               userLon: locationManager.longitude) {
                        self.region = region
                    }
                }
                
                // Additional information sections
                if !info.intro.isEmpty {
                    DetailSection(icon: "book.fill", title: "정보", content: info.intro, color: .green)
                }
                
                if !info.forecast.isEmpty {
                    DetailSection(icon: "cloud.sun.fill", title: "예보", content: info.forecast, color: .blue)
                }
                
                if !info.ebbf.isEmpty {
                    DetailSection(icon: "arrow.triangle.2.circlepath", title: "조수", content: info.ebbf, color: .cyan)
                }
                
                if !info.notice.isEmpty {
                    DetailSection(icon: "exclamationmark.triangle.fill", title: "주의", content: info.notice, color: .red)
                }
                
                // Seasonal information
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "thermometer.medium")
                            .font(.caption2)
                            .foregroundColor(.purple)
                            .frame(width: 16)
                        Text("계절 정보")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        SeasonRow(emoji: "🌸", season: "봄", temp: info.wtemp_sp, fish: info.fish_sp)
                        SeasonRow(emoji: "☀️", season: "여름", temp: info.wtemp_su, fish: info.fish_su)
                        SeasonRow(emoji: "🍂", season: "가을", temp: info.wtemp_fa, fish: info.fish_fa)
                        SeasonRow(emoji: "❄️", season: "겨울", temp: info.wtemp_wi, fish: info.fish_wi)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Helper Views
    
    private struct DetailSection: View {
        let icon: String
        let title: String
        let content: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(color)
                        .frame(width: 16)
                    Text(title)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                
                Text(content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .padding(.leading, 22)
            }
        }
    }
    
    private struct SeasonRow: View {
        let emoji: String
        let season: String
        let temp: String
        let fish: String
        
        var body: some View {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.caption2)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(season): \(temp)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if !fish.isEmpty {
                        Text(fish)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding(.leading, 22)
        }
    }
    
    // MARK: - Helper Functions
    
    private func parseTargetFish(_ raw: String) -> [TargetFish] {
        return raw.split(separator: "▶")
            .compactMap { segment in
                let parts = segment.split(separator: "-", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                
                let fishName = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let methodsString = String(parts[1]).trimmingCharacters(in: .whitespaces)
                let methods = methodsString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                
                return TargetFish(name: fishName, methods: methods)
            }
    }
    
    private func makeRegion(point: Point, userLat: Double, userLon: Double) -> MKCoordinateRegion? {
        guard let spotLat = Double(point.lat),
              let spotLon = Double(point.lon) else { return nil }
        
        let spot = CLLocationCoordinate2D(latitude: spotLat, longitude: spotLon)
        let user = CLLocationCoordinate2D(latitude: userLat, longitude: userLon)
        
        // Midpoint
        let center = CLLocationCoordinate2D(
            latitude: (spot.latitude + user.latitude) / 2,
            longitude: (spot.longitude + user.longitude) / 2
        )
        
        // Compute absolute deltas
        let latDelta = abs(spot.latitude - user.latitude)
        let lonDelta = abs(spot.longitude - user.longitude)
        
        // Add some padding (so markers aren’t at the very edge)
        let paddingFactor = 2.2
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta * paddingFactor, 0.01),
            longitudeDelta: max(lonDelta * paddingFactor, 0.01)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }

}

// MARK: - Supporting Types

struct TargetFish {
    let name: String
    let methods: [String]
}
