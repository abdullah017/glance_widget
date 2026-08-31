package dev.glance.widget.android

import java.io.File
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.io.TempDir

/**
 * A widget that stops having a picture must stop having the file behind it too.
 *
 * `remove(imagePathKey)` in the manager drops the reference, which is what makes
 * the widget stop drawing the old picture -- but it leaves the file on disk with
 * nothing able to reach it. `ImageStore.evict` was written for that and was
 * never called from anywhere.
 */
class ImageStoreEvictionTest {

    private fun seed(cacheDir: File, widgetId: String): File =
        ImageStore.cacheFile(cacheDir, widgetId).apply { writeBytes(byteArrayOf(1, 2, 3)) }

    @Test
    fun `an update carrying no image drops the file the widget used to show`(@TempDir cacheDir: File) {
        val cached = seed(cacheDir, "btc")
        assertTrue(cached.exists(), "precondition: the widget has a cached picture")

        val result = runBlocking { ImageStore.store(cacheDir, "btc", null, null) }

        assertTrue(result is ImageStore.Result.Empty, "no source is not a failure, just nothing to draw")
        assertFalse(cached.exists(), "the cached file outlived the picture it was for")
    }

    @Test
    fun `an update carrying no image leaves other widgets alone`(@TempDir cacheDir: File) {
        val mine = seed(cacheDir, "btc")
        val theirs = seed(cacheDir, "eth")

        runBlocking { ImageStore.store(cacheDir, "btc", null, null) }

        assertFalse(mine.exists())
        assertTrue(theirs.exists(), "another widget's picture was collateral damage")
    }

    @Test
    fun `evicting a widget that never had a picture is not an error`(@TempDir cacheDir: File) {
        ImageStore.evict(cacheDir, "never-seen")

        assertFalse(ImageStore.cacheFile(cacheDir, "never-seen").exists())
    }

    /**
     * Widget ids come from the app and may contain path separators, so they are
     * hashed rather than used as a path segment.
     */
    @Test
    fun `a widget id is never used as a path segment`(@TempDir cacheDir: File) {
        val file = ImageStore.cacheFile(cacheDir, "../../etc/passwd")

        assertTrue(file.parentFile == cacheDir, "escaped the cache directory: ${file.path}")
        assertTrue(file.name.endsWith(".png"))
    }

    @Test
    fun `two widgets do not share a file`(@TempDir cacheDir: File) {
        assertTrue(ImageStore.cacheFile(cacheDir, "btc") != ImageStore.cacheFile(cacheDir, "eth"))
    }
}
