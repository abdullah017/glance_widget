package dev.glance.widget.android

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.datastore.preferences.core.Preferences
import androidx.glance.GlanceTheme
import androidx.glance.unit.ColorProvider

/**
 * The four colours every template paints with.
 *
 * Each template used to resolve these itself, which meant the same four
 * `prefs[...] ?: default` blocks appeared seven times, and the defaults drifted
 * between them. Resolving in one place is also what makes Material You a single
 * change rather than seven.
 */
internal data class WidgetColors(
    val background: ColorProvider,
    val text: ColorProvider,
    val secondaryText: ColorProvider,
    val accent: ColorProvider
)

/**
 * Resolves the colours for a widget, in order: the wallpaper palette if the
 * theme asked for it and the device can supply one, then the colours set on the
 * theme, then the built-in defaults.
 *
 * Note the middle step. On Android 11 and below a widget that asked for dynamic
 * colour lands here on its configured colours -- not on Glance's stand-in for a
 * wallpaper palette, which is Material's baseline purple. See [DynamicColors].
 */
@Composable
internal fun widgetColors(prefs: Preferences): WidgetColors {
    val isDark = prefs[GlanceWidgetManager.isDarkKey] ?: true

    if (DynamicColors.shouldApply(prefs[GlanceWidgetManager.useDynamicColorKey])) {
        val colors = GlanceTheme.colors
        return WidgetColors(
            background = colors.surface,
            text = colors.onSurface,
            secondaryText = colors.onSurfaceVariant,
            accent = colors.primary
        )
    }

    return WidgetColors(
        background = prefs[GlanceWidgetManager.backgroundColorKey]
            ?.let { ColorProvider(Color(it)) }
            ?: ColorProvider(Color(if (isDark) 0xFF1A1A2E.toInt() else 0xFFFFFFFF.toInt())),
        text = prefs[GlanceWidgetManager.textColorKey]
            ?.let { ColorProvider(Color(it)) }
            ?: ColorProvider(Color(if (isDark) 0xFFFFFFFF.toInt() else 0xFF212121.toInt())),
        secondaryText = prefs[GlanceWidgetManager.secondaryTextColorKey]
            ?.let { ColorProvider(Color(it)) }
            ?: ColorProvider(Color(if (isDark) 0xFFB0B0B0.toInt() else 0xFF757575.toInt())),
        accent = prefs[GlanceWidgetManager.accentColorKey]
            ?.let { ColorProvider(Color(it)) }
            ?: ColorProvider(Color(0xFF2196F3.toInt()))
    )
}
