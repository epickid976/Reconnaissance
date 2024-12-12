//
//  HapticManager.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/20/24.
//

import UIKit // Or SwiftUI, depending on your project
import SwiftUI

//MARK: - Haptic Manager

@MainActor
class HapticManager {
    //MARK: - Singleton
    static let shared = HapticManager()
    
    //MARK: - Dependencies
    
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    //MARK: - Feedback Generators
    
    // Feedback Generators
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // Custom Feedback Patterns (iOS 13+)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let softNotification = UINotificationFeedbackGenerator()

    //MARK: - Initializer
    
    private init() {
            // Prepare the generators when the shared instance is created
            impactGenerator.prepare()
            notificationGenerator.prepare()
            selectionGenerator.prepare()
            lightImpact.prepare()
            rigidImpact.prepare()
            softNotification.prepare()
        }
    
    // MARK: - Public Interface
    func trigger(_ type: HapticType) {
        if !preferencesViewModel.hapticFeedback {
            return
        }
        switch type {
        case .impact:
            impactGenerator.impactOccurred()
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .selectionChanged:
            selectionGenerator.selectionChanged()

        // iOS 13+ Specific
        case .lightImpact:
            lightImpact.impactOccurred()
        case .rigidImpact:
            rigidImpact.impactOccurred()
        case .softSuccess:
            softNotification.notificationOccurred(.success)
        case .softError:
            softNotification.notificationOccurred(.error)
        case .softWarning:
            softNotification.notificationOccurred(.warning)
        }
    }
}

//MARK: - Haptic Type
// Haptic Types Enum
enum HapticType {
    case impact, success, error, warning, selectionChanged

    // iOS 13+
    case lightImpact, rigidImpact
    case softSuccess, softError, softWarning
}

//MARK: - View Extensions
@MainActor
extension NavigationLink {
    func onTapHaptic(_ type: HapticType) -> some View {
        self.simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.trigger(type)
        })
    }
}

