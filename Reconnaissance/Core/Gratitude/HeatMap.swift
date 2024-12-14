//
//  HeatMap.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/12/24.
//

import SwiftUI
import SwiftData

//MARK: Heatmap

struct HeatmapView: View {
    @State var viewModel = HeatmapViewModel.shared // Use the shared instance
    @State var dailyGratitudes: [DailyGratitude]
    
    let availableWidth: CGFloat

    @State private var showHeatmap = false // Controls entrance animation

    private let calendar = Calendar.current

    var body: some View {
        let cellSize: CGFloat = availableWidth / 53 // 52 weeks + padding
        let rows = Array(repeating: GridItem(.fixed(cellSize), spacing: 4), count: 7)
        let today = Calendar.current.startOfDay(for: Date())

        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                VStack(alignment: .leading) {
                    // Month labels
                    HStack {
                        ForEach(0..<12, id: \.self) { month in
                            Text(shortMonthName(for: month + 1))
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.bottom, 4)

                    // Heatmap grid
                    LazyHGrid(rows: rows, spacing: 4) {
                        ForEach(viewModel.heatmapData, id: \.date) { data in
                            Rectangle()
                                .foregroundColor(colorForStreak(data.streak))
                                .frame(width: cellSize, height: cellSize)
                                .cornerRadius(2)
                                .id(data.date)
                        }
                    }
                    .frame(height: cellSize * 7 + 6 * 4) // 7 rows + spacings
                    .opacity(showHeatmap ? 1 : 0) // Control entire grid's opacity
                    .animation(.easeInOut(duration: 0.5), value: showHeatmap) // Animate the entire heatmap's appearance
                }
                .padding()
                .onAppear {
                    Task {
                        await viewModel.calculateHeatmapData(dailyGratitudes: dailyGratitudes)
                        
                        withAnimation {
                            showHeatmap = true // Trigger grid's fade-in animation
                        }
                        
                        // Scroll to today's date after data is ready
                        if let todayIndex = viewModel.heatmapData.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                            DispatchQueue.main.async {
                                proxy.scrollTo(viewModel.heatmapData[todayIndex].date, anchor: .center)
                            }
                        }
                    }
                }
                
            }
        }
    }

    private func shortMonthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.shortMonthSymbols[month - 1]
    }

    // Color gradient based on streak
    private func colorForStreak(_ streak: Int) -> Color {
        switch streak {
        case 0: return Color.gray.opacity(0.5) // Default gray for missing data
        case 1: return Color.green.opacity(0.6) // Light green for a streak of 1
        case 2: return Color.green.opacity(1.0) // Darker green for a streak of 2
        default: return Color.green
            .darker(by: 20) // Full green for streaks of 3 or more
        }
    }
}

@MainActor
@Observable
class HeatmapViewModel {
    static let shared = HeatmapViewModel() // Singleton instance
    
    var heatmapData: [(date: Date, streak: Int)] = []
    
    private let calendar = Calendar.current

    // Populate heatmap data
    @BackgroundActor
    func calculateHeatmapData(dailyGratitudes: [DailyGratitude]) async {
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
        let daysInYear = calendar.range(of: .day, in: .year, for: startOfYear)?.count ?? 365

        let allDates = (0..<daysInYear).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfYear) }

        // Perform the calculation in the background
        let calculatedData = allDates.map { date -> (date: Date, streak: Int) in
            if let gratitude = dailyGratitudes.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                return (date: date, streak: gratitude.streak)
            } else {
                return (date: date, streak: 0) // Default gray
            }
        }

        // Update on the main thread
        await MainActor.run {
            heatmapData = calculatedData
        }
    }
}

struct CircularProgressView: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}
