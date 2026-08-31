package dev.glance.widget.android

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * One type and spacing scale for every template.
 *
 * Each template used to carry its own literals, which is how seven widgets end
 * up disagreeing about what a title looks like while sitting on the same home
 * screen. It also made the compact band unfixable one template at a time: the
 * numbers that overflow a 40dp slot are the same numbers in each of them.
 *
 * The compact row is the one with a constraint behind it rather than a
 * preference. A launcher can hand a template a slot as short as the
 * `minResizeHeight` its consumer declares, and 40dp is what this plugin's own
 * `simple_widget_info.xml` allows. A 20sp value at roughly 1.3x line height is
 * 26dp; 4dp of padding top and bottom brings it to 34dp. That leaves headroom
 * at a font scale above 1.0, and it is why compact padding is 4dp rather than
 * the 16dp the other bands use -- there is nothing else to give.
 *
 * Free of Glance types so it can be checked on the JVM.
 */
internal object WidgetTypeScale {

    /** The label above the thing the widget exists to show. */
    fun title(sizeClass: WidgetSizeClass): TextUnit = when (sizeClass) {
        WidgetSizeClass.COMPACT -> 12.sp
        WidgetSizeClass.MEDIUM -> 14.sp
        WidgetSizeClass.EXPANDED -> 16.sp
    }

    /** The thing itself: the number, the percentage, the reading. */
    fun value(sizeClass: WidgetSizeClass): TextUnit = when (sizeClass) {
        WidgetSizeClass.COMPACT -> 20.sp
        WidgetSizeClass.MEDIUM -> 28.sp
        WidgetSizeClass.EXPANDED -> 36.sp
    }

    /** Supporting text: subtitles, axis labels, item detail. */
    fun caption(sizeClass: WidgetSizeClass): TextUnit = when (sizeClass) {
        WidgetSizeClass.COMPACT -> 10.sp
        WidgetSizeClass.MEDIUM -> 12.sp
        WidgetSizeClass.EXPANDED -> 14.sp
    }

    /** Body text inside a list or a row, where the value is not a number. */
    fun body(sizeClass: WidgetSizeClass): TextUnit = when (sizeClass) {
        WidgetSizeClass.COMPACT -> 12.sp
        WidgetSizeClass.MEDIUM -> 14.sp
        WidgetSizeClass.EXPANDED -> 16.sp
    }

    /** Padding around the whole widget. */
    fun padding(sizeClass: WidgetSizeClass): Dp = when (sizeClass) {
        WidgetSizeClass.COMPACT -> 4.dp
        WidgetSizeClass.MEDIUM -> 16.dp
        WidgetSizeClass.EXPANDED -> 16.dp
    }

    /** Vertical gap between stacked elements. */
    fun gap(sizeClass: WidgetSizeClass): Dp = when (sizeClass) {
        WidgetSizeClass.COMPACT -> 2.dp
        WidgetSizeClass.MEDIUM -> 8.dp
        WidgetSizeClass.EXPANDED -> 12.dp
    }
}
