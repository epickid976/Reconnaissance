//
//  FaceIdView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 1/20/25.
//

import SwiftUI

struct SecureView: View {
    @State private var isAuthenticated: Bool = false
    @AppStorage("isBiometricEnabled") private var isBiometricEnabled: Bool = false
    @State private var errorMessage: String? // To handle errors and display alerts

    var body: some View {
        ZStack {
            
            if isAuthenticated || !isBiometricEnabled {
                // Main content view
                HomeTabView()
                    .onAppear {
                        Task {
                            do {
                                try await NotificationManager.shared.requestPermission()
                            } catch {
                                print("Error receiving Notification Permission")
                            }
                        }
                    }
            } else {
                // Authentication view
                // Background gradient for modern aesthetics
                LinearGradient(
                    colors: [.blue.opacity(0.7), .purple.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                
                VStack(spacing: 20) {
                    Image(systemName: determineIconForLock())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)

                    Text("Authentication Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Button(action: {
                        authenticate()
                    }) {
                        Label("Authenticate", systemImage: determineIconForLock())
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                            .transition(.opacity)
                    }
                }
                .padding()
                .animation(.spring(), value: errorMessage)
            }
        }
        .onAppear {
            if isBiometricEnabled && !isAuthenticated {
                authenticate()
            }
        }
        .alert("Authentication Failed", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK", role: .cancel) { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "An unknown error occurred.")
        })
    }

    /// Authenticate the user using Face ID or passcode
    private func authenticate() {
        Task {
            do {
                let success = try await AuthenticationManager.shared.authenticateUser(localizedReason: "Authenticate to access secure content.")
                if success {
                    isAuthenticated = true
                }
            } catch {
                errorMessage = error.localizedDescription
                isAuthenticated = false
            }
        }
    }
}
