//
//  Reconnaissance_WatchApp.swift
//  Reconnaissance Watch Watch App
//
//  Created by Jose Blanco on 12/9/24.
//

import SwiftUI
import SwiftData
import UserNotifications

//MARK: - Main App

@main
struct Reconnaissance_Watch_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            WatchTabView()
                .modelContainer(SharedModelContainer.container)
        }
    }
}

//MARK: - Watch Tab View

struct WatchTabView: View {
    
    var body: some View {
        NavigationStack {
            TabView {
                TodayView()
                SummaryViews()
                WatchSettingsView()
            }
            .tabViewStyle(.verticalPage) // Enables the horizontal scrolling style
            .indexViewStyle(.page(backgroundDisplayMode: .automatic)) // Customize the index dots
        }
    }
}

//MARK: - Page View for Debugging

struct PageView: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
