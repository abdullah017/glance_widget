package dev.glance.widget.android

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.action.Action
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback

/**
 * Reports a widget tap to Dart, queueing it when Dart is not there to hear it.
 *
 * Every template used to report taps from a Glance lambda action:
 *
 * ```kotlin
 * .clickable { GlanceWidgetManager.sendActionEvent(widgetId, "tap") }
 * ```
 *
 * That block runs in the app's process, which the system starts for the
 * broadcast if it is not already up -- and a process started that way has no
 * Flutter engine in it. `sendActionEvent` posts to a null sink, so every tap on
 * a widget belonging to a closed app was dropped without a trace. An
 * `ActionCallback` gets a `Context`, which is what reaches the queue.
 *
 * A tap that opens a deep link still uses `actionStartActivity`: opening the
 * app is what a deep link is for, and the launch is the notification.
 */
class ReportActionCallback : ActionCallback {

    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val widgetId = parameters[widgetIdKey] ?: return
        val actionType = parameters[actionTypeKey] ?: return
        val index = parameters[indexKey]

        GlanceWidgetManager.recordActionEvent(
            context = context,
            widgetId = widgetId,
            actionType = actionType,
            payload = index?.let { mapOf(parameters[indexNameKey].orEmpty() to it) }
        )
    }

    companion object {
        /** Which widget was tapped. */
        val widgetIdKey = ActionParameters.Key<String>("widgetId")

        /** The action name Dart already knows, such as `tap` or `itemTap`. */
        val actionTypeKey = ActionParameters.Key<String>("actionType")

        /** Which row, when the tap was on one. */
        val indexKey = ActionParameters.Key<Int>("index")

        /**
         * What the index is called in the payload.
         *
         * The templates are not consistent: a list row sends `itemIndex` and a
         * calendar event sends `index`. Both names are already in the wild and
         * in whatever `onAction` handlers callers have written, so the name
         * travels with the action rather than being unified here -- that would
         * be a silent breaking change to every existing handler.
         */
        val indexNameKey = ActionParameters.Key<String>("indexName")

        /** The action for a plain tap on [widgetId]'s widget. */
        fun tap(widgetId: String, actionType: String): Action =
            actionRunCallback<ReportActionCallback>(
                actionParametersOf(widgetIdKey to widgetId, actionTypeKey to actionType)
            )

        /** The action for a tap on row [index], reported under [indexName]. */
        fun tapAt(
            widgetId: String,
            actionType: String,
            index: Int,
            indexName: String = "index"
        ): Action =
            actionRunCallback<ReportActionCallback>(
                actionParametersOf(
                    widgetIdKey to widgetId,
                    actionTypeKey to actionType,
                    indexKey to index,
                    indexNameKey to indexName
                )
            )
    }
}
