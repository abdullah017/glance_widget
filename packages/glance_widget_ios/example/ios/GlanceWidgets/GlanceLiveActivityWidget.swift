#if canImport(ActivityKit)
import ActivityKit
#endif
import SwiftUI
import WidgetKit

// MARK: - Attributes
//
// This is the extension's own copy. The plugin declares an identically shaped,
// identically named type in its own module, and an extension cannot import a
// Swift package, so the duplication is unavoidable -- the same bargain
// `SharedModels.swift` already lives with.
//
// ActivityKit matches a running activity to the presentation that draws it by
// the attributes **type name and the shape of ContentState**, not by module.
// That was measured rather than assumed: see
// docs/findings-live-activity-module-boundary.md.
//
// So: rename this type or change a field, and nothing fails to compile on
// either side -- the activity just stops appearing. If you change one, change
// both.

struct GlanceActivityStat: Codable, Hashable {
    let label: String
    let value: String
}

#if canImport(ActivityKit)
@available(iOS 16.1, *)
struct GlanceActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let title: String
        let status: String
        let progress: Double?
        let stats: [GlanceActivityStat]
    }

    let activityId: String
}

/// Names this file's own copy of the type.
///
/// The plugin's test target compiles this file *and* links the plugin, so a
/// bare `GlanceActivityAttributes` there is ambiguous by design -- the
/// target-local copy wins, and a rename here would silently make the contract
/// test compare the plugin's copy against itself. Resolved in this file, this
/// alias always means the copy above.
typealias GlanceTemplateActivityAttributes = GlanceActivityAttributes

/// The same, for the stat type.
typealias GlanceTemplateActivityStat = GlanceActivityStat

// MARK: - Presentation

@available(iOS 16.2, *)
struct GlanceLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GlanceActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .padding(16)
                .activityBackgroundTint(Color.black.opacity(0.6))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.title).font(.caption).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.status).font(.caption).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let progress = context.state.progress {
                        ProgressView(value: progress)
                    }
                }
            } compactLeading: {
                Text(context.state.title.prefix(1))
            } compactTrailing: {
                Text(context.state.status).lineLimit(1)
            } minimal: {
                Text(context.state.title.prefix(1))
            }
        }
    }
}

@available(iOS 16.2, *)
private struct LockScreenView: View {
    let state: GlanceActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(state.title).font(.headline)
            Text(state.status).font(.subheadline)
            if let progress = state.progress {
                ProgressView(value: progress)
            }
            if !state.stats.isEmpty {
                HStack(spacing: 16) {
                    ForEach(state.stats, id: \.label) { stat in
                        VStack(alignment: .leading) {
                            Text(stat.label).font(.caption2).opacity(0.7)
                            Text(stat.value).font(.caption)
                        }
                    }
                }
            }
        }
    }
}
#endif
