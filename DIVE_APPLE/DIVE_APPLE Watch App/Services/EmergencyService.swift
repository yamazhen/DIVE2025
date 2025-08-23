import Foundation
import WatchKit

class EmergencyService: NSObject {

    func callPolice() {
        #if targetEnvironment(simulator)
            let alert = WKAlertAction(title: "OK", style: .default) {}

            WKExtension.shared().rootInterfaceController?.presentAlert(
                withTitle: "⚠ 응급 통화",
                message: "실제 기기에서는 112로 전화를 겁니다",
                preferredStyle: .alert,
                actions: [alert]
            )

            WKInterfaceDevice.current().play(.notification)
        #else
            if let url = URL(string: "tel:112") {

                WKExtension.shared().openSystemURL(url)
                return
            }

        #endif
    }
}
