import Foundation
import SwiftUI
import WatchKit

class EmergencyGestureService: ObservableObject {
    @Published var tapCount: Int = 0
    @Published var isEmergencyActive: Bool = false

    private var healthService: HealthService?
    private var lastTapTime: Date = Date()
    private let tapTimeWindow: TimeInterval = 0.5  // time in second for window of tap
    private let requiredTaps: Int = 3

    func configure(healthService: HealthService) {
        self.healthService = healthService
    }

    func handleTap() {
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)

        if timeSinceLastTap > tapTimeWindow {
            tapCount = 1
        } else {
            tapCount += 1
        }

        lastTapTime = now

        if tapCount >= requiredTaps {
            triggerEmergency()
            resetTapCount()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + tapTimeWindow) { [weak self] in
            if let self = self, now.timeIntervalSince(self.lastTapTime) >= self.tapTimeWindow {
                self.resetTapCount()
            }
        }
    }

    private func triggerEmergency() {
        isEmergencyActive = true

        let emergencyAlert = WKAlertAction(title: "Call Emergency", style: .destructive) {
            let emergencyService = EmergencyService()
            emergencyService.callPolice()
            self.isEmergencyActive = false
        }

        let cancelAlert = WKAlertAction(title: "Cancel", style: .cancel) {
            self.isEmergencyActive = false
        }

        WKExtension.shared().rootInterfaceController?.presentAlert(
            withTitle: "EMERGENCY",
            message: "Call 112?",
            preferredStyle: .alert,
            actions: [emergencyAlert, cancelAlert]
        )

        WKInterfaceDevice.current().play(.directionUp)

        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.isEmergencyActive = false
        }
    }

    private func resetTapCount() {
        tapCount = 0
    }

    func testEmergencyGesture() {
        tapCount = requiredTaps
        triggerEmergency()
        resetTapCount()
    }
}
