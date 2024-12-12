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

    @Environment(\.colorScheme) var colorScheme

    @State private var isFlipped = false // Tracks whether the card is flipped

    var body: some View {
        ZStack {
            // Front of the card
            if !isFlipped {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(color: shadowColor, radius: 6, x: 0, y: 4)
                    .overlay(
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(gratitude.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(.thinMaterial)
                                    )
                                    .background(
                                        Capsule()
                                            .fill(colorScheme == .light ? Color.gray.opacity(0.1) : Color.black.opacity(0.4))
                                    )
                                
                                Spacer()
                                
                                Text("🔥 \(gratitude.streak) Day\(gratitude.streak > 1 ? "s" : "")")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(6)
                                    .background(
                                        Capsule()
                                            .fill(.thinMaterial)
                                    )
                                    .background(
                                        Capsule()
                                            .fill(colorScheme == .light ? Color.gray.opacity(0.1) : Color.black.opacity(0.4))
                                    )
                            }
                            
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
                    )
                    .opacity(isFlipped ? 0 : 1) // Hide front when flipped

            } else {
                // Back of the card showing notes
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(color: shadowColor, radius: 6, x: 0, y: 4)
                    .overlay(
                        VStack {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 8)
                                .rotationEffect(.degrees(360))  // Rotate back content
                                .scaleEffect(x: -1, y: 1)      // Fix mirrored content
                              
                            ScrollView { // Use ScrollView to handle large text
                                Text(gratitude.notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .rotationEffect(.degrees(360))  // Rotate back content
                                    .scaleEffect(x: -1, y: 1)      // Fix mirrored content
                                    //.padding()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it fills the available space
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure the content fills the back card
                        .rotationEffect(.degrees(180)) // Rotate back content to fix upside-down and mirrored text
                    )
                    .opacity(isFlipped ? 1 : 0) // Hide back when not flipped
            }
        }
        .frame(width: mainWindowSize.width * 0.9, height: 140)
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 1, y: 0, z: 0)
        )
        .animation(.easeInOut(duration: 0.6), value: isFlipped)
        .onTapGesture {
            isFlipped.toggle() // Flip the card on tap
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { gesture in
                    if gesture.translation.height < 0 { // Swipe up detected
                        isFlipped = true
                    } else if gesture.translation.height > 0 { // Swipe down detected
                        isFlipped = false
                    }
                }
        )
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
