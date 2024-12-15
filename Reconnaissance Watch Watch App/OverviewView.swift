//
//  OverviewView.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/15/24.
//

import SwiftUI
import SwiftData

//MARK: - Summary Views

struct SummaryViews: View {
    
    @Query var gratitudes: [DailyGratitude]
    
    private var calendar = Calendar.current
    private var thisWeeksGratitudes: [DailyGratitude] {
        gratitudes.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
    }
    
    var body: some View {
        GeometryReader { proxy in
            NavigationStack {
                WatchOverviewView(
                    gratitudes: gratitudes,
                    thisWeeksGratitudes: thisWeeksGratitudes,
                    mainWindowSize: proxy.size
                )
            }
        }
    }
}

//MARK: - Watch Overview View

struct WatchOverviewView: View {
    let gratitudes: [DailyGratitude]
    let thisWeeksGratitudes: [DailyGratitude]
    let mainWindowSize: CGSize // Use to determine device-specific adjustments

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 12) {
                // 🎯 Milestones Section
                VStack(spacing: 8) {
                    Text("🎯 Milestones")
                        .font(dynamicFont(for: .headline))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if gratitudes.count > 0 {
                        Text("🎉 \(gratitudes.count) entries!")
                            .font(dynamicFont(for: .subheadline))
                            .foregroundColor(.blue)
                    } else {
                        Text("No entries yet.")
                            .font(dynamicFont(for: .subheadline))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Logged \(gratitudes.count) entries so far.")
                        .font(dynamicFont(for: .footnote))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                
                // 🌀 Weekly Progress
                VStack(spacing: 8) {
                    CircularProgressView(
                        progress: Double(thisWeeksGratitudes.count) / 7.0,
                        color: .blue,
                        lineWidth: isSmallWatch ? 3 : 5
                    )
                    .frame(width: isSmallWatch ? 40 : 50, height: isSmallWatch ? 40 : 50)
                    
                    Text("\(thisWeeksGratitudes.count)/7 this week")
                        .font(dynamicFont(for: .footnote))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                
                // 📝 Reflections
                Text("“Gratitude turns what we have into enough.”")
                    .font(dynamicFont(for: .caption))
                    .italic()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    private var isSmallWatch: Bool {
        mainWindowSize.width < 150 // Adjust based on actual Apple Watch dimensions
    }

    private func dynamicFont(for textStyle: Font.TextStyle) -> Font {
        if isSmallWatch {
            // SE (40mm)
            return Font.system(size: textStyle == .headline ? 14 : 12)
        } else if mainWindowSize.width < 200 {
            // S9/S10 (42mm)
            return Font.system(size: textStyle == .headline ? 16 : 14)
        } else {
            // Ultra
            return Font.system(textStyle)
        }
    }
}

//MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
