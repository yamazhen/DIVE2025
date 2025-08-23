import SwiftUI
import WatchKit

@main
struct DIVE_APPLE_Watch_AppApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthService = HealthService()
    @StateObject private var alertService = AlertService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(healthService)
                .environmentObject(alertService)
                .onAppear {
                    healthService.requestHealthPermissions()
                    alertService.startMonitoring()
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: WKExtension.applicationWillEnterForegroundNotification)
                ) { _ in
                    if let location = locationManager.location {
                        Task {
                            await alertService.checkAllAlerts(
                                lat: location.coordinate.latitude,
                                lon: location.coordinate.longitude)
                        }
                    }
                }
        }
    }
}
