//
//  SettingsView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/15/24.
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct WatchSettingsView: View {
    @StateObject private var preferencesViewModel = ColumnViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showPrivacyPolicy = false
    @State private var showDeleteAlert = false
    @State private var showAppVersionAlert = false
    @State private var showAboutApp = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    headerView(name: preferencesViewModel.name)
                    // Haptics Setting
                    PreferenceRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "Haptics",
                        foregroundColor: .green,
                        iconColor: .green,
                        toggleValue: $preferencesViewModel.watchHapticFeedback
                    )
                    
                    // Privacy Policy
                    PreferenceRow(
                        icon: "lock.doc",
                        title: "Privacy Policy",
                        iconColor: .pink,
                        action: {
                            showPrivacyPolicy = true
                        }
                    )
                    .sheet(isPresented: $showPrivacyPolicy) {
                        WatchPrivacyPolicyView()
                    }
                    
                    // About App
                    PreferenceRow(
                        icon: "info.circle.fill",
                        title: "About App",
                        iconColor: .blue,
                        action: {
                            showAboutApp = true
                        }
                    )
                    .sheet(isPresented: $showAboutApp) {
                        WatchAboutAppView()
                    }
                    
                    // App Version
                    PreferenceRow(
                        icon: "numbers.rectangle.fill",
                        title: "App Version",
                        description: "\(getAppVersion())",
                        iconColor: .teal,
                        action: {
                            showAppVersionAlert = true
                        }
                    )
                    .alert("App Version", isPresented: $showAppVersionAlert) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("Version \(getAppVersion())")
                    }
                    
                    // Delete All Data
                    PreferenceRow(
                        icon: "trash",
                        title: "Delete All Data",
                        iconColor: .red,
                        action: {
                            showDeleteAlert = true
                        }
                    )
                    .alert("Delete All Data", isPresented: $showDeleteAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Delete", role: .destructive) {
                            deleteAllData()
                        }
                    } message: {
                        Text("Are you sure you want to delete all data? This action cannot be undone.")
                    }
                }
                .padding(5)
            }
            .navigationTitle("Settings")
        }
    }
    
    @ViewBuilder
    private func headerView(name: String) -> some View {
        VStack(spacing: 8) {
            // Gradient Background
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80) // Adjust height for watch screen
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                VStack(spacing: 4) {
                    // Welcome Text
                    Text("Hello, \(name) 👋")
                        .font(.headline) // Adjust for watchOS
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    // Subtitle
                    Text("Here are your settings")
                        .font(.footnote) // Smaller subtitle font
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding()
            }
            
            Divider()
                .background(Color.primary.opacity(0.2))
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Helpers
    
    private func deleteAllData() {
        Task {
            do {
                let fetchDescriptor = FetchDescriptor<DailyGratitude>()
                let allEntries = try modelContext.fetch(fetchDescriptor)
                allEntries.forEach { modelContext.delete($0) }
                try modelContext.save()
            } catch {
                print("Failed to delete all data: \(error)")
            }
        }
    }
    
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "Unknown"
    }
}

struct WatchPrivacyPolicyView: View {
    let privacyPolicyURL = URL(string: "https://servicemaps.ejvapps.online/privacy")!
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                
                Text("Privacy Policy")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                //.padding()
                
                Text("Link to our Privacy Policy and Security Practices.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // Redirect URL to paired iPhone
                    let session = ASWebAuthenticationSession(
                        url: privacyPolicyURL,
                        callbackURLScheme: nil
                    ) { _, _ in
                        
                    }
                    
                    session.prefersEphemeralWebBrowserSession = true
                    
                    session.start()
                }) {
                    Text("Open")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }
}

struct WatchAboutAppView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "heart.text.square.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                
                Text("About This App")
                    .font(.headline)
                    .padding(.bottom, 8)
                
                Text("""
                This app is designed to help you reflect on gratitude and prioritize self-care. We hope it fosters positivity and mindfulness in your daily life. Thank you for using our app!
                """)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            }
            .padding()
        }
        .navigationTitle("About App")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WatchDeleteAllDataView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var showConfirmationAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.red)
            
            Text("Delete All Data")
                .font(.headline)
            
            Text("""
            Are you sure you want to delete all your data? This action cannot be undone, and all your saved entries will be permanently removed.
            """)
            .font(.footnote)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
            
            Button(action: {
                showConfirmationAlert = true
            }) {
                Text("Delete All Data")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(10)
            }
            .alert("Confirm Deletion", isPresented: $showConfirmationAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This action cannot be undone. Are you sure you want to delete all data?")
            }
            
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
        .padding()
        .navigationTitle("Delete All Data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteAllData() {
        Task {
            do {
                let fetchDescriptor = FetchDescriptor<DailyGratitude>()
                let allEntries = try modelContext.fetch(fetchDescriptor)
                allEntries.forEach { modelContext.delete($0) }
                try modelContext.save()
            } catch {
                print("Failed to delete all data: \(error)")
            }
        }
    }
}
