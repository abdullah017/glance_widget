package dev.glance.widget.android

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.util.LruCache
import java.io.File

/**
 * Keeps decoded widget images around between compositions.
 *
 * A Glance composable body runs again on every recomposition, so decoding
 * inside it re-decoded the same picture every time the widget was redrawn.
 * Pictures here are already bounded by [ImageStore], so a handful of them cost
 * little to hold.
 */
internal object ImageCache {
    private const val TAG = "GlanceImageCache"

    /** Enough for several widgets' worth of 512px pictures. */
    private const val MAX_BYTES = 8 * 1024 * 1024

    private val cache = object : LruCache<String, Bitmap>(MAX_BYTES) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.byteCount
    }

    /**
     * The picture at [path], decoding it only if it is not already held.
     *
     * [stamp] is the update timestamp: the file is rewritten in place when a
     * widget's picture changes, so the path alone would keep serving the old
     * bitmap.
     */
    fun get(path: String, stamp: Long): Bitmap? {
        val key = "$path@$stamp"
        cache.get(key)?.let { return it }

        val bitmap = decode(path) ?: return null
        cache.put(key, bitmap)
        return bitmap
    }

    private fun decode(path: String): Bitmap? {
        return try {
            val file = File(path)
            if (!file.exists()) {
                Log.w(TAG, "Widget image is missing: $path")
                return null
            }
            BitmapFactory.decodeFile(path)
        } catch (e: OutOfMemoryError) {
            // Already bounded at store time; this is the backstop.
            Log.e(TAG, "Ran out of memory decoding $path", e)
            null
        }
    }

    fun clear() = cache.evictAll()
}
