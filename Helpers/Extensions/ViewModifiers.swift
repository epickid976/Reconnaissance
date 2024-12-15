//
//  ViewModifiers.swift
//  Service Maps 2.0
//
//  Created by Jose Blanco on 6/25/24.
//

import Foundation
import SwiftUI

// MARK: - View Modifiers

#if os(iOS)
extension View {
    /// Clips the view to a specified corner radius for specific corners.
    /// - Parameters:
    ///   - radius: The corner radius to apply.
    ///   - corners: Specific corners to apply the radius (e.g., topLeft, bottomRight).
    /// - Returns: A view with the specified rounded corners.
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
#endif

extension View {
    // MARK: - Custom Spacers
    
    /// Sets horizontal alignment spacing.
    /// - Parameter alignment: Desired horizontal alignment.
    /// - Returns: The view with modified alignment and spacing.
    @ViewBuilder func hSpacing(_ alignment: Alignment) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    /// Sets vertical alignment spacing.
    /// - Parameter alignment: Desired vertical alignment.
    /// - Returns: The view with modified alignment and spacing.
    @ViewBuilder func vSpacing(_ alignment: Alignment) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
}

struct ExecuteCode: View {
    /// Initializes and executes a block of code when this view is created.
    /// - Parameter codeToExec: A closure to execute.
    init(_ codeToExec: () -> ()) {
        codeToExec()
    }
    
    var body: some View {
        EmptyView()
    }
}

// MARK: - Spacer Extensions

extension Spacer {
    /// Creates a spacer with a fixed width, if specified.
    /// - Parameter value: Desired width for the spacer.
    /// - Returns: Spacer view with specified width.
    @ViewBuilder static func width(_ value: CGFloat?) -> some View {
        switch value {
            case .some(let value): Spacer().frame(width: max(value, 0))
            case nil: Spacer()
        }
    }
    
    /// Creates a spacer with a fixed height, if specified.
    /// - Parameter value: Desired height for the spacer.
    /// - Returns: Spacer view with specified height.
    @ViewBuilder static func height(_ value: CGFloat?) -> some View {
        switch value {
            case .some(let value): Spacer().frame(height: max(value, 0))
            case nil: Spacer()
        }
    }
}

// MARK: - Font Extensions

extension Font {
    // Custom fonts for various font weights and families
    static func interBold(_ size: CGFloat) -> Font { .custom("Inter-Bold", size: size) }
    static func interSemiBold(_ size: CGFloat) -> Font { .custom("Inter-SemiBold", size: size) }
    static func interRegular(_ size: CGFloat) -> Font { .custom("Inter-Regular", size: size) }

    static func satoshiBlack(_ size: CGFloat) -> Font { .custom("Satoshi-Black", size: size) }
    static func satoshiBold(_ size: CGFloat) -> Font { .custom("Satoshi-Bold", size: size) }
    static func satoshiRegular(_ size: CGFloat) -> Font { .custom("Satoshi-Regular", size: size) }

    static func openSansBold(_ size: CGFloat) -> Font { .custom("OpenSans-Bold", size: size) }
    static func openSansRegular(_ size: CGFloat) -> Font { .custom("OpenSans-Regular", size: size) }

    static func spaceGrotesk(_ size: CGFloat) -> Font { .custom("SpaceGrotesk-Bold", size: size) }
}

// MARK: - Conditional View Modifier

extension View {
    /// Conditionally applies a transformation to a view.
    /// - Parameters:
    ///   - condition: Condition to evaluate.
    ///   - transform: Transformation to apply if condition is true.
    /// - Returns: The original or transformed view based on the condition.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

//MARK: - Scroll

struct ScrollTransitionModifier: ViewModifier {
    @Environment(\.isScrollEnabled) var isScrollEnabled: Bool // Detect if scroll is active (iOS 16)
    @State private var opacity: Double = 1.0 // Local state for opacity (iOS 16)
    @State private var scale: CGFloat = 1.0 // Local state for scale (iOS 16)
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollTransition { content, phase in
                content
                    .opacity(phase.isIdentity || phase == .bottomTrailing ? 1 : 0)
                    .scaleEffect(phase.isIdentity || phase == .bottomTrailing ? 1 : 0.75)
            }
        } else {
            content
        }
    }
}

//MARK: - Optional View Modifier
extension View {
    @ViewBuilder
    func optionalViewModifier<Content: View>(@ViewBuilder content: @escaping (Self) -> Content) -> some View {
        content (self)
    }
}

// MARK: - Shadowed Style
extension View {
    func shadowedStyle() -> some View {
        self
            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 0)
            .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 0)
    }
}

//MARK: - Checkmark Toggle Style

struct CheckmarkToggleStyle: ToggleStyle {
    var color: Color = .teal
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .foregroundColor(configuration.isOn ? color : Color(UIColor.darkGray))
                .frame(width: 51, height: 31, alignment: .center)
                .overlay(
                    Circle()
                        .foregroundColor(.white)
                        .padding(.all, 3)
                        .overlay(
                            Image(systemName: configuration.isOn ? "checkmark" : "xmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .font(Font.title.weight(.black))
                                .frame(width: 8, height: 8, alignment: .center)
                                .foregroundColor(configuration.isOn ? color : .gray)
                        )
                        .offset(x: configuration.isOn ? 11 : -11, y: 0)
                        .animation(Animation.linear(duration: 0.1))
                    
                ).cornerRadius(20)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}

class ColumnViewModel: ObservableObject {
    
    @AppStorage("name") var name = "mon ami(e)"
    
    @AppStorage("columnViewPreference") var isColumnViewEnabled = true

    @AppStorage("hapticFeedback") var hapticFeedback = true
    @AppStorage("watchHapticFeedback") var watchHapticFeedback = true
}
