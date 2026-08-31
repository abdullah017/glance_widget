package dev.glance.widget.android

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class ImageResolverTest {
    private fun remote(source: ImageSource): ImageSource.Remote {
        if (source !is ImageSource.Remote) error("expected a remote source, got $source")
        return source
    }

    private fun invalid(source: ImageSource): ImageSource.Invalid {
        if (source !is ImageSource.Invalid) error("expected an invalid source, got $source")
        return source
    }

    // `imageUrl` is documented, validated in Dart and sent over the channel, and
    // no native code on either platform ever read it. These pin it down.
    @Test
    fun `an image url is a source the plugin must resolve`() {
        val source = ImageResolver.sourceOf(imageBase64 = null, imageUrl = "https://example.com/a.png")

        assertEquals("https://example.com/a.png", remote(source).url)
    }

    @Test
    fun `inline bytes win over a url, since they need no network`() {
        val source = ImageResolver.sourceOf(imageBase64 = "AAAA", imageUrl = "https://example.com/a.png")

        assertEquals(ImageSource.Inline("AAAA"), source)
    }

    @Test
    fun `neither source given is not an error, just nothing to draw`() {
        assertEquals(ImageSource.None, ImageResolver.sourceOf(null, null))
        assertEquals(ImageSource.None, ImageResolver.sourceOf("", "   "))
    }

    @Test
    fun `only http and https are fetched`() {
        // A widget update is an app-supplied string reaching a network stack, so
        // file:// and friends must not become an arbitrary-read primitive.
        for (url in listOf("file:///etc/passwd", "content://media/1", "ftp://h/a.png", "javascript:x")) {
            assertTrue(url in invalid(ImageResolver.sourceOf(null, url)).reason, url)
        }
        assertEquals("http://example.com/a.png", remote(ImageResolver.sourceOf(null, "http://example.com/a.png")).url)
    }

    @Test
    fun `a malformed url is refused rather than thrown at the network stack`() {
        assertTrue(invalid(ImageResolver.sourceOf(null, "not a url")).reason.isNotEmpty())
    }

    // A 4000x3000 ARGB_8888 bitmap is ~48 MB and blows the RemoteViews limit.
    // `catch (e: Exception)` cannot catch the resulting OutOfMemoryError, so the
    // host process dies. Downsampling is what keeps that from happening.
    @Test
    fun `a large image is downsampled to fit the budget`() {
        // 4000x3000 at ARGB_8888 is ~48 MB. Sampling by 4 gives 1000x750, about
        // 3 MB, which a widget host can actually take.
        val sample = ImageResolver.sampleSizeFor(4000, 3000, 512, 512)

        assertEquals(4, sample)
        assertEquals(1000, 4000 / sample)
        assertEquals(750, 3000 / sample)
    }

    @Test
    fun `an image already within budget is not resampled`() {
        assertEquals(1, ImageResolver.sampleSizeFor(400, 300, 512, 512))
    }

    @Test
    fun `the sample size is always a power of two`() {
        for (width in listOf(513, 1000, 1023, 1025, 2049, 6000)) {
            val sample = ImageResolver.sampleSizeFor(width, width, 512, 512)
            assertTrue(sample > 0 && (sample and (sample - 1)) == 0, "$width -> $sample")
        }
    }

    @Test
    fun `a degenerate size never yields a zero sample size`() {
        // Integer division on a zero or negative bound would otherwise produce 0
        // and BitmapFactory treats that as 1 only by accident.
        assertEquals(1, ImageResolver.sampleSizeFor(0, 0, 512, 512))
        assertEquals(1, ImageResolver.sampleSizeFor(100, 100, 0, 0))
        assertEquals(1, ImageResolver.sampleSizeFor(-1, -1, 512, 512))
    }

    @Test
    fun `downsampling keeps the image at or above the requested size`() {
        // Halving too far would waste the budget on a blurry picture.
        val sample = ImageResolver.sampleSizeFor(2000, 1000, 512, 512)
        assertTrue(1000 / sample >= 512, "shortest side ${1000 / sample} fell below 512")
    }
}
