package dev.glance.widget.android

/**
 * Decides what a removed widget takes with it.
 *
 * Dragging a widget off the home screen used to leave everything behind: its
 * downsampled image on disk, and its id in `getActiveWidgetIds()` forever. See
 * #13. The hook to fix it always existed -- `GlanceAppWidget.onDelete` runs
 * before Glance deletes the instance's own state -- and nothing was overriding
 * it.
 *
 * The decision is not simply "forget the id", because one id can name more than
 * one placed widget: [WidgetInstanceResolver] deliberately keeps two copies of
 * the same widget in sync. Removing the second copy of `btc` must not delete
 * the image the first copy is still drawing.
 *
 * Deliberately free of Android types so it can be checked on the JVM.
 */
object WidgetRemovalPolicy {

    /**
     * Whether [removedWidgetId]'s data is now unreachable.
     *
     * [survivingWidgetIds] are the ids carried by every instance still placed,
     * across all templates and with the removed one already excluded. A null or
     * blank entry is an instance that has never been written to; it carries no
     * id and so cannot be keeping one alive.
     */
    fun shouldForget(removedWidgetId: String?, survivingWidgetIds: List<String?>): Boolean {
        // An instance removed before its first update never claimed an id.
        // There is nothing keyed by it to delete, and no id to forget.
        if (removedWidgetId.isNullOrBlank()) return false

        return survivingWidgetIds.none { it == removedWidgetId }
    }
}
