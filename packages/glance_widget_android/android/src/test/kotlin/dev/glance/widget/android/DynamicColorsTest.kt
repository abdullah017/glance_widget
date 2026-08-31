package dev.glance.widget.android

import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Material You is not a "use it if you have it" feature here.
 *
 * Glance's [androidx.glance.color.DynamicThemeColorProviders] resolves through
 * its own `glance_color*` resources, and only the `values-v31` variant points
 * at `@android:color/system_accent1_*`. Below API 31 the plain `values` file
 * answers with the static Material baseline -- `#ff6750a4`, purple. So handing
 * those providers to an Android 11 device does not fall back to the app's own
 * theme, it silently replaces it with someone else's palette. Hence the gate.
 */
class DynamicColorsTest {

    @Test
    fun `android 12 and above can read the wallpaper palette`() {
        assertTrue(DynamicColors.isAvailable(sdkInt = 31))
        assertTrue(DynamicColors.isAvailable(sdkInt = 34))
        assertTrue(DynamicColors.isAvailable(sdkInt = 36))
    }

    @Test
    fun `below android 12 there is no wallpaper palette to read`() {
        assertFalse(DynamicColors.isAvailable(sdkInt = 30))
        assertFalse(DynamicColors.isAvailable(sdkInt = 26))
    }

    @Test
    fun `the theme's own colours win when dynamic colour was never asked for`() {
        assertFalse(DynamicColors.shouldApply(requested = false, sdkInt = 36))
        assertFalse(DynamicColors.shouldApply(requested = false, sdkInt = 26))
    }

    @Test
    fun `asking for dynamic colour on an old device falls back to the theme`() {
        // Not to Material purple, which is what handing Glance's providers
        // straight through would do.
        assertFalse(DynamicColors.shouldApply(requested = true, sdkInt = 30))
    }

    @Test
    fun `asking for dynamic colour on a capable device applies it`() {
        assertTrue(DynamicColors.shouldApply(requested = true, sdkInt = 31))
    }

    @Test
    fun `a null request is treated as not asked for`() {
        // The preference is absent for every widget stored before this feature
        // existed. Those must keep the colours they were given.
        assertFalse(DynamicColors.shouldApply(requested = null, sdkInt = 36))
    }
}
