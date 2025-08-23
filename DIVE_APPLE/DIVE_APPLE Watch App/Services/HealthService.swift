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
    @Published var currentBloodPressureSystolic: Double = 0
    @Published var currentBloodPressureDiastolic: Double = 0
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
        let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        let typesToRead: Set = [heartRateType, systolicType, diastolicType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) {
            [weak self] success, error in
            DispatchQueue.main.async {
                self?.hasHealthPermission = success
                if success {
                    self?.startHeartRateMonitoring()
                    self?.startBloodPressureMonitoring()
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

    func triggerEmergencyProtocol(reason: String) {
        triggerEmergencyProtocol(bpm: 0, reason: reason)
    }
    
    private func triggerEmergencyProtocol(bpm: Double, reason: String) {
        guard !dangerAlertCooldown else { return }

        dangerAlertCooldown = true

        emergencyService.callPolice()

        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            self.dangerAlertCooldown = false
        }
    }

    func startBloodPressureMonitoring() {
        guard hasHealthPermission else { return }
        
        startBloodPressureQuery(for: .bloodPressureSystolic)
        startBloodPressureQuery(for: .bloodPressureDiastolic)
    }
    
    private func startBloodPressureQuery(for identifier: HKQuantityTypeIdentifier) {
        guard let bpType = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: bpType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { _, samples, _, _, _ in
            self.processBloodPressureSamples(samples, for: identifier)
        }
        
        query.updateHandler = { _, samples, _, _, _ in
            self.processBloodPressureSamples(samples, for: identifier)
        }
        
        healthStore.execute(query)
    }
    
    private func processBloodPressureSamples(_ samples: [HKSample]?, for identifier: HKQuantityTypeIdentifier) {
        guard let samples = samples as? [HKQuantitySample],
              let latestSample = samples.last else { return }
        
        let pressure = latestSample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
        
        DispatchQueue.main.async {
            switch identifier {
            case .bloodPressureSystolic:
                self.currentBloodPressureSystolic = pressure
            case .bloodPressureDiastolic:
                self.currentBloodPressureDiastolic = pressure
            default:
                break
            }
            
            self.checkBloodPressureAlert(
                systolic: self.currentBloodPressureSystolic,
                diastolic: self.currentBloodPressureDiastolic
            )
        }
    }
    
    private func checkBloodPressureAlert(systolic: Double, diastolic: Double) {
        guard systolic > 0 && diastolic > 0 else { return }
        
        let alert: HealthAlert
        
        // Blood pressure categories (American Heart Association guidelines)
        switch (systolic, diastolic) {
        case (180..., _), (_, 120...):
            alert = HealthAlert(
                message: "DANGER: Blood pressure critically high (\(Int(systolic))/\(Int(diastolic)))", 
                type: .danger
            )
            triggerEmergencyProtocol(bpm: 0, reason: "High blood pressure crisis")
        case (140...179, _), (_, 90...119):
            alert = HealthAlert(
                message: "High blood pressure (\(Int(systolic))/\(Int(diastolic)))", 
                type: .high
            )
        case (130...139, _), (_, 80...89):
            alert = HealthAlert(
                message: "Elevated blood pressure (\(Int(systolic))/\(Int(diastolic)))", 
                type: .high
            )
        case (...90, _), (_, ...60):
            alert = HealthAlert(
                message: "Low blood pressure (\(Int(systolic))/\(Int(diastolic)))", 
                type: .low
            )
        default:
            alert = HealthAlert(
                message: "Normal blood pressure (\(Int(systolic))/\(Int(diastolic)))", 
                type: .normal
            )
        }
        
        healthAlert = alert
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
    
    func simulateBloodPressure(systolic: Double, diastolic: Double) {
        dangerAlertCooldown = false  // reset cooldown for testing
        currentBloodPressureSystolic = systolic
        currentBloodPressureDiastolic = diastolic
        checkBloodPressureAlert(systolic: systolic, diastolic: diastolic)
    }
}
