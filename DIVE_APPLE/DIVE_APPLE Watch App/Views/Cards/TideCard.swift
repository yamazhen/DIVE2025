import SwiftUI

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

                                let timePartsTwo = currentTide.pTime2.components(separatedBy: " ")
                                VStack {
                                    Text(timePartsTwo[0])
                                    HStack {
                                        Text(timePartsTwo[1]).font(.system(size: 10))
                                        Text(timePartsTwo[2]).font(.system(size: 10))
                                            .foregroundColor(Color.red)
                                    }
                                }
                                let timePartsFour = currentTide.pTime4.components(separatedBy: " ")
                                VStack {
                                    Text(timePartsFour[0])
                                    HStack {
                                        Text(timePartsFour[1]).font(.system(size: 10))
                                        Text(timePartsFour[2]).font(.system(size: 10))
                                            .foregroundColor(Color.red)
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

                                let timePartsOne = currentTide.pTime1.components(separatedBy: " ")
                                VStack {
                                    Text(timePartsOne[0])
                                    HStack {
                                        Text(timePartsOne[1]).font(.system(size: 10))
                                        Text(timePartsOne[2]).font(.system(size: 10))
                                            .foregroundColor(Color.blue)
                                    }
                                }
                                let timePartsThree = currentTide.pTime3.components(separatedBy: " ")
                                VStack {
                                    Text(timePartsThree[0])
                                    HStack {
                                        Text(timePartsThree[1]).font(.system(size: 10))
                                        Text(timePartsThree[2]).font(.system(size: 10))
                                            .foregroundColor(Color.blue)
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
