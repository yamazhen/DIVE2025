import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TideCard()
            WeatherCard()
            PointCard()
            HealthCard()
            AlertCard()
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

#Preview {
    ContentView()
}
