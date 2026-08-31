package dev.glance.widget.android

import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.glance.appwidget.SizeMode

/**
 * The slots the templates declare to Glance.
 *
 * `SizeMode.Responsive` builds one layout per declared size up front and lets
 * the launcher pick between them without another round trip to the app. The
 * alternative, `SizeMode.Exact`, asks the app to recompose on every resize --
 * more layouts than the launcher will ever show, and a wake-up each time the
 * user drags a corner.
 *
 * The three sizes are the boundaries of [WidgetSizeClass], not arbitrary
 * points: one per band, so the band a template sees is the band it declared.
 */
internal object WidgetSlots {

    private val compact = DpSize(110.dp, 40.dp)
    private val medium = DpSize(180.dp, 110.dp)
    private val expanded = DpSize(250.dp, 250.dp)

    /** For templates a user can shrink to a single line. */
    val resizable = SizeMode.Responsive(setOf(compact, medium, expanded))

    /** For templates whose smallest declared slot is already two cells tall. */
    val tall = SizeMode.Responsive(setOf(medium, expanded))
}
