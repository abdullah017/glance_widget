package dev.glance.widget.android

import android.content.Context
import android.util.Log
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.state.updateAppWidgetState
import dev.glance.widget.android.templates.ListGlanceWidget

/**
 * Ticks a checkbox from the widget, without an Activity and without Dart.
 *
 * The checkbox used to call `GlanceWidgetManager.sendActionEvent` from a Glance
 * lambda action. That runs in the app's process, which the system starts for
 * the broadcast if it is not already up -- and a process started that way has
 * no Flutter engine in it. The event went to a null sink and was dropped, and
 * nothing wrote the new state either, so ticking a box from the home screen
 * while the app was closed did nothing at all and left no trace.
 *
 * An `ActionCallback` fixes both halves: `onAction` is a suspend function, so
 * it can write the widget's own state, and the interaction is queued for Dart
 * rather than shouted into a process that cannot hear it.
 */
class ToggleListItemAction : ActionCallback {

    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val widgetId = parameters[widgetIdKey] ?: return
        val index = parameters[itemIndexKey] ?: return

        var checked: Boolean? = null
        updateAppWidgetState(context, glanceId) { prefs ->
            val toggled = ListItems.toggling(prefs[GlanceWidgetManager.itemsKey], index) {
                Log.e(TAG, "Failed to read the list's items while toggling", it)
            }
            // A widget on screen can be several updates behind its own state,
            // so this is the fourth row of a list that now has two. Leave the
            // state alone; the redraw below shows the real list.
            if (toggled != null) {
                prefs[GlanceWidgetManager.itemsKey] = toggled.items
                checked = toggled.checked
            }
        }

        ListGlanceWidget().update(context, glanceId)

        val newValue = checked ?: return
        GlanceWidgetManager.recordActionEvent(
            context = context,
            widgetId = widgetId,
            actionType = "checkboxToggle",
            payload = mapOf("itemIndex" to index, "value" to newValue)
        )
    }

    companion object {
        private const val TAG = "GlanceToggleItem"

        /** Which widget the tapped checkbox belongs to. */
        val widgetIdKey = ActionParameters.Key<String>("widgetId")

        /** Which row was tapped. */
        val itemIndexKey = ActionParameters.Key<Int>("itemIndex")

        /** The parameters a checkbox at [index] of [widgetId] runs with. */
        fun parametersFor(widgetId: String, index: Int): ActionParameters =
            actionParametersOf(widgetIdKey to widgetId, itemIndexKey to index)
    }
}
