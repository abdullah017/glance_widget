import AppIntents
import Foundation
import WidgetKit

// MARK: - Pending actions

/// An interaction this extension handled while the app was not running.
///
/// The field names and the JSON they encode to are a contract with the
/// plugin's `GlancePendingAction`, which cannot be imported here. They are
/// asserted on both sides -- `GlanceActionQueueTests` in the plugin, and
/// `GlanceInteractiveTests` against this copy -- because a drift between them
/// does not crash anything. It silently loses every interaction the user makes
/// while the app is closed, which is the whole point of the feature.
struct GlancePendingAction: Codable, Equatable {
    let widgetId: String
    let type: String
    let payload: [String: String]?
    let timestamp: Double
}

/// The queue's rules, as this side implements them.
enum GlanceActionQueue {
    /// The most actions the queue holds. Must match the plugin's `capacity`.
    ///
    /// An app that is never opened again would otherwise grow this without
    /// limit in storage the user cannot see.
    static let capacity = 100

    /// The key the plugin drains. Must match `GlanceStorageKeys.pendingActions`.
    static let storageKey = "pendingWidgetActions"

    /// [queue] with [action] on the end, oldest first, trimmed to `capacity`.
    static func appending(_ action: GlancePendingAction, to queue: [Data]) -> [Data] {
        guard let encoded = try? JSONEncoder().encode(action) else { return queue }
        let appended = queue + [encoded]
        guard appended.count > capacity else { return appended }
        return Array(appended.suffix(capacity))
    }
}

// MARK: - List toggling

/// The checkbox flip, as a function of the list rather than of storage.
///
/// The intent that calls this runs in a process with no app, no Flutter engine
/// and no test harness around it. Keeping the decision out here is what makes
/// the off-by-one and the empty-list case checkable at all.
enum GlanceListToggle {

    /// [items] with the one at [index] checked the other way, or `nil` when
    /// there is no such item.
    ///
    /// A stale widget is exactly where an out-of-range index comes from: the
    /// list on screen can be several updates behind what is stored, so the
    /// user taps row four of a list that now has two. Returning `nil` leaves
    /// storage untouched and the widget reloads to the real list.
    static func toggling(_ items: [ListItemData], at index: Int) -> [ListItemData]? {
        guard items.indices.contains(index) else { return nil }
        var toggled = items
        let item = items[index]
        toggled[index] = ListItemData(
            text: item.text,
            checked: !item.checked,
            secondaryText: item.secondaryText,
            iconName: item.iconName
        )
        return toggled
    }
}

// MARK: - Intent

/// Ticks a checkbox from the widget, without opening the app.
///
/// The previous behaviour was a `Link` to `glancewidget://action?...`, which
/// launches the app to tick a box -- on the lock screen that is a full unlock
/// and a cold start for a two-state toggle. Running here instead means the
/// widget updates in place; the app is told what happened the next time it
/// runs, by way of `GlanceActionQueue`.
struct GlanceToggleItemIntent: AppIntent {
    static var title: LocalizedStringResource { "Toggle List Item" }

    /// Kept out of Shortcuts and Spotlight. It is an implementation detail of
    /// a widget, not something a user should be able to run against an
    /// arbitrary index.
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Widget")
    var widgetId: String

    @Parameter(title: "Item")
    var itemIndex: Int

    init() {}

    /// Builds the intent a checkbox runs.
    init(widgetId: String, itemIndex: Int) {
        self.widgetId = widgetId
        self.itemIndex = itemIndex
    }

    func perform() async throws -> some IntentResult {
        WidgetStorage.shared.toggleListItem(widgetId: widgetId, itemIndex: itemIndex)
        WidgetCenter.shared.reloadTimelines(ofKind: "ListWidget")
        return .result()
    }
}

// MARK: - Storage

extension WidgetStorage {

    /// Flips the checkbox at [itemIndex] of [widgetId] and queues the action.
    ///
    /// The write happens here rather than being left to the app because the
    /// app may not run for hours. Without it the box springs back the moment
    /// the timeline reloads, which reads as the tap having failed.
    func toggleListItem(widgetId: String, itemIndex: Int) {
        guard let defaults = userDefaults,
              let data = loadListWidget(widgetId: widgetId),
              let toggled = GlanceListToggle.toggling(data.items, at: itemIndex) else {
            return
        }

        let updated = ListWidgetData(
            widgetId: data.widgetId,
            title: data.title,
            items: toggled,
            showCheckboxes: data.showCheckboxes,
            maxItems: data.maxItems,
            deepLinkUri: data.deepLinkUri,
            timestamp: Date().timeIntervalSince1970,
            theme: data.theme
        )
        guard let encoded = try? JSONEncoder().encode(updated) else { return }
        defaults.set(encoded, forKey: "listWidgetData_\(widgetId)")

        enqueue(
            GlancePendingAction(
                widgetId: widgetId,
                type: "checkboxToggle",
                payload: [
                    "itemIndex": String(itemIndex),
                    "value": String(toggled[itemIndex].checked)
                ],
                timestamp: Date().timeIntervalSince1970
            )
        )
    }

    /// Adds [action] to the queue the plugin drains when the app next runs.
    func enqueue(_ action: GlancePendingAction) {
        guard let defaults = userDefaults else { return }
        let existing = defaults.array(forKey: GlanceActionQueue.storageKey) as? [Data] ?? []
        defaults.set(
            GlanceActionQueue.appending(action, to: existing),
            forKey: GlanceActionQueue.storageKey
        )
    }
}
