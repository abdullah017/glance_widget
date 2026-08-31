package dev.glance.widget.android

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * The gauge templates read a different shape than `GaugeWidgetData.toMap()`
 * writes, and neither side used to bridge it. These tests pin both ends: the
 * keys Dart sends (`label`, `value`, `maxValue`, `color`, `unit`) and the keys
 * the templates read (`value` as text, `progress` as a fraction).
 */
class GaugeMetricsTest {

    private val accent = 0xFF2196F3.toInt()

    private fun metric(
        label: String = "CPU",
        value: Any? = 42.0,
        maxValue: Any? = 100.0,
        color: Int? = null,
        unit: String? = null
    ): Map<String, Any?> = mapOf(
        "label" to label,
        "value" to value,
        "maxValue" to maxValue,
        "color" to color,
        "unit" to unit
    )

    private fun data(vararg metrics: Any?): Map<String, Any?> =
        mapOf("title" to "Server", "metrics" to metrics.toList())

    // --- radial -------------------------------------------------------------

    @Test
    fun `progress comes from the first metric`() {
        val params = GaugeMetrics.forRadial(
            data(metric(value = 25.0, maxValue = 50.0)),
            accent,
            isDark = true
        )

        assertEquals(0.5f, params!!.progress, 0.0001f)
    }

    @Test
    fun `the value text is the metric value, not a percentage of nothing`() {
        val params = GaugeMetrics.forRadial(data(metric(value = 42.0)), accent, isDark = true)

        assertEquals("42", params!!.valueText)
    }

    @Test
    fun `a fractional value keeps one decimal`() {
        val params = GaugeMetrics.forRadial(data(metric(value = 42.55)), accent, isDark = true)

        assertEquals("42.6", params!!.valueText)
    }

    @Test
    fun `the unit is appended to the value`() {
        val params = GaugeMetrics.forRadial(
            data(metric(value = 42.0, unit = "%")),
            accent,
            isDark = true
        )

        assertEquals("42%", params!!.valueText)
    }

    @Test
    fun `labels span zero to the metric maximum`() {
        val params = GaugeMetrics.forRadial(data(metric(maxValue = 250.0)), accent, isDark = true)

        assertEquals("0", params!!.minLabel)
        assertEquals("250", params.maxLabel)
    }

    @Test
    fun `the metric colour wins over the theme accent`() {
        val params = GaugeMetrics.forRadial(
            data(metric(color = 0xFFFF0000.toInt())),
            accent,
            isDark = true
        )

        assertEquals(0xFFFF0000.toInt(), params!!.gaugeColor)
    }

    @Test
    fun `without a metric colour the theme accent is used`() {
        val params = GaugeMetrics.forRadial(data(metric()), 0xFF00FF00.toInt(), isDark = true)

        assertEquals(0xFF00FF00.toInt(), params!!.gaugeColor)
    }

    @Test
    fun `progress is clamped when the value runs past the maximum`() {
        val params = GaugeMetrics.forRadial(
            data(metric(value = 300.0, maxValue = 100.0)),
            accent,
            isDark = true
        )

        assertEquals(1f, params!!.progress, 0.0001f)
    }

    @Test
    fun `a non-positive maximum draws an empty arc rather than dividing by zero`() {
        val params = GaugeMetrics.forRadial(
            data(metric(value = 5.0, maxValue = 0.0)),
            accent,
            isDark = true
        )

        assertEquals(0f, params!!.progress, 0.0001f)
    }

    @Test
    fun `the track colour follows the theme brightness`() {
        val dark = GaugeMetrics.forRadial(data(metric()), accent, isDark = true)
        val light = GaugeMetrics.forRadial(data(metric()), accent, isDark = false)

        assertEquals(0xFF3A3A4E.toInt(), dark!!.trackColor)
        assertEquals(0xFFE0E0E0.toInt(), light!!.trackColor)
    }

    @Test
    fun `no usable metric means no gauge to draw`() {
        assertNull(GaugeMetrics.forRadial(data(), accent, isDark = true))
        assertNull(GaugeMetrics.forRadial(emptyMap(), accent, isDark = true))
        assertNull(GaugeMetrics.forRadial(data("not a metric"), accent, isDark = true))
        assertNull(GaugeMetrics.forRadial(data(metric(value = "42")), accent, isDark = true))
    }

    // --- dashboard ----------------------------------------------------------

    @Test
    fun `a dashboard card carries the keys the template reads`() {
        val cards = GaugeMetrics.forDashboard(data(metric(label = "RAM", value = 3.0, maxValue = 8.0, unit = " GB")))

        assertEquals(1, cards.size)
        assertEquals(setOf("label", "value", "color", "progress"), cards[0].keys)
    }

    @Test
    fun `a dashboard value is text, because the template casts it to String`() {
        val card = GaugeMetrics.forDashboard(data(metric(value = 3.0, unit = " GB")))[0]

        assertTrue(card["value"] is String, "value was ${card["value"]?.javaClass}")
        assertEquals("3 GB", card["value"])
    }

    @Test
    fun `a dashboard card carries a progress fraction the template can draw`() {
        val card = GaugeMetrics.forDashboard(data(metric(value = 3.0, maxValue = 8.0)))[0]

        assertEquals(0.375f, card["progress"] as Float, 0.0001f)
    }

    @Test
    fun `dashboard cards keep their order and their colours`() {
        val cards = GaugeMetrics.forDashboard(
            data(
                metric(label = "CPU", color = 0xFFFF0000.toInt()),
                metric(label = "RAM")
            )
        )

        assertEquals(listOf("CPU", "RAM"), cards.map { it["label"] })
        assertEquals(0xFFFF0000.toInt(), cards[0]["color"])
        assertNull(cards[1]["color"])
    }

    @Test
    fun `a dashboard entry that is not a map is dropped, not crashed on`() {
        val cards = GaugeMetrics.forDashboard(data("nonsense", metric(label = "RAM")))

        assertEquals(listOf("RAM"), cards.map { it["label"] })
    }
}
