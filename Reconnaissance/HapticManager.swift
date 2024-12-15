import UIKit
// For watchOS-specific haptics
import SwiftUI

// MARK: - Haptic Manager

@MainActor
class HapticManager {
    // MARK: - Singleton
    static let shared = HapticManager()
    
    // MARK: - Dependencies
    @ObservedObject var preferencesViewModel = ColumnViewModel()
    
    // MARK: - Feedback Generators (iOS only)
    #if os(iOS)
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    #endif
    
    // MARK: - Initializer
    private init() {
        #if os(iOS)
        // Prepare the generators when the shared instance is created (iOS only)
        impactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
        lightImpact.prepare()
        rigidImpact.prepare()
        #endif
    }
    
    // MARK: - Public Interface
    func trigger(_ type: HapticType) {
        // Check user preferences
        if !preferencesViewModel.hapticFeedback {
            return
        }
        
        #if os(iOS)
        // iOS-specific haptics
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
        case .lightImpact:
            lightImpact.impactOccurred()
        case .rigidImpact:
            rigidImpact.impactOccurred()
        }
        
        #elseif os(watchOS)
        // watchOS-specific haptics
        let watchHapticType: WKHapticType = {
            switch type {
            case .impact, .success:
                return .success
            case .error:
                return .failure
            case .warning:
                return .notification
            case .selectionChanged:
                return .click
            default:
                return .click // Default fallback
            }
        }()
        WKInterfaceDevice.current().play(watchHapticType)
        #endif
    }
}

// MARK: - Haptic Type
// Haptic Types Enum
enum HapticType {
    case impact, success, error, warning, selectionChanged
    
    // iOS-only
    #if os(iOS)
    case lightImpact, rigidImpact
    #endif
}

// MARK: - View Extensions
@MainActor
extension NavigationLink {
    func onTapHaptic(_ type: HapticType) -> some View {
        self.simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.trigger(type)
        })
    }
}
