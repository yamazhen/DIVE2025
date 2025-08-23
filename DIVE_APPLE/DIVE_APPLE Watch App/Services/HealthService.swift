import Foundation
import HealthKit

struct HealthAlert {
    let message: String
    let type: AlertType

    enum AlertType {
        case low, high, normal, danger
    }
}

class HealthService: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var currentHeartRate: Double = 0
    @Published var isMonitoring = false
    @Published var healthAlert: HealthAlert?
    @Published var hasHealthPermission = false

    private var dangerAlertCooldown = false
    private let emergencyService = EmergencyService()

    func requestHealthPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }

        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToRead: Set = [heartRateType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) {
            [weak self] success, error in
            DispatchQueue.main.async {
                self?.hasHealthPermission = success
                if success {
                    self?.startHeartRateMonitoring()
                } else if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func startHeartRateMonitoring() {
        guard !isMonitoring && hasHealthPermission else { return }
        isMonitoring = true

        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { _, samples, _, _, _ in
            self.processSamples(samples)
        }

        query.updateHandler = { _, samples, _, _, _ in
            self.processSamples(samples)
        }

        healthStore.execute(query)
    }

    private func processSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample],
            let latestSample = samples.last
        else { return }

        let heartRate = latestSample.quantity.doubleValue(
            for: HKUnit.count().unitDivided(by: .minute()))

        DispatchQueue.main.async {
            self.currentHeartRate = heartRate
            self.checkHeartRateAlert(heartRate)
        }
    }

    private func checkHeartRateAlert(_ bpm: Double) {
        let alert: HealthAlert

        switch bpm {
        case 0..<40:
            alert = HealthAlert(
                message: "DANGER: Heart rate too low (\(Int(bpm)) BPM)", type: .danger)
            triggerEmergencyProtocol(bpm: bpm, reason: "Low heart rate")
        case 150...:
            alert = HealthAlert(
                message: "DANGER: Heart rate too high (\(Int(bpm)) BPM)", type: .danger)
            triggerEmergencyProtocol(bpm: bpm, reason: "High heart rate")
        case 40..<60:
            alert = HealthAlert(message: "Low heart rate (\(Int(bpm)) BPM)", type: .low)
        case 120..<150:
            alert = HealthAlert(message: "High heart rate (\(Int(bpm)) BPM)", type: .high)
        default:
            alert = HealthAlert(message: "Normal heart rate (\(Int(bpm)) BPM)", type: .normal)
        }

        healthAlert = alert
    }

    private func triggerEmergencyProtocol(bpm: Double, reason: String) {
        guard !dangerAlertCooldown else { return }

        dangerAlertCooldown = true

        emergencyService.callPolice()

        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            self.dangerAlertCooldown = false
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        dangerAlertCooldown = false
    }

    func simulateDangerousHeartRate(bpm: Double) {
        dangerAlertCooldown = false  // reset cooldown for testing
        currentHeartRate = bpm
        checkHeartRateAlert(bpm)
    }
}
