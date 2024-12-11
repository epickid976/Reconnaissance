//
//  GratitudeCell.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/10/24.
//
import SwiftUI

//MARK: - Gratitude Cell

struct GratitudeCell: View {
    let gratitude: DailyGratitude
    let mainWindowSize: CGSize
    
    @Environment(\.colorScheme) var colorScheme // Detect light or dark mode
    
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            // Background with Material
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial) // Using Material for the background
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor, lineWidth: 1) // Subtle border for definition
                )
                .shadow(color: shadowColor, radius: 6, x: 0, y: 4)
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Date and Streak
                HStack {
                    // Date Capsule with Material
                    Text(gratitude.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.thinMaterial) // Frosted glass effect
                        )
                        .background(
                            Capsule()
                                .fill(colorScheme == .light ? Color.gray.opacity(0.1) : Color.black.opacity(0.4))
                        )
                    
                    Spacer()
                    
                    // Streak Capsule with Material
                    Text("🔥 \(gratitude.streak) Day\(gratitude.streak > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(6)
                        .background(
                            Capsule()
                                .fill(.thinMaterial) // Frosted glass effect
                        )
                        .background(
                            Capsule()
                                .fill(colorScheme == .light ? Color.gray.opacity(0.1) : Color.black.opacity(0.4))
                        )
                }
                
                // Gratitude Entries
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(gratitude.entry1)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text(gratitude.entry2)
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.8))
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text(gratitude.entry3)
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.8))
                    }
                }
            }
            .padding()
        }
        .frame(width: mainWindowSize.width * 0.9, height: 140)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                isVisible = true
            }
        }
    }
    
    // Capsule Background for Light/Dark Mode
    private var capsuleBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8)
    }
    
    // Subtle Border Color
    private var borderColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)
    }
    
    // Shadow Color for Light/Dark Mode
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3)
    }
}




//MARK: - Preview

#Preview {
    
    ScrollView {
        LazyVStack(spacing: 22) { // Add spacing to separate cells
            GratitudeCell(
                gratitude: DailyGratitude.example,
                mainWindowSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            )
            GratitudeCell(
                gratitude: DailyGratitude.example,
                mainWindowSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            )
            GratitudeCell(
                gratitude: DailyGratitude.example,
                mainWindowSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            )
            GratitudeCell(
                gratitude: DailyGratitude.example,
                mainWindowSize: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            )
        }
        .padding()
    }
}
