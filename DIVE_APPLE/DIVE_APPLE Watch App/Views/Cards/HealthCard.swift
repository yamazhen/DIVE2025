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
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(heartRateColor(healthService.currentHeartRate))

                    if let alert = healthService.healthAlert {
                        Text(alert.message)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(alertColor(alert.type))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 3) {
                        HStack(spacing: 3) {
                            Button("Test Low") {
                                healthService.simulateDangerousHeartRate(bpm: 35)
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                            .controlSize(.mini)

                            Button("Test High") {
                                healthService.simulateDangerousHeartRate(bpm: 160)
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .controlSize(.mini)
                        }
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

    private func alertColor(_ type: HealthAlert.AlertType) -> Color {
        switch type {
        case .danger: return .red
        case .high, .low: return .orange
        case .normal: return .green
        }
    }
}
