import SwiftUI

struct HealthCard: View {
    @EnvironmentObject var healthService: HealthService

    var body: some View {
        VStack(spacing: 6) {
            if !healthService.hasHealthPermission {
                Text("Health permission not set")
            } else {
                VStack {
                    Text("\(Int(healthService.currentHeartRate)) BPM")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(heartRateColor(healthService.currentHeartRate))

                    Text(
                        "\(Int(healthService.currentBloodPressureSystolic))/\(Int(healthService.currentBloodPressureDiastolic)) mmHg"
                    )
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(
                        bloodPressureColor(
                            healthService.currentBloodPressureSystolic,
                            healthService.currentBloodPressureDiastolic))

                    if let alert = healthService.healthAlert {
                        Text(alert.message)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(alertColor(alert.type))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 3) {
                        HStack(spacing: 3) {
                            Button("Low BPM") {
                                healthService.simulateDangerousHeartRate(bpm: 35)
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                            .controlSize(.mini)

                            Button("High BPM") {
                                healthService.simulateDangerousHeartRate(bpm: 160)
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                            .controlSize(.mini)
                        }

                        Button("High Blood Pressure") {
                            healthService.simulateBloodPressure(systolic: 190, diastolic: 110)
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.yellow)
                        .controlSize(.mini)

                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(4)
    }

    private func heartRateColor(_ bpm: Double) -> Color {
        switch bpm {
        case 0..<40, 150...: return .red
        case 40..<60, 120..<150: return .orange
        default: return .green
        }
    }

    private func bloodPressureColor(_ systolic: Double, _ diastolic: Double) -> Color {
        switch (systolic, diastolic) {
        case (180..., _), (_, 120...): return .red  // Crisis
        case (140..., _), (_, 90...): return .red  // High
        case (130..., _), (_, 80...): return .orange  // Elevated
        case (...90, _), (_, ...60): return .orange  // Low
        default: return .green  // Normal
        }
    }

    private func alertColor(_ type: HealthAlert.AlertType) -> Color {
        switch type {
        case .danger: return .red
        case .high, .low: return .orange
        case .normal: return .green
        }
    }
}
