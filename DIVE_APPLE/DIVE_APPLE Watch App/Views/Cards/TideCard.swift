import SwiftUI

func parseTideTime(_ timeString: String) -> (time: String, height: String?, arrow: String?) {
    let parts = timeString.components(separatedBy: " ")
    let time = parts.count > 0 ? parts[0] : "--:--"
    let height = parts.count > 1 ? parts[1] : nil
    let arrow = parts.count > 2 ? parts[2] : nil
    return (time, height, arrow)
}

func getMoonIcon(for mulValue: String) -> String {
    let cleanValue = mulValue.replacingOccurrences(of: "물", with: "")
        .trimmingCharacters(in: .whitespaces)

    guard let mul = Int(cleanValue) else { return "moonphase.full.moon" }

    switch mul {
    case 1...2:
        return "moonphase.new.moon"
    case 3...4:
        return "moonphase.waxing.crescent"
    case 5...6:
        return "moonphase.first.quarter"
    case 7...8:
        return "moonphase.waxing.gibbous"
    case 9...10:
        return "moonphase.full.moon"
    case 11...12:
        return "moonphase.waning.gibbous"
    case 13...14:
        return "moonphase.last.quarter"
    case 15:
        return "moonphase.waning.crescent"
    default:
        return "moonphase.full.moon"
    }
}

struct TideCard: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var tides: [Tide] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                    Button("재시도") { Task { await loadTideData() } }.font(.caption2)
                        .foregroundColor(.blue)
                }
            } else if tides.isEmpty {
                Text("조석 데이터 없음").font(.caption)
            } else {
                if let currentTide = getCurrentTideData() {
                    VStack(spacing: 4) {
                        VStack {
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(getCurrentTideStatus().text).font(
                                                .system(size: 24)
                                            )
                                            .fontWeight(.bold)
                                            .foregroundColor(getCurrentTideStatus().color)
                                            HStack(spacing: 4) {
                                                Image(systemName: "clock")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.gray)
                                                Text(getNextTideInfo()).font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        Spacer()
                                        let parts = currentTide.pThisDate.split(separator: "-")
                                        Text("\(parts[1]).\(parts[2]) \(parts[3])")
                                            .font(.system(size: 12))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                }
                                Spacer()
                            }
                        }
                        Spacer()
                        HStack {
                            VStack {
                                let tide1 = parseTideTime(currentTide.pTime1)
                                VStack {
                                    Text(tide1.time).font(.system(size: 12))
                                    HStack {
                                        if let h = tide1.height {
                                            Text(h).foregroundColor(Color.gray).font(
                                                .system(size: 10))
                                        }
                                        if let a = tide1.arrow {
                                            Text(a).foregroundColor(Color.blue).font(
                                                .system(size: 10))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.2))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                                let tide3 = parseTideTime(currentTide.pTime3)
                                VStack {
                                    Text(tide3.time).font(.system(size: 12))
                                    HStack {
                                        if let h = tide3.height {
                                            Text(h).foregroundColor(Color.gray).font(
                                                .system(size: 10))
                                        }
                                        if let a = tide3.arrow {
                                            Text(a).foregroundColor(Color.blue).font(
                                                .system(size: 10))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.2))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                            }
                            Spacer()
                            VStack {
                                let tide2 = parseTideTime(currentTide.pTime2)
                                VStack {
                                    Text(tide2.time).font(.system(size: 12))
                                    HStack {
                                        if let h = tide2.height {
                                            Text(h).foregroundColor(Color.gray).font(
                                                .system(size: 10))
                                        }
                                        if let a = tide2.arrow {
                                            Text(a).foregroundColor(Color.red).font(
                                                .system(size: 10))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.2))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                )
                                let tide4 = parseTideTime(currentTide.pTime4)
                                VStack {
                                    Text(tide4.time).font(.system(size: 12))
                                    HStack {
                                        if let h = tide4.height {
                                            Text(h).foregroundColor(Color.gray).font(
                                                .system(size: 10))
                                        }
                                        if let a = tide4.arrow {
                                            Text(a).foregroundColor(Color.red).font(
                                                .system(size: 10))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.2))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 1)
                                )
                            }
                        }
                        Spacer()
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                Text(
                                    currentTide.pSelArea.replacingOccurrences(of: "<br>", with: "")
                                )
                                .font(.system(size: 14))
                                .lineLimit(1)
                            }

                            Spacer()

                            HStack(spacing: 3) {
                                Image(systemName: getMoonIcon(for: currentTide.pMul))
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                                Text(currentTide.pMul)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                        }
                    }
                } else {
                    Text("현재 조석 데이터 없음")
                        .font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func getCurrentTideStatus() -> (text: String, color: Color) {
        guard let currentTide = getCurrentTideData() else { return ("알 수 없음", .gray) }

        let highTideMsg = "만조"
        let lowTideMsg = "간조"

        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: now)

        let time1 = parseTideTime(currentTide.pTime1).time
        let time2 = parseTideTime(currentTide.pTime2).time
        let time3 = parseTideTime(currentTide.pTime3).time
        let time4 = parseTideTime(currentTide.pTime4).time

        switch currentTime {
        case _ where currentTime < time1 || currentTime > time4:
            let isHigh = currentTide.pTime4.contains("▲")
            return (isHigh ? highTideMsg : lowTideMsg, isHigh ? .red : .blue)
        case _ where currentTime < time2:
            let isHigh = currentTide.pTime1.contains("▲")
            return (isHigh ? highTideMsg : lowTideMsg, isHigh ? .red : .blue)
        case _ where currentTime < time3:
            let isHigh = currentTide.pTime2.contains("▲")
            return (isHigh ? highTideMsg : lowTideMsg, isHigh ? .red : .blue)
        default:
            let isHigh = currentTide.pTime3.contains("▲")
            return (isHigh ? highTideMsg : lowTideMsg, isHigh ? .red : .blue)
        }
    }
    private func getNextTideInfo() -> String {
        guard let currentTide = getCurrentTideData() else { return "" }

        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTimeString = formatter.string(from: now)

        let tides = [
            (
                time: parseTideTime(currentTide.pTime1).time,
                isHigh: currentTide.pTime1.contains("▲")
            ),
            (
                time: parseTideTime(currentTide.pTime2).time,
                isHigh: currentTide.pTime2.contains("▲")
            ),
            (
                time: parseTideTime(currentTide.pTime3).time,
                isHigh: currentTide.pTime3.contains("▲")
            ),
            (
                time: parseTideTime(currentTide.pTime4).time,
                isHigh: currentTide.pTime4.contains("▲")
            ),
        ]

        for tide in tides {
            if tide.time > currentTimeString {
                let timeUntil = calculateTimeDifference(from: currentTimeString, to: tide.time)
                let tideType = tide.isHigh ? "만조" : "간조"
                return "\(tideType) \(timeUntil) 후"
            }
        }

        let tideType = tides[0].isHigh ? "만조" : "간조"
        return "내일 \(tideType)"
    }

    private func calculateTimeDifference(from startTime: String, to endTime: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let start = formatter.date(from: startTime),
            let end = formatter.date(from: endTime)
        else { return "" }

        let diff = end.timeIntervalSince(start)
        let hours = Int(diff) / 3600
        let minutes = Int(diff) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
