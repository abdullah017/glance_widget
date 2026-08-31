package dev.glance.widget.android

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import android.util.Log
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Turns an image widget's declared source into a small file on disk, ahead of
 * the widget ever being drawn.
 *
 * Fetching and decoding happen here, at update time, rather than in the
 * template. A Glance composition runs inside the host's process on the host's
 * schedule; it is not a place to do network or heavy decode work, and a widget
 * host will not wait for it.
 */
internal object ImageStore {
    private const val TAG = "GlanceImageStore"
    private const val CACHE_DIR = "glance_widget_images"

    /**
     * Widgets are small and the picture has to survive an IPC hand-off to the
     * host, so this is deliberately far below the source resolution of any
     * modern camera.
     */
    private const val MAX_EDGE_PX = 512

    private const val CONNECT_TIMEOUT_MS = 10_000
    private const val READ_TIMEOUT_MS = 15_000

    /** Refuses anything larger before a byte of it is decoded. */
    private const val MAX_DOWNLOAD_BYTES = 16L * 1024 * 1024

    sealed interface Result {
        /** The picture is at [path], already downsampled. */
        data class Stored(val path: String) : Result

        /** There was no picture to store. */
        object Empty : Result

        /** The picture could not be produced, and why. */
        data class Failed(val reason: String) : Result
    }

    suspend fun store(
        context: Context,
        widgetId: String,
        imageBase64: String?,
        imageUrl: String?
    ): Result = withContext(Dispatchers.IO) {
        val bytes = when (val source = ImageResolver.sourceOf(imageBase64, imageUrl)) {
            is ImageSource.None -> return@withContext Result.Empty
            is ImageSource.Invalid -> return@withContext Result.Failed(source.reason)
            is ImageSource.Inline ->
                runCatching { Base64.decode(source.base64, Base64.DEFAULT) }
                    .getOrElse { return@withContext Result.Failed("imageBase64 is not valid base64") }
            is ImageSource.Remote ->
                when (val fetched = download(source.url)) {
                    is Fetched.Ok -> fetched.bytes
                    is Fetched.Err -> return@withContext Result.Failed(fetched.reason)
                }
        }

        val bitmap = decodeDownsampled(bytes)
            ?: return@withContext Result.Failed("image data could not be decoded")

        writeToCache(context, widgetId, bitmap)
    }

    /** Drops the cached picture for [widgetId], if any. */
    fun evict(context: Context, widgetId: String) {
        runCatching { cacheFile(context, widgetId).delete() }
    }

    private fun cacheFile(context: Context, widgetId: String): File {
        val dir = File(context.cacheDir, CACHE_DIR).apply { mkdirs() }
        // Widget ids come from the app and may contain anything, so they are not
        // used as path segments directly.
        return File(dir, "${widgetId.hashCode().toUInt().toString(16)}.png")
    }

    private fun writeToCache(context: Context, widgetId: String, bitmap: Bitmap): Result {
        return try {
            val file = cacheFile(context, widgetId)
            // Written beside the target and renamed, so a reader never sees a
            // half-written file if the process dies mid-write.
            val temp = File(file.parentFile, "${file.name}.tmp")
            temp.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            if (!temp.renameTo(file)) {
                temp.delete()
                return Result.Failed("could not move the decoded image into the cache")
            }
            Result.Stored(file.absolutePath)
        } catch (e: IOException) {
            Log.e(TAG, "Failed to cache image for $widgetId", e)
            Result.Failed("could not write the decoded image to the cache: ${e.message}")
        } finally {
            bitmap.recycle()
        }
    }

    /**
     * Decodes at a reduced size.
     *
     * `OutOfMemoryError` is an `Error`, not an `Exception`, so the usual
     * `catch (e: Exception)` around a decode never caught it and the host
     * process died instead. Bounding the decode is the real fix; catching it is
     * the backstop for the case the bound is still not enough.
     */
    private fun decodeDownsampled(bytes: ByteArray): Bitmap? {
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)

            val options = BitmapFactory.Options().apply {
                inSampleSize = ImageResolver.sampleSizeFor(
                    bounds.outWidth,
                    bounds.outHeight,
                    MAX_EDGE_PX,
                    MAX_EDGE_PX
                )
            }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "Ran out of memory decoding a widget image", e)
            null
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "Malformed image data", e)
            null
        }
    }

    private sealed interface Fetched {
        data class Ok(val bytes: ByteArray) : Fetched
        data class Err(val reason: String) : Fetched
    }

    private fun download(url: String): Fetched {
        var connection: HttpURLConnection? = null
        return try {
            connection = (URL(url).openConnection() as HttpURLConnection).apply {
                connectTimeout = CONNECT_TIMEOUT_MS
                readTimeout = READ_TIMEOUT_MS
                instanceFollowRedirects = true
                requestMethod = "GET"
            }

            val status = connection.responseCode
            if (status !in 200..299) {
                return Fetched.Err("fetching imageUrl returned HTTP $status")
            }

            val declared = connection.contentLengthLong
            if (declared > MAX_DOWNLOAD_BYTES) {
                return Fetched.Err("imageUrl is ${declared} bytes, over the ${MAX_DOWNLOAD_BYTES} byte limit")
            }

            // A server may understate or omit the length, so the read is capped
            // as well rather than trusting the header.
            val bytes = connection.inputStream.use { it.readAtMost(MAX_DOWNLOAD_BYTES) }
                ?: return Fetched.Err("imageUrl exceeded the ${MAX_DOWNLOAD_BYTES} byte limit while downloading")

            Fetched.Ok(bytes)
        } catch (e: CancellationException) {
            throw e
        } catch (e: IOException) {
            Log.e(TAG, "Failed to fetch $url", e)
            Fetched.Err("could not fetch imageUrl: ${e.message}")
        } finally {
            connection?.disconnect()
        }
    }

    /** Reads the whole stream, or null once it goes past [limit]. */
    private fun java.io.InputStream.readAtMost(limit: Long): ByteArray? {
        val out = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(8 * 1024)
        var total = 0L
        while (true) {
            val read = read(buffer)
            if (read == -1) break
            total += read
            if (total > limit) return null
            out.write(buffer, 0, read)
        }
        return out.toByteArray()
    }
}
