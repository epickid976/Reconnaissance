//
//  ReflectionWidget.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/18/24.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct ReflectionProvider: TimelineProvider {
    @Query var gratitudes: [DailyGratitude]

    func placeholder(in context: Context) -> ReflectionEntry {
        ReflectionEntry(date: Date(), startDate: nil, lastEntryDate: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ReflectionEntry) -> Void) {
        let startDate = gratitudes.last?.date
        let lastEntryDate = gratitudes.first?.date
        let entry = ReflectionEntry(date: Date(), startDate: startDate, lastEntryDate: lastEntryDate)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReflectionEntry>) -> Void) {
        let startDate = gratitudes.last?.date
        let lastEntryDate = gratitudes.first?.date
        let entry = ReflectionEntry(date: Date(), startDate: startDate, lastEntryDate: lastEntryDate)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct ReflectionEntry: TimelineEntry {
    let date: Date
    let startDate: Date?
    let lastEntryDate: Date?
}

struct ReflectionSummaryWidgetView: View {
    @Query var gratitudes: [DailyGratitude]

    var body: some View {
        let firstEntryDate = gratitudes.last?.date
        let lastEntryDate = gratitudes.first?.date

        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("📝 Reflection Summary", comment: ""))
                .font(.headline)
                .fontWeight(.semibold)

            if let startDate = firstEntryDate {
                Text("Started: \(startDate, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let recentDate = lastEntryDate {
                    Text("Last entry: \(recentDate, style: .relative)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(NSLocalizedString("Start your gratitude journey today!", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ReflectionSummaryWidget: Widget {
    let kind: String = "ReflectionSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReflectionProvider()) { _ in
            ReflectionSummaryWidgetView()
                .containerBackground(.fill.tertiary, for: .widget)
                .modelContainer(SharedModelContainer.container)
        }
        .configurationDisplayName("Reflection Summary")
        .description("Review your gratitude journey.")
        .supportedFamilies([.systemMedium])
    }
}
