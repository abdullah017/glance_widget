#if canImport(ActivityKit)
import ActivityKit
#endif
import Foundation

/// One labelled value in a Live Activity's expanded presentation.
struct GlanceActivityStat: Codable, Hashable {
    let label: String
    let value: String
}

/// Why a Live Activity call could not be carried out.
///
/// These become the `code` Dart sees, so they are part of the API.
enum GlanceLiveActivityError: String, Error {
    /// The OS is older than 16.2, where `ActivityConfiguration` arrived.
    case unsupportedVersion = "LIVE_ACTIVITY_UNSUPPORTED"
    /// The user turned Live Activities off for this app in Settings.
    case notEnabled = "LIVE_ACTIVITY_DISABLED"
    /// `startLiveActivity` was called for an id that is already running.
    case alreadyRunning = "LIVE_ACTIVITY_ALREADY_RUNNING"
    /// `update` or `end` named an id with no activity behind it.
    case notFound = "LIVE_ACTIVITY_NOT_FOUND"
    /// The arguments from Dart were not the shape this expects.
    case malformedContent = "LIVE_ACTIVITY_BAD_CONTENT"

    var message: String {
        switch self {
        case .unsupportedVersion:
            return "Live Activities need iOS 16.2 or later."
        case .notEnabled:
            return "Live Activities are turned off for this app in Settings."
        case .alreadyRunning:
            return "An activity with that activityId is already running. "
                + "Use updateLiveActivity, or end it first."
        case .notFound:
            return "No running activity has that activityId. It may have "
                + "ended, or the user may have dismissed it."
        case .malformedContent:
            return "The Live Activity content was not the expected shape."
        }
    }
}

#if canImport(ActivityKit)

/// The one shape a Glance Live Activity can show.
///
/// The widget extension declares its own copy of this type, in its own module,
/// because an extension cannot import the plugin's Swift package. ActivityKit
/// matches a running activity to its presentation by the attributes **type
/// name and shape**, not by module -- measured, not assumed; see
/// `findings-live-activity-module-boundary.md`.
///
/// Which is also the hazard: renaming this type, or changing `ContentState`,
/// silently stops matching the copy in a developer's extension, with no
/// compile error on either side. `GlanceActivityAttributesTests` pins both.
@available(iOS 16.1, *)
struct GlanceActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let title: String
        let status: String
        let progress: Double?
        let stats: [GlanceActivityStat]
    }

    /// The caller's own id. ActivityKit assigns one of its own that Dart never
    /// sees, so this is what `update` and `end` look an activity up by.
    let activityId: String
}

@available(iOS 16.1, *)
extension GlanceActivityAttributes.ContentState {
    /// Reads the map the Dart side sends.
    ///
    /// `stats` crosses as an ordered list of pairs rather than a dictionary on
    /// purpose: they are drawn in the order they were written, and a
    /// dictionary has no order to carry.
    static func from(_ raw: Any?) throws -> Self {
        guard let map = raw as? [String: Any],
              let title = map["title"] as? String,
              let status = map["status"] as? String
        else {
            throw GlanceLiveActivityError.malformedContent
        }
        let stats: [GlanceActivityStat] = (map["stats"] as? [[String: Any]] ?? [])
            .compactMap { entry in
                guard let label = entry["label"] as? String,
                      let value = entry["value"] as? String
                else { return nil }
                return GlanceActivityStat(label: label, value: value)
            }
        return Self(
            title: title,
            status: status,
            progress: map["progress"] as? Double,
            stats: stats
        )
    }
}

/// Starts, updates and ends the plugin's Live Activities.
///
/// There is deliberately no registry of running activities here. An activity
/// outlives the process that requested it -- the app can be killed and
/// relaunched while the card is still on the Lock Screen -- so anything held in
/// memory would be wrong exactly when it mattered. `Activity.activities` is
/// asked every time instead; it is the system's list, not ours.
@available(iOS 16.2, *)
enum GlanceLiveActivityManager {

    static var areEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func isRunning(_ activityId: String) -> Bool {
        find(activityId) != nil
    }

    private static func find(_ activityId: String) -> Activity<GlanceActivityAttributes>? {
        Activity<GlanceActivityAttributes>.activities.first {
            $0.attributes.activityId == activityId
        }
    }

    static func start(
        activityId: String,
        state: GlanceActivityAttributes.ContentState
    ) throws {
        guard areEnabled else { throw GlanceLiveActivityError.notEnabled }
        guard find(activityId) == nil else {
            throw GlanceLiveActivityError.alreadyRunning
        }
        let activity = try Activity.request(
            attributes: GlanceActivityAttributes(activityId: activityId),
            content: .init(state: state, staleDate: nil)
        )
        GlanceLog.widget.notice(
            "Live Activity started for \(activityId, privacy: .public) as \(activity.id, privacy: .public)"
        )
    }

    static func update(
        activityId: String,
        state: GlanceActivityAttributes.ContentState
    ) async throws {
        guard let activity = find(activityId) else {
            throw GlanceLiveActivityError.notFound
        }
        await activity.update(.init(state: state, staleDate: nil))
    }

    static func end(
        activityId: String,
        state: GlanceActivityAttributes.ContentState?,
        dismissal: String
    ) async throws {
        guard let activity = find(activityId) else {
            throw GlanceLiveActivityError.notFound
        }
        let policy: ActivityUIDismissalPolicy =
            dismissal == "immediate" ? .immediate : .default
        let content = state.map {
            ActivityContent(state: $0, staleDate: nil)
        }
        await activity.end(content, dismissalPolicy: policy)
    }
}
#endif
