import SwiftUI
import WatchKit

@main
struct DIVE_APPLE_Watch_AppApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var healthService = HealthService()
    @StateObject private var alertService = AlertService.shared
    @StateObject private var emergencyGestureService = EmergencyGestureService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(healthService)
                .environmentObject(alertService)
                .environmentObject(emergencyGestureService)
                .onAppear {
                    healthService.requestHealthPermissions()
                    alertService.startMonitoring()
                    emergencyGestureService.configure(healthService: healthService)
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
