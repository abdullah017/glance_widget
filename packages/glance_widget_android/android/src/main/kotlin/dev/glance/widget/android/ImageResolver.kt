package dev.glance.widget.android

import java.net.URI

/** Where an image widget's picture comes from. */
sealed interface ImageSource {
    /** Bytes the app already supplied; nothing to fetch. */
    data class Inline(val base64: String) : ImageSource

    /** An address the plugin has to fetch before the widget can draw. */
    data class Remote(val url: String) : ImageSource

    /** An address the plugin refuses to fetch, and why. */
    data class Invalid(val reason: String) : ImageSource

    /** Neither source was supplied. Not an error -- just nothing to draw. */
    object None : ImageSource
}

/**
 * Decides what an image widget update is pointing at, and how far a picture has
 * to shrink before it is safe to hand to a widget host.
 *
 * Free of Android types on purpose, so both decisions can be tested on the JVM.
 */
object ImageResolver {
    /**
     * Only these are fetched. A widget update carries an app-supplied string
     * into a network stack, so `file://` and `content://` must not turn that
     * into a way to read arbitrary local data.
     */
    private val FETCHABLE_SCHEMES = setOf("http", "https")

    fun sourceOf(imageBase64: String?, imageUrl: String?): ImageSource {
        // Inline bytes win: they are already here and need no network.
        if (!imageBase64.isNullOrBlank()) return ImageSource.Inline(imageBase64)
        if (imageUrl.isNullOrBlank()) return ImageSource.None

        val scheme = runCatching { URI(imageUrl).scheme }.getOrNull()
            ?: return ImageSource.Invalid("imageUrl is not a valid URI: '$imageUrl'")

        return if (scheme.lowercase() in FETCHABLE_SCHEMES) {
            ImageSource.Remote(imageUrl)
        } else {
            ImageSource.Invalid("imageUrl scheme '$scheme' is not fetchable: '$imageUrl'")
        }
    }

    /**
     * The `BitmapFactory.Options.inSampleSize` to decode with, so a picture
     * lands at or just above [reqWidth] x [reqHeight].
     *
     * Without this a 4000x3000 photo decodes to roughly 48 MB of ARGB_8888,
     * overruns the limit on what can be handed to a widget host, and raises
     * `OutOfMemoryError` -- which is an `Error`, so the `catch (e: Exception)`
     * around a decode does not catch it and the host process dies.
     */
    fun sampleSizeFor(srcWidth: Int, srcHeight: Int, reqWidth: Int, reqHeight: Int): Int {
        if (srcWidth <= 0 || srcHeight <= 0 || reqWidth <= 0 || reqHeight <= 0) return 1

        var sampleSize = 1
        // Halve while BOTH sides still clear the request, so the shorter side
        // never falls below what was asked for.
        while (srcHeight / (sampleSize * 2) >= reqHeight && srcWidth / (sampleSize * 2) >= reqWidth) {
            sampleSize *= 2
        }
        return sampleSize
    }
}
