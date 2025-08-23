import SwiftUI

func parseTideTime(_ timeString: String) -> (time: String, height: String?, arrow: String?) {
    let parts = timeString.components(separatedBy: " ")
    let time = parts.count > 0 ? parts[0] : "--:--"

    var height: String?
    var arrow: String?

    for part in parts {
        if part.hasPrefix("(") && part.contains(")") {
            height = part
        }
        if part.contains("▲") || part.contains("▼") {
            arrow = part
        }
    }

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
    @State private var showGraphView = false

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
                    ZStack {
                        TideInfoView(currentTide: currentTide)
                            .opacity(showGraphView ? 0 : 1)
                            .scaleEffect(showGraphView ? 0.95 : 1)
                            .offset(y: showGraphView ? -10 : 0)
                        
                        TideGraphView(currentTide: currentTide)
                            .opacity(showGraphView ? 1 : 0)
                            .scaleEffect(showGraphView ? 1 : 0.95)
                            .offset(y: showGraphView ? 0 : 10)
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.5).delay(0.05)) {
                            showGraphView.toggle()
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
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}

struct TideInfoView: View {
    let currentTide: Tide

    var body: some View {
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
    }

    private func getCurrentTideStatus() -> (text: String, color: Color) {
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
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}

struct TideGraphView: View {
    let currentTide: Tide

    var body: some View {
        ZStack {
            Color.black
                .cornerRadius(8)

            TideGraphContent(currentTide: currentTide)
        }
    }
}

struct TideGraphContent: View {
    let currentTide: Tide

    var body: some View {
        GeometryReader { geometry in
            let points = getTidePoints()
            let width = geometry.size.width - 32
            let height = geometry.size.height - 60

            VStack {
                Canvas { context, size in
                    drawTideGraph(
                        context: context, size: size, points: points, width: width, height: height)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                moonLabel()
            }
        }
    }

    private func drawTideGraph(
        context: GraphicsContext, size: CGSize, points: [TidePoint], width: CGFloat, height: CGFloat
    ) {
        let minHeight = getMinHeight()
        let maxHeight = getMaxHeight()
        let heightRange = maxHeight - minHeight

        guard heightRange > 0 && points.count >= 2 else { return }

        var graphPoints: [CGPoint] = []
        for (index, point) in points.enumerated() {
            let normalizedHeight = CGFloat((point.height - minHeight) / heightRange)
            let x = 16 + CGFloat(index) * (width / CGFloat(points.count - 1))
            let centerY = size.height / 2
            let verticalSpread = height * 0.4
            let y = centerY - (normalizedHeight - 0.5) * verticalSpread

            graphPoints.append(CGPoint(x: x, y: y))
        }

        var path = Path()
        path.move(to: graphPoints[0])

        for i in 1..<graphPoints.count {
            let currentPoint = graphPoints[i]
            let previousPoint = graphPoints[i - 1]

            let midX = (previousPoint.x + currentPoint.x) / 2
            let controlPoint1 = CGPoint(x: midX, y: previousPoint.y)
            let controlPoint2 = CGPoint(x: midX, y: currentPoint.y)

            path.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
        }

        context.stroke(path, with: .color(.gray), lineWidth: 2)

        for (index, point) in points.enumerated() {
            let graphPoint = graphPoints[index]

            let circleRect = CGRect(
                x: graphPoint.x - 6,
                y: graphPoint.y - 6,
                width: 12,
                height: 12
            )
            context.fill(Path(ellipseIn: circleRect), with: .color(point.isHigh ? .red : .blue))

            let labelY = graphPoint.y + (point.isHigh ? -25 : 25)
            let labelPoint = CGPoint(x: graphPoint.x, y: labelY)

            context.draw(
                Text(point.time)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(point.isHigh ? .red : .blue),
                at: labelPoint,
                anchor: .center
            )
        }
    }

    private func currentTimeBar(width: CGFloat, geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.8))
            .frame(width: 2, height: geometry.size.height - 40)
            .position(x: getCurrentTimePosition(in: width) + 16, y: geometry.size.height / 2)
    }

    private func timeLabels(points: [TidePoint]) -> some View {
        EmptyView()
    }

