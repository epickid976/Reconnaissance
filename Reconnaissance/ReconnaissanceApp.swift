//
//  ReconnaissanceApp.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/9/24.
//

import SwiftUI

@main
struct ReconnaissanceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: DailyGratitude.self)
        }
    }
}
