package dev.glance.widget.android

/**
 * Turns a stored `GlanceTheme.borderRadius` into the value a template rounds by.
 *
 * Three of the seven templates read the preference into a local and then never
 * used it; the other four did not read it at all. `GlanceTheme.borderRadius`
 * therefore did nothing on Android while doing exactly what it says on iOS --
 * see #20. Pulling the decision out here is what lets the edges be checked
 * without rendering a widget, which a Composable in a Glance template cannot be.
 */
internal object CornerRadius {

    /** What a widget rounds by when the theme does not say. */
    const val DEFAULT_DP = 16f

    /**
     * The radius for a stored preference of [stored], in dp.
     *
     * The old code wrote `?.toInt() ?: 16`, which silently floored a 12.5dp
     * radius to 12. Dart sends a `double` and Glance takes a `Dp` built from a
     * `Float`, so there is no reason to pass through `Int` at all.
     */
    fun dpFor(stored: Float?): Float = when {
        // Not configured: the theme's own default, matching Dart's.
        stored == null -> DEFAULT_DP
        // A NaN or an infinity reaches Glance as a corner it cannot lay out.
        // Nothing in the Dart API produces one, but the value crosses a method
        // channel as an untyped number.
        !stored.isFinite() -> DEFAULT_DP
        // A negative radius is not a smaller corner, it is an invalid one.
        stored < 0f -> 0f
        else -> stored
    }
}
