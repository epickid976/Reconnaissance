//
//  Reconnaissance_WatchApp.swift
//  Reconnaissance Watch Watch App
//
//  Created by Jose Blanco on 12/9/24.
//

import SwiftUI
import SwiftData

@main
struct Reconnaissance_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: DailyGratitude.self)
        }
    }
}
