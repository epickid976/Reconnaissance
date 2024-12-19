//
//  ReconnaissanceWatchWidgets.swift
//  ReconnaissanceWatchWidgets
//
//  Created by Jose Blanco on 12/19/24.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct ReconnaissanceWatchWidgetsEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Image("100") // Replace "100" with your app icon's asset name
                .resizable()
                .scaledToFit() // Ensures the image scales correctly within the frame
                .frame(width: 50, height: 50) // Adjust the size as needed
        }
    }
}

@main
struct ReconnaissanceWatchWidgets: Widget {
    let kind: String = "ReconnaissanceWatchWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ReconnaissanceWatchWidgetsEntryView(entry: entry)
                .containerBackground(.clear, for: .widget) // Transparent background
        }
        .configurationDisplayName("App Shortcut")
        .description("Quickly open Reconnaissance.")
        .supportedFamilies([.accessoryCircular]) // Only accessoryCircular
    }
}

#Preview(as: .accessoryRectangular) {
    ReconnaissanceWatchWidgets()
} timeline: {
    SimpleEntry(date: .now)
    SimpleEntry(date: .now)
}
