import SwiftUI

// Split tide string safely
func parseTideTime(_ timeString: String) -> (time: String, height: String?, arrow: String?) {
    let parts = timeString.components(separatedBy: " ")
    let time = parts.count > 0 ? parts[0] : "--:--"
    let height = parts.count > 1 ? parts[1] : nil
    let arrow = parts.count > 2 ? parts[2] : nil
    return (time, height, arrow)
}

struct TideCard: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var tides: [Tide] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading tides...").font(.caption2)
            } else if let error = errorMessage {
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle").foregroundColor(.orange).font(
                        .caption)
                    Text(error).font(.caption2).multilineTextAlignment(.center)
                    Button("Retry") { Task { await loadTideData() } }.font(.caption2)
                        .foregroundColor(.blue)
                }
            } else if tides.isEmpty {
                Text("No tide data").font(.caption)
            } else {
                if let currentTide = getCurrentTideData() {
                    VStack {
                        Text(
                            currentTide.pSelArea.replacingOccurrences(of: "<br>", with: "") + " 0 "
                                + currentTide.pMul)
                        Divider()
                        HStack {
                            VStack(spacing: 8, ) {
                                Text("민조")
                                    .font(.system(size: 12))
                                    .padding(.horizontal, 8)
                                    .background(Color.red)
                                    .cornerRadius(6)

                                let tide2 = parseTideTime(currentTide.pTime2)
                                VStack {
                                    Text(tide2.time)
                                    HStack {
                                        if let h = tide2.height { Text(h).font(.system(size: 10)) }
                                        if let a = tide2.arrow { Text(a).font(.system(size: 10)).foregroundColor(.red) }
                                    }
                                }

                                let tide4 = parseTideTime(currentTide.pTime4)
                                VStack {
                                    Text(tide4.time)
                                    HStack {
                                        if let h = tide4.height { Text(h).font(.system(size: 10)) }
                                        if let a = tide4.arrow { Text(a).font(.system(size: 10)).foregroundColor(.red) }
                                    }
                                }
                            }
                            Divider()
                            VStack(spacing: 8) {
                                Text("간조")
                                    .font(.system(size: 12))
                                    .padding(.horizontal, 8)
                                    .background(Color.blue)
                                    .cornerRadius(6)

                                let tide1 = parseTideTime(currentTide.pTime1)
                                VStack {
                                    Text(tide1.time)
                                    HStack {
                                        if let h = tide1.height { Text(h).font(.system(size: 10)) }
                                        if let a = tide1.arrow { Text(a).font(.system(size: 10)).foregroundColor(.blue) }
                                    }
                                }

                                let tide3 = parseTideTime(currentTide.pTime3)
                                VStack {
                                    Text(tide3.time)
                                    HStack {
                                        if let h = tide3.height { Text(h).font(.system(size: 10)) }
                                        if let a = tide3.arrow { Text(a).font(.system(size: 10)).foregroundColor(.blue) }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("No current tide data")
                        .font(.caption)
                }
            }
        }
        .task {
            await loadTideData()
        }
    }

    private func loadTideData() async {
        isLoading = true
        errorMessage = nil

        let lat = locationManager.latitude != 0.0 ? locationManager.latitude : 35.1796
        let lon = locationManager.longitude != 0.0 ? locationManager.longitude : 129.0756

        do {
            tides = try await TideService.shared.fetchTideData(lat: lat, lon: lon)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func getCurrentTideData() -> Tide? {
        let today = DateFormatter()
        today.dateFormat = "yyyy-M-d"
        let todayString = today.string(from: Date())

        return tides.first { tide in tide.pThisDate.contains(todayString) }
    }
}