    private func moonLabel() -> some View {
        HStack(spacing: 3) {
            Image(systemName: getMoonIcon(for: currentTide.pMul))
                .font(.system(size: 10))
                .foregroundColor(.yellow)
            Text(currentTide.pMul)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(6)
        .padding(.bottom, 4)
    }

    private func getTidePoints() -> [TidePoint] {
        let tides = [
            currentTide.pTime1,
            currentTide.pTime2,
            currentTide.pTime3,
            currentTide.pTime4,
        ]

        return tides.map { tideData in
            let parsed = parseTideTime(tideData)
            let isHigh = tideData.contains("▲")
            
            // Extract numeric value from parentheses for graph calculation
            let heightValue: Float
            if let heightString = parsed.height {
                let numericString = heightString.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                heightValue = Float(numericString) ?? 100.0
            } else {
                heightValue = 100.0
            }

            return TidePoint(
                time: parsed.time,
                height: heightValue,
                heightText: parsed.height ?? "",
                isHigh: isHigh
            )
        }
    }

    private func getMinHeight() -> Float {
        return getTidePoints().map { $0.height }.min() ?? 0
    }

    private func getMaxHeight() -> Float {
        return getTidePoints().map { $0.height }.max() ?? 200
    }

    private func getCurrentTimePosition(in width: CGFloat) -> CGFloat {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: now)

        let points = getTidePoints()
        let times = points.map { $0.time }
        let stepX = width / CGFloat(points.count - 1)

        let currentMinutes = timeToMinutes(currentTime)

        for i in 0..<times.count - 1 {
            let startMinutes = timeToMinutes(times[i])
            let endMinutes = timeToMinutes(times[i + 1])

            if currentMinutes >= startMinutes && currentMinutes <= endMinutes {
                let progress =
                    CGFloat(currentMinutes - startMinutes) / CGFloat(endMinutes - startMinutes)
                return CGFloat(i) * stepX + progress * stepX
            }
        }

        let firstMinutes = timeToMinutes(times[0])
        let lastMinutes = timeToMinutes(times[times.count - 1])

        if currentMinutes < firstMinutes {
            let progress =
                CGFloat(currentMinutes + 1440 - lastMinutes)
                / CGFloat(firstMinutes + 1440 - lastMinutes)
            return width * progress
        } else {
            let progress =
                CGFloat(currentMinutes - lastMinutes) / CGFloat(firstMinutes + 1440 - lastMinutes)
            return width * progress
        }
    }

    private func timeToMinutes(_ time: String) -> Int {
        let components = time.components(separatedBy: ":")
        guard components.count == 2,
            let hours = Int(components[0]),
            let minutes = Int(components[1])
        else {
            return 0
        }
        return hours * 60 + minutes
    }
}

struct TidePoint {
    let time: String
    let height: Float
    let heightText: String
    let isHigh: Bool
}

struct SmoothTideWave: Shape {
    let tideData: [TidePoint]
    let width: CGFloat
    let height: CGFloat
    let minHeight: Float
    let maxHeight: Float

    func path(in rect: CGRect) -> Path {
        var path = Path()

        guard tideData.count >= 2 else { return path }

        let heightRange = maxHeight - minHeight
        guard heightRange > 0 else { return path }

        let tidePoints = tideData.enumerated().map { index, point in
            let x = 16 + CGFloat(index) * (width / CGFloat(tideData.count - 1))
            let normalizedHeight = CGFloat((point.height - minHeight) / heightRange)

            let centerY = rect.height / 2
            let verticalSpread = height * 0.8
            let y = centerY - (normalizedHeight - 0.5) * verticalSpread

            return CGPoint(x: x, y: y)
        }

        path.move(to: tidePoints[0])

        for i in 1..<tidePoints.count {
            let currentPoint = tidePoints[i]
            let previousPoint = tidePoints[i - 1]

            let midX = (previousPoint.x + currentPoint.x) / 2
            let controlPoint1 = CGPoint(x: midX, y: previousPoint.y)
            let controlPoint2 = CGPoint(x: midX, y: currentPoint.y)

            path.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
        }

        return path
    }
}
