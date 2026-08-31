package dev.glance.widget.android

import androidx.compose.ui.unit.DpSize

/**
 * How much room a widget actually has, in three bands.
 *
 * A launcher hands the widget whatever the user dragged it to, which can be far
 * below the size it was designed against -- the templates declare
 * `minResizeHeight="40dp"` against a `minHeight` of 110dp. Painting one fixed
 * layout into all of them means the compact case overflows and the expanded
 * case wastes most of the slot.
 *
 * Classified by height. Height is what runs out first: a wide, short slot has
 * room for more text across but no room for another line, and it is the extra
 * line that pushes a template past its slot.
 *
 * Free of Glance types so the boundaries can be tested on the JVM.
 */
internal enum class WidgetSizeClass {
    /** Roughly one cell tall. Room for one thing; show the value. */
    COMPACT,

    /** Two or three cells. The layout the templates were originally drawn for. */
    MEDIUM,

    /** Four or more. Room for detail the smaller bands have to drop. */
    EXPANDED;

    companion object {
        /** Below this a slot holds a single line of content. */
        const val COMPACT_MAX_HEIGHT_DP = 80f

        /** Below this a slot holds the standard layout but no extras. */
        const val MEDIUM_MAX_HEIGHT_DP = 180f

        fun of(heightDp: Float): WidgetSizeClass {
            // Zero and NaN have both been seen from LocalSize during the first
            // composition after a resize. The compact layout fits everywhere,
            // so it is the safe answer for a size we cannot read.
            if (!heightDp.isFinite() || heightDp < COMPACT_MAX_HEIGHT_DP) return COMPACT
            return if (heightDp < MEDIUM_MAX_HEIGHT_DP) MEDIUM else EXPANDED
        }

        fun of(size: DpSize): WidgetSizeClass = of(size.height.value)
    }
}
