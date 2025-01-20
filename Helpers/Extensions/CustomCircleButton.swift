//
//  CustomCircleButton.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/16/24.
//

import Foundation
import SwiftUI
import Combine

//MARK: - Circle Button Style
struct CircleButtonStyle: ButtonStyle {
    //MARK: - Properties
    var imageName: String
    var foreground = Color.primary
    var background = Color.white
    var width: CGFloat = 40
    var height: CGFloat = 40
    @Binding var progress: CGFloat
    @Binding var animation: Bool
    
    //MARK: - Body
    func makeBody(configuration: Configuration) -> some View {
        
        Circle()
            
            .optionalViewModifier { content in
                if progress > 0.01 {
                    content
                        .fill(Color.clear)
                } else {
                    content
                        .fill(Material.ultraThin)
                }
            }
        
            .overlay(Image(systemName: imageName == "magnifyingglass" && animation == true ? "" : imageName)
                .resizable()
                .scaledToFit()
                .foregroundColor(foreground)
                .padding(12)
                .bold()
                .optionalViewModifier { content in
                    if #available(iOS 17, *) {
                        content
                            .symbolEffect(.bounce, options: .speed(3.0), value: animation)
                    } else {
                        content
                    }
                }
            )
        
            .frame(width: width, height: height)
            
    }
}

//MARK: - Custom Oval Button

struct MiniOvalButton: View {
    var label: String
    var action: () -> Void
    var color: Color = .blue
    var textColor: Color = .white
    var showIcon: Bool = true
    var icon: String = "plus"

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if showIcon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(textColor)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(color, lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            .hoverEffect(.highlight) // Optional for iOS
        }
        .buttonStyle(PlainButtonStyle())
    }
}
