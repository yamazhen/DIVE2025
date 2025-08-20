import SwiftUI

struct LocationCard: View {
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        VStack {
            Text("Location").font(.headline)

            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                Text("Lat: \(locationManager.latitude, specifier: "%.6f")")
                Text("Long: \(locationManager.longitude, specifier: "%.6f")")
            case .denied, .restricted:
                Text("Location access denied")
                Text("Enable in Settings")
            case .notDetermined:
                Text("Requesting location access...")
            @unknown default:
                Text("Location status unknown")
            }
        }
    }
}
