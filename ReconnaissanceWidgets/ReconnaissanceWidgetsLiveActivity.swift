//
//  ReconnaissanceWidgetsLiveActivity.swift
//  ReconnaissanceWidgets
//
//  Created by Jose Blanco on 12/17/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ReconnaissanceWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ReconnaissanceWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReconnaissanceWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ReconnaissanceWidgetsAttributes {
    fileprivate static var preview: ReconnaissanceWidgetsAttributes {
        ReconnaissanceWidgetsAttributes(name: "World")
    }
}

extension ReconnaissanceWidgetsAttributes.ContentState {
    fileprivate static var smiley: ReconnaissanceWidgetsAttributes.ContentState {
        ReconnaissanceWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ReconnaissanceWidgetsAttributes.ContentState {
         ReconnaissanceWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ReconnaissanceWidgetsAttributes.preview) {
   ReconnaissanceWidgetsLiveActivity()
} contentStates: {
    ReconnaissanceWidgetsAttributes.ContentState.smiley
    ReconnaissanceWidgetsAttributes.ContentState.starEyes
}
