//
//  MilestoneWidget.swift
//  Reconnaissance
//
//  Created by Jose Blanco on 12/18/24.
//
import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct MilestonesProvider: TimelineProvider {
    @Query var gratitudes: [DailyGratitude]
    
    func placeholder(in context: Context) -> MilestonesEntry {
        MilestonesEntry(date: Date(), totalEntries: 0, weeklyProgress: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (MilestonesEntry) -> Void) {
        let weeklyProgress = Double(gratitudes.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
        }.count) / 7.0
        let entry = MilestonesEntry(date: Date(), totalEntries: gratitudes.count, weeklyProgress: weeklyProgress)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MilestonesEntry>) -> Void) {
        let weeklyProgress = Double(gratitudes.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
        }.count) / 7.0
        let entry = MilestonesEntry(date: Date(), totalEntries: gratitudes.count, weeklyProgress: weeklyProgress)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct MilestonesEntry: TimelineEntry {
    let date: Date
    let totalEntries: Int
    let weeklyProgress: Double
}

struct MilestonesWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    @Query var gratitudes: [DailyGratitude]

    var body: some View {
        let totalEntries = gratitudes.count
        let thisWeekCount = gratitudes.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
        }.count

        if widgetFamily == .systemSmall {
            smallWidget(totalEntries: totalEntries, thisWeekCount: thisWeekCount)
        } else {
            mediumWidget(totalEntries: totalEntries, thisWeekCount: thisWeekCount)
        }
    }

    // MARK: - Small Widget Layout
    @ViewBuilder
    private func smallWidget(totalEntries: Int, thisWeekCount: Int) -> some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("🎯 Milestones", comment: ""))
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            CircularProgressView(
                progress: Double(thisWeekCount) / 7.0,
                color: .blue,
                lineWidth: 4
            )
            .frame(width: 40, height: 40)

            Text(NSLocalizedString("\(thisWeekCount)/7", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)

            Text(NSLocalizedString("Week Progress", comment: ""))
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .containerBackground(.fill.tertiary, for: .widget)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Medium Widget Layout
    @ViewBuilder
    private func mediumWidget(totalEntries: Int, thisWeekCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(NSLocalizedString("🎯 Milestones", comment: ""))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Main Content
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    // Total Entries
                    Text(NSLocalizedString("🎉 \(totalEntries) entries!", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text(NSLocalizedString("Logged \(totalEntries) entries so far.", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Circular Progress
                VStack {
                    CircularProgressView(
                        progress: Double(thisWeekCount) / 7.0,
                        color: .blue,
                        lineWidth: 6
                    )
                    .frame(width: 50, height: 50)

                    Text(NSLocalizedString("\(thisWeekCount)/7", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(NSLocalizedString("Week Progress", comment: ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MilestonesWidget: Widget {
    let kind: String = "MilestonesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GratitudeProvider()) { _ in
            MilestonesWidgetView()
                .containerBackground(.fill.tertiary, for: .widget)
                .modelContainer(for: [DailyGratitude.self])
        }
        .configurationDisplayName("Milestones")
        .description("Track your milestones and weekly progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
