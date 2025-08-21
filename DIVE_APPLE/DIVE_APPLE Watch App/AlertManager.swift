//
//  AlertManager.swift
//  DIVE_APPLE
//
//  Created by Nodirbek Bokiev on 8/22/25.
//

import SwiftUI

class AlertManager: ObservableObject {
    @Published var message: String?
    @Published var title: String = "Alert"

    func show(title: String = "Alert", message: String) {
        self.title = title
        self.message = message
    }

    func clear() {
        self.message = nil
    }
}
