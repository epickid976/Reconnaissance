//
//  ReconnaissanceWidgets.swift
//  ReconnaissanceWidgets
//
//  Created by Jose Blanco on 12/17/24.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct GratitudeProvider: TimelineProvider {
    @Query var gratitudes: [DailyGratitude]
    
    var today: DailyGratitude? {
        gratitudes.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        })
    }
    
    func placeholder(in context: Context) -> GratitudeEntry {
        GratitudeEntry(date: Date(), gratitude: sampleGratitude)
    }

    func getSnapshot(in context: Context, completion: @escaping (GratitudeEntry) -> Void) {
        let entry = GratitudeEntry(date: Date(), gratitude: today ?? sampleGratitude)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GratitudeEntry>) -> Void) {
        let currentDate = Date()
        
        // Create an entry for the current state
        let entry = GratitudeEntry(date: currentDate, gratitude: today)

        // Schedule the next update for 1 hour later
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

struct GratitudeEntry: TimelineEntry {
    let date: Date
    let gratitude: DailyGratitude?
}

let sampleGratitude = DailyGratitude(
    entry1: "Family time",
    entry2: "Good health",
    entry3: "Learning SwiftUI",
    date: Date(),
    notes: "Grateful for a productive day!"
)

struct GratitudeTodayView: View {
    var entry: GratitudeProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if let gratitude = entry.gratitude {
            VStack(alignment: .leading, spacing: spacing) {
                if widgetFamily != .systemSmall {
                    // Top Row: Date and Streak (only for medium/large widgets)
                    HStack {
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Spacer()

                        Text("🔥 \(gratitude.streak) Day\(gratitude.streak > 1 ? "s" : "")")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    }
                } else {
                    // Only Streak for small widget
                    Text("🔥 \(gratitude.streak) Day\(gratitude.streak > 1 ? "s" : "")")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                }

                // Main Gratitude Entries
                VStack(alignment: .leading, spacing: entrySpacing) {
                    HStack(spacing: iconSpacing) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(gratitude.entry1)
                            .font(widgetFamily == .systemSmall ? .caption : .headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    HStack(spacing: iconSpacing) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text(gratitude.entry2)
                            .font(widgetFamily == .systemSmall ? .caption : .subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    HStack(spacing: iconSpacing) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text(gratitude.entry3)
                            .font(widgetFamily == .systemSmall ? .caption : .subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(containerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            Link(destination: URL(string: "reconnaissance://addGratitude")!) {
                VStack(spacing: 12) {
                    Text("No gratitude entries yet!")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Label("Add Gratitude", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(containerBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Spacing and Design Adjustments
    private var spacing: CGFloat {
        widgetFamily == .systemSmall ? 6 : 12
    }
    
    private var entrySpacing: CGFloat {
        widgetFamily == .systemSmall ? 4 : 8
    }
    
    private var iconSpacing: CGFloat {
        widgetFamily == .systemSmall ? 6 : 8
    }
    
    private var horizontalPadding: CGFloat {
        widgetFamily == .systemSmall ? 6 : 12
    }
    
    private var verticalPadding: CGFloat {
        widgetFamily == .systemSmall ? 6 : 12
    }
    
    private var containerBackground: some View {
        Color(uiColor: colorScheme == .dark ? UIColor.systemGray6 : UIColor.systemBackground)
    }
}

struct GratitudeTodayWidget: Widget {
    let kind: String = "GratitudeTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GratitudeProvider()) { entry in
            GratitudeTodayView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Gratitude Today")
        .description("View your daily gratitude entries.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}


//struct AddGratitudeIntent: AppIntent {
//    static var title: LocalizedStringResource = "Add Gratitude Entry"
//    static var description = IntentDescription("Opens the app to add a new gratitude entry.")
//
//    func perform() async throws -> some IntentResult {
//        // Open your app using the URL scheme
//        if let url = URL(string: "reconnaissance://addGratitude") {
//            await UIApplication.shared.open(url)
//        }
//        return .result()
//    }
//}

#Preview(as: .systemMedium) {
    GratitudeTodayWidget()
} timeline: {
    GratitudeEntry(date: .now, gratitude: sampleGratitude)
    GratitudeEntry(date: .now, gratitude: nil)
}
