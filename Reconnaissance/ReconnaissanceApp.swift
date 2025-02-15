//
//  ReconnaissanceApp.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/9/24.
//

import SwiftUI
import SwiftData



@main
struct ReconnaissanceApp: App {
    //MARK: - Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(SharedModelContainer.container)
        }
    }
}

