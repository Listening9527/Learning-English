//
//  LearningApp.swift
//  Learning
//
//  Created by CNCEMNV02 on 2026/7/20.
//

import SwiftUI

@main
struct LearningApp: App {
    init() {
        DatabaseManager.shared.initializeDatabase()
    }

    var body: some Scene {
        WindowGroup {
            MainPage()
        }
    }
}
