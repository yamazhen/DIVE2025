import SwiftUI

struct AlertCard: View {
    @EnvironmentObject var alertService: AlertService
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        VStack(spacing: 4) {
            Text("Alert Testing")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            HStack {
                Text("Monitoring: ").foregroundColor(.gray)
                Text(alertService.isMonitoring ? "ON" : "OFF")
                    .foregroundColor(alertService.isMonitoring ? .green : .red)
            }.font(.system(size: 10))
            VStack(spacing: 2) {
                Button("Test Typhoon") {
                    testRealTyphoon()
                }
                .buttonStyle(.bordered)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.red)
                .controlSize(.mini)

                Button("Test Climate") {
                    testRealClimate()
                }
                .buttonStyle(.bordered)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.orange)
                .controlSize(.mini)

                Button("Test Tide") {
                    testRealTide()
                }
                .buttonStyle(.bordered)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.blue)
                .controlSize(.mini)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(4)
    }

    private func testRealTyphoon() {
        alertService.resetCooldowns()

        if let location = locationManager.location {
            Task {
                do {
                    let typhoonAlerts = try await TyphoonService.shared.checkNearbyTyphoons(
                        userLat: location.coordinate.latitude,
                        userLon: location.coordinate.longitude
                    )

                    await MainActor.run {
                        for alert in typhoonAlerts {
                            alertService.activeAlerts.append(alert)
                        }

                        if typhoonAlerts.isEmpty {
                            let infoAlert = Alert(
                                type: .typhoon,
                                title: "⚠ 태풍 정보 ⚠",
                                message: "현재 한국 근처에 활성 태풍이 없습니다"
                            )
                            alertService.activeAlerts.append(infoAlert)
                            alertService.triggerNotification(for: infoAlert)
                        } else {
                            for alert in typhoonAlerts {
                                alertService.triggerNotification(for: alert)
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        let errorAlert = Alert(
                            type: .typhoon,
                            title: "⚠ API 오류 ⚠",
                            message: "태풍 정보 가져오기 실패: \(error.localizedDescription)"
                        )
                        alertService.activeAlerts.append(errorAlert)
                        alertService.triggerNotification(for: errorAlert)
                    }
                }
            }
        }
    }
    
    private func testRealClimate() {
        if let location = locationManager.location {
            Task {
                do {
                    let weatherResponse = try await WeatherService.shared.fetchWeather(
                        lat: location.coordinate.latitude, 
                        lon: location.coordinate.longitude
                    )
                    
                    await MainActor.run {
                        alertService.resetCooldowns()
                        let initialCount = alertService.activeAlerts.count
                        
                        Task {
                            await alertService.checkClimateAnomalyAlert(weather: weatherResponse.weather)
                            
                            // Check if any new alerts were added
                            let newCount = alertService.activeAlerts.count
                            if newCount == initialCount {
                                let noAlert = Alert(
                                    type: .climateAnomaly,
                                    title: "⚠ 기후 정보 ⚠",
                                    message: "현재 기후 이상 현상이 없습니다"
                                )
                                alertService.activeAlerts.append(noAlert)
                                alertService.triggerNotification(for: noAlert)
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        let errorAlert = Alert(
                            type: .climateAnomaly,
                            title: "⚠ API 오류 ⚠",
                            message: "기후 정보 가져오기 실패"
                        )
                        alertService.activeAlerts.append(errorAlert)
                        alertService.triggerNotification(for: errorAlert)
                    }
                }
            }
        }
    }
    
    private func testRealTide() {
        if let location = locationManager.location {
            Task {
                do {
                    let tides = try await TideService.shared.fetchTideData(
                        lat: location.coordinate.latitude, 
                        lon: location.coordinate.longitude
                    )
                    
                    await MainActor.run {
                        alertService.resetCooldowns()
                        let initialCount = alertService.activeAlerts.count
                        
                        Task {
                            await alertService.checkHighTideAlert(tides: tides)
                            
                            // Check if any new alerts were added
                            let newCount = alertService.activeAlerts.count
                            if newCount == initialCount {
                                let noAlert = Alert(
                                    type: .highTide,
                                    title: "≈ 조수 정보 ≈",
                                    message: "현재 고조 경보가 없습니다"
                                )
                                alertService.activeAlerts.append(noAlert)
                                alertService.triggerNotification(for: noAlert)
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        let errorAlert = Alert(
                            type: .highTide,
                            title: "⚠ API 오류 ⚠",
                            message: "조수 정보 가져오기 실패"
                        )
                        alertService.activeAlerts.append(errorAlert)
                        alertService.triggerNotification(for: errorAlert)
                    }
                }
            }
        }
    }

    private func testTyphoonAlert() {
        alertService.resetCooldowns()

        let testWeather = Weather(
            weather: [
                WeatherEntry(
                    aplYmdt: "202508231400",
                    sky: "흐림",
                    sky_code: "3",
                    rain: "0",
                    temp: "25",
                    winddir: "270",
                    windspd: "30",  // High wind speed to trigger typhoon
                    pago: "7",  // High wave height to trigger typhoon
                    humidity: "80",
                    pm25_s: nil,
                    pm10_s: nil,
                    pm10: nil,
                    pm25: nil
                )
            ],
            info: WeatherInfo(city: "Test City", cityCode: "TEST")
        )

        Task {
            await alertService.checkTyphoonAlert(weather: testWeather)
        }
    }

    private func testClimateAlert() {
        alertService.resetCooldowns()

        let testWeather = Weather(
            weather: [
                WeatherEntry(
                    aplYmdt: "202508231400",
                    sky: "맑음",
                    sky_code: "1",
                    rain: "0",
                    temp: "40",  // High temperature to trigger climate anomaly
                    winddir: "180",
                    windspd: "20",  // High wind speed
                    pago: "4",  // High waves
                    humidity: "90",
                    pm25_s: nil,
                    pm10_s: nil,
                    pm10: nil,
                    pm25: nil
                )
            ],
            info: WeatherInfo(city: "Test City", cityCode: "TEST")
        )

        Task {
            await alertService.checkClimateAnomalyAlert(weather: testWeather)
        }
    }

    private func testTideAlert() {
        alertService.resetCooldowns()

        let testTides = [
            Tide(
                pThisDate: "2025-08-23",
                pSelArea: "Test Area",
                pMul: "3.2",
                pSun: "06:00",
                pMoon: "18:30",
                pTime1: getCurrentTimeInOneHour(),  // High tide in 1 hour
                pTime2: "18:45",
                pTime3: "06:30",
                pTime4: "19:00"
            )
        ]

        Task {
            await alertService.checkHighTideAlert(tides: testTides)
        }
    }

    private func getCurrentTimeInOneHour() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let oneHourLater = Date().addingTimeInterval(3600)  // 1 hour from now
        return formatter.string(from: oneHourLater)
    }
}
