import SwiftUI

struct ContentView: View {
    @EnvironmentObject var emergencyGestureService: EmergencyGestureService
    
    var body: some View {
        TabView {
            SmartFishingCard()
            TideCard()
            WeatherCard()
            PointCard()
            HealthCard()
            AlertCard()
        }
        .tabViewStyle(PageTabViewStyle())
        .onTapGesture {
            emergencyGestureService.handleTap()
        }
        // Visual feedback overlay disabled - uncomment for debugging
        /*
        .overlay(
            VStack {
                if emergencyGestureService.tapCount > 0 {
                    HStack {
                        ForEach(0..<emergencyGestureService.tapCount, id: \.self) { _ in
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 10)
                    .animation(.easeInOut(duration: 0.2), value: emergencyGestureService.tapCount)
                }
                Spacer()
            }
        )
        */
    }
}

#Preview {
    ContentView()
}
