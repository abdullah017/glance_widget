package dev.glance.widget.android

import android.os.Build

/**
 * Decides whether a widget should paint itself from the wallpaper.
 *
 * The gate is not a nicety. Glance's `DynamicThemeColorProviders` resolves
 * through its own `glance_color*` resources, and only the `values-v31` variant
 * points at `@android:color/system_accent1_*`. On anything older the plain
 * `values` file answers -- with the static Material baseline, `#ff6750a4`. So
 * handing those providers to an Android 11 device does not degrade to the app's
 * own theme, it silently repaints the widget purple. Below API 31 we therefore
 * ignore the request and use the colours the app actually configured.
 *
 * Kept free of Glance and Compose types so it can be tested on the JVM; the
 * SDK level is a parameter for the same reason.
 */
internal object DynamicColors {

    /** Whether this device exposes a wallpaper palette at all. */
    fun isAvailable(sdkInt: Int = Build.VERSION.SDK_INT): Boolean =
        sdkInt >= Build.VERSION_CODES.S

    /**
     * Whether to paint from the wallpaper.
     *
     * [requested] is null for every widget stored before this setting existed,
     * which must keep the colours it was given.
     */
    fun shouldApply(requested: Boolean?, sdkInt: Int = Build.VERSION.SDK_INT): Boolean =
        requested == true && isAvailable(sdkInt)
}
