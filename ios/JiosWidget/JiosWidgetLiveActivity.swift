//
//  JiosWidgetLiveActivity.swift
//  JiosWidget
//
//  Created by EternallyAscend on 2026/3/18.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct JiosWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct JiosWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: JiosWidgetAttributes.self) { context in
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

extension JiosWidgetAttributes {
    fileprivate static var preview: JiosWidgetAttributes {
        JiosWidgetAttributes(name: "World")
    }
}

extension JiosWidgetAttributes.ContentState {
    fileprivate static var smiley: JiosWidgetAttributes.ContentState {
        JiosWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: JiosWidgetAttributes.ContentState {
         JiosWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: JiosWidgetAttributes.preview) {
   JiosWidgetLiveActivity()
} contentStates: {
    JiosWidgetAttributes.ContentState.smiley
    JiosWidgetAttributes.ContentState.starEyes
}
