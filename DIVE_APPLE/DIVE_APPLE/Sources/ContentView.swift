import CoreLocation
import SwiftUI

public struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    public init() {}

    // fuck you nodirbek
    public var body: some View {
        VStack(spacing: 20) {
            Text("DIVE2025")
            if let location = locationManager.location {
                VStack {
                    Text("Lat: \(location.coordinate.latitude, specifier: "%.6f")")
                    Text("Long: \(location.coordinate.longitude, specifier: "%.6f")")
                }
            } else {
                Text("Getting location...")
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
