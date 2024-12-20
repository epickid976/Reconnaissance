//
//  MemoryWidget.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/18/24.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct MemoryProvider: TimelineProvider {
    @Query var gratitudes: [DailyGratitude]

    func placeholder(in context: Context) -> MemoryEntry {
        MemoryEntry(date: Date(), randomGratitude: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MemoryEntry) -> Void) {
        let randomGratitude = gratitudes.randomElement()
        let entry = MemoryEntry(date: Date(), randomGratitude: randomGratitude)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoryEntry>) -> Void) {
        let randomGratitude = gratitudes.randomElement()
        let entry = MemoryEntry(date: Date(), randomGratitude: randomGratitude)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct MemoryEntry: TimelineEntry {
    let date: Date
    let randomGratitude: DailyGratitude?
}

struct MemoryWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    @Query var gratitudes: [DailyGratitude]

    var body: some View {
        let randomGratitude = gratitudes.randomElement()

        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("🧠 Memory of Gratitude", comment: ""))
                .font(widgetFamily == .systemSmall ? .subheadline : .headline)
                .fontWeight(.semibold)

            if let randomGratitude = randomGratitude {
                if widgetFamily == .systemSmall {
                    Text("\"\(randomGratitude.entry1)\"")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                } else {
                    Text("On \(randomGratitude.date, style: .date), you wrote:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\"\(randomGratitude.entry1)\"")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            } else {
                Text(NSLocalizedString("No memories yet.", comment: ""))
                    .font(widgetFamily == .systemSmall ? .caption : .subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(widgetFamily == .systemSmall ? 8 : 12)
        .containerBackground(.fill.tertiary, for: .widget)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MemoryOfGratitudeWidget: Widget {
    let kind: String = "MemoryOfGratitudeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GratitudeProvider()) { _ in
            MemoryWidgetView()
                .containerBackground(.fill.tertiary, for: .widget)
                .modelContainer(for: [DailyGratitude.self])
        }
        .configurationDisplayName("Memory of Gratitude")
        .description("Recall a moment of gratitude.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
