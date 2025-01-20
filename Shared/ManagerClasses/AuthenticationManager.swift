//
//  AuthenticationManager.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 1/20/25.
//

import LocalAuthentication

import LocalAuthentication

@MainActor
final class AuthenticationManager {
    static let shared = AuthenticationManager()

    /// Authenticates the user using biometrics or passcode.
    func authenticateUser(localizedReason: String = "Authenticate to proceed") async throws -> Bool {
        let context = LAContext()

        // Check if the device supports biometrics
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            // Fallback to passcode if biometrics are unavailable
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
                return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: localizedReason)
            } else {
                throw AuthenticationError.biometricUnavailable
            }
        }

        // Attempt biometric authentication
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReason)
        } catch {
            // Fallback to passcode if biometrics fail or aren't configured
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
                return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: localizedReason)
            } else {
                throw error
            }
        }
    }

    /// Determines the type of biometric authentication available.
    static func biometricType() -> BiometricType {
        let context = LAContext()
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touch
        case .faceID:
            return .face
        default:
            return .none
        }
    }

    enum BiometricType {
        case none
        case touch
        case face
    }

    enum AuthenticationError: Error, LocalizedError {
        case biometricUnavailable

        var errorDescription: String? {
            switch self {
            case .biometricUnavailable:
                return "Biometric authentication is not available on this device."
            }
        }
    }
}


