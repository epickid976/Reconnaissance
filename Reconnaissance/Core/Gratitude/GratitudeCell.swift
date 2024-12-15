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
    var isAppleWatch = false

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContext

    @State private var isFlipped = false // Tracks whether the card is flipped

    var body: some View {
        ZStack {
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
                                smallDateView(
                                    for: gratitude.date,
                                    isAppleWatch: isAppleWatch,
                                    colorScheme: colorScheme
                                )
                                
                                Spacer()
                                
                                Text("🔥 \(gratitude.streak) Day\(gratitude.streak > 1 ? "s" : "")")
                                    .font(dynamicFont(for: .caption))
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
                                        .font(dynamicFont(for: .headline))
                                        .foregroundColor(.primary)
                                }
                                HStack(spacing: 8) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                    Text(gratitude.entry2)
                                        .font(dynamicFont(for: .subheadline))
                                        .foregroundColor(.primary.opacity(0.8))
                                }
                                HStack(spacing: 8) {
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(.green)
                                    Text(gratitude.entry3)
                                        .font(dynamicFont(for: .subheadline))
                                        .foregroundColor(.primary.opacity(0.8))
                                }
                            }
                        }
                        .padding()
                    )
                    .opacity(isFlipped ? 0 : 1) // Hide front when flipped
            } else {
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
                                .font(dynamicFont(for: .headline))
                                .foregroundColor(.primary)
                                .padding(.bottom, 8)
                                .scaleEffect(x: -1, y: 1)      // Fix mirrored content
                            ScrollView {
                                Text(gratitude.notes)
                                    .font(dynamicFont(for: .body))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .scaleEffect(x: -1, y: 1)      // Fix mirrored content
                        }
                        .padding()
                    )
                    .rotationEffect(.degrees(180)) // Rotate back content to fix upside-down and mirrored text
                    .opacity(isFlipped ? 1 : 0) // Hide back when not flipped
            }
        }
        .frame(
            width: mainWindowSize.width * 0.9,
            height: isAppleWatch ? dynamicHeight(for: mainWindowSize.width) : 140
        )
        .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 1, y: 0, z: 0)
                )
        .animation(.easeInOut(duration: 0.6), value: isFlipped)
        .onTapGesture {
            HapticManager.shared.trigger(.impact)
            isFlipped.toggle()
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { gesture in
                    if gesture.translation.height < 0 {
                        isFlipped = true
                    } else if gesture.translation.height > 0 {
                        isFlipped = false
                    }
                }
        )
    }

    // MARK: - Helpers

    private var borderColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.4) : Color.gray.opacity(0.3)
    }

    private func dynamicFont(for textStyle: Font.TextStyle) -> Font {
        if isAppleWatch {
            // Adjust font sizes for specific Apple Watch models
            if mainWindowSize.width > 200 {
                // Apple Watch Ultra
                return Font.system(textStyle)
            } else if mainWindowSize.width > 150 {
                // Apple Watch S9/S10 (42mm)
                return Font.system(size: textStyle == .headline ? 12 : 10, weight: .regular)
            } else {
                // Apple Watch SE 2 (40mm)
                return Font.system(size: textStyle == .headline ? 10 : 8, weight: .regular)
            }
        } else {
            // Default font size for non-watchOS
            return Font.system(textStyle)
        }
    }
    
    private func dynamicHeight(for width: CGFloat) -> CGFloat {
        if width < 180 {
            // Apple Watch SE (40mm)
            return 110
        } else if width < 200 {
            // Apple Watch S9/S10 (42mm)
            return 120
        } else {
            // Apple Watch Ultra
            return 140
        }
    }

    @ViewBuilder
    private func smallDateView(for date: Date, isAppleWatch: Bool, colorScheme: ColorScheme) -> some View {
        let dateString: String = {
            if isAppleWatch {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: date)
            } else {
                return date.formatted(date: .abbreviated, time: .omitted)
            }
        }()
        
        Text(dateString)
            .font(dynamicFont(for: .caption))
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
    }
}




//MARK: - Preview
#if DEBUG
#if os(iOS)
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
#endif
#endif
