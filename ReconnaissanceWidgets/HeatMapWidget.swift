//
//  HeatMapWidget.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/18/24.
//
import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct HeatmapWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    @Query var gratitudes: [DailyGratitude]
    
    var body: some View {
        let today = Calendar.current.startOfDay(for: Date())
        let last30Days = (0..<30).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }.reversed()
        
        // Map streak data for the last 30 days
        let heatmapData = last30Days.map { date -> (date: Date, streak: Int) in
            if let gratitude = gratitudes.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                return (date: date, streak: gratitude.streak)
            } else {
                return (date: date, streak: 0) // Default gray
            }
        }
        
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("🔥 Streak Heatmap")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Heatmap Grid
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize)), count: 7), spacing: 4) {
                ForEach(heatmapData, id: \.date) { data in
                    Rectangle()
                        .foregroundColor(colorForStreak(data.streak))
                        .frame(width: cellSize, height: cellSize)
                        .cornerRadius(2)
                }
            }
            .frame(height: cellSize * 7 + 6 * 4) // 7 rows + spacings
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var cellSize: CGFloat {
        widgetFamily == .systemMedium ? 12 : 8 // Adjust for medium widget
    }
    
    // Color gradient based on streak
    private func colorForStreak(_ streak: Int) -> Color {
        switch streak {
        case 0: return Color.gray.opacity(0.5) // Default gray for missing data
        case 1: return Color.green.opacity(0.6) // Light green for a streak of 1
        case 2: return Color.green.opacity(1.0) // Darker green for a streak of 2
        default: return Color.green
        }
    }
}

struct HeatmapWidget: Widget {
    let kind: String = "HeatmapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HeatmapProvider()) { _ in
            HeatmapWidgetView()
        }
        .configurationDisplayName("Streak Heatmap")
        .description("Track your gratitude streaks over the last 30 days.")
        .supportedFamilies([.systemMedium])
    }
}

struct HeatmapProvider: TimelineProvider {
    func placeholder(in context: Context) -> HeatmapEntry {
        HeatmapEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (HeatmapEntry) -> Void) {
        let entry = HeatmapEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HeatmapEntry>) -> Void) {
        let entry = HeatmapEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct HeatmapEntry: TimelineEntry {
    let date: Date
}
