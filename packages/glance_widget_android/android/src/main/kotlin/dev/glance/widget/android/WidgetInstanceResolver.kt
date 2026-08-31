package dev.glance.widget.android

/**
 * Decides which placed widget instances an update is addressed to.
 *
 * Android hands out every instance of a template class at once
 * (`GlanceAppWidgetManager.getGlanceIds(Class)`), and nothing in the Glance API
 * ties a host-assigned instance to the `widgetId` an app chose. That mapping
 * lives in each instance's own state, under [GlanceWidgetManager.widgetIdKey];
 * this is where it is read back.
 *
 * Deliberately free of Android types so the routing rules can be tested on the
 * JVM without a host, an emulator, or a DataStore.
 */
object WidgetInstanceResolver {
    /** One placed widget: an opaque handle plus the id it currently carries. */
    data class Instance<out T>(val handle: T, val widgetId: String?)

    /** Where an update should go. */
    sealed interface Resolution<out T> {
        /**
         * Write to [handles]. [adopted] marks an instance that did not carry
         * this id yet and is being claimed by this update.
         */
        data class Targets<out T>(val handles: List<T>, val adopted: Boolean) : Resolution<T>

        /** Nothing on the home screen can receive this update. */
        data class NoTarget(val reason: String) : Resolution<Nothing>
    }

    fun <T> resolve(instances: List<Instance<T>>, widgetId: String): Resolution<T> {
        if (instances.isEmpty()) {
            return Resolution.NoTarget("no instance of this template is placed on the home screen")
        }

        // An id may legitimately name more than one instance: placing the same
        // widget twice should keep both copies in sync.
        val matching = instances.filter { it.widgetId == widgetId }
        val unclaimed = instances.filter { it.widgetId.isNullOrBlank() }
        val foreign = instances.filter { !it.widgetId.isNullOrBlank() && it.widgetId != widgetId }

        if (matching.isNotEmpty()) {
            // A newly placed second copy should be filled rather than left
            // blank -- but only when no other id is in play, since otherwise
            // there is no way to tell which widget the blank one is meant to
            // become.
            val adoptable = if (foreign.isEmpty()) unclaimed else emptyList()
            return Resolution.Targets(
                (matching + adoptable).map { it.handle },
                adopted = adoptable.isNotEmpty()
            )
        }

        // A just-placed instance carries no id yet. Claim exactly one, so that
        // `update("btc")` followed by `update("eth")` fills one widget each
        // instead of painting both with the same data.
        if (unclaimed.isNotEmpty()) {
            return Resolution.Targets(listOf(unclaimed.first().handle), adopted = true)
        }

        // With a single instance there is nothing to disambiguate, so re-key it
        // rather than leave the only widget of an app that renamed its id
        // permanently unreachable.
        if (instances.size == 1) {
            return Resolution.Targets(listOf(instances.single().handle), adopted = true)
        }

        // Guessing here is exactly what let one id's update erase another's.
        val known = instances.mapNotNull { it.widgetId }.distinct().joinToString(", ")
        return Resolution.NoTarget(
            "no widget carries the id '$widgetId'; placed ids are: $known"
        )
    }
}
