//
//  ReconnaissanceWatchWidgets.swift
//  ReconnaissanceWatchWidgets
//
//  Created by Jose Blanco on 12/18/24.
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

struct CircularShortcutWidgetView: View {
    var entry: SimpleEntry

    var body: some View {
        Link(destination: URL(string: "reconnaissance://")!) { // Replace "reconnaissance://" with your app's URL scheme
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2)) // Background
                Image(systemName: "app.fill") // Replace with a relevant SF Symbol
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
            }
        }
    }
}

@main
struct ReconnaissanceWatchWidgets: Widget {
    let kind: String = "ReconnaissanceWatchWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CircularShortcutWidgetView(entry: entry)
        }
        .configurationDisplayName("App Shortcut")
        .description("Quickly open Reconnaissance.")
        .supportedFamilies([.accessoryCircular])
    }
}
