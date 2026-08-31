package dev.glance.widget.android

/**
 * Translates the metric list Dart sends into what the two gauge templates read.
 *
 * `GaugeWidgetData.toMap()` sends `title`, `metrics`, `gaugeType` and
 * `deepLinkUri`, and each metric carries `label`, `value` (a number),
 * `maxValue`, `color` and `unit`. Neither template could use that:
 *
 *  - the radial branch looked for top-level `progress`, `value`, `gaugeColor`,
 *    `minLabel` and `maxLabel` keys, none of which are ever sent, so every
 *    gauge drew an empty arc reading "0%";
 *  - the dashboard branch forwarded the metrics untouched, but the template
 *    reads `value` as a String and wants a `progress` fraction, so every card
 *    showed an empty value and no bar.
 *
 * Both shapes are decided here, free of Android types, so the arithmetic and
 * the key names can be checked on the JVM.
 */
internal object GaugeMetrics {
    private const val DARK_TRACK = 0xFF3A3A4E.toInt()
    private const val LIGHT_TRACK = 0xFFE0E0E0.toInt()

    /**
     * The metric maps of [data], with anything that is not a map dropped.
     */
    fun metricsOf(data: Map<String, Any?>): List<Map<*, *>> =
        (data["metrics"] as? List<*>)?.filterIsInstance<Map<*, *>>() ?: emptyList()

    /**
     * The fraction [metric] fills, between 0 and 1.
     *
     * A maximum of zero or less has no meaningful fraction. Dart's
     * `GaugeMetric` asserts against it, but an assert is stripped from release
     * builds and this map can also arrive from a native caller.
     */
    fun progressOf(metric: Map<*, *>): Float {
        val value = (metric["value"] as? Number)?.toDouble() ?: return 0f
        val maxValue = (metric["maxValue"] as? Number)?.toDouble() ?: 0.0
        if (maxValue <= 0) return 0f
        return (value / maxValue).coerceIn(0.0, 1.0).toFloat()
    }

    /**
     * The text shown for [metric]: its value, then its unit if it has one.
     *
     * The iOS template draws the unit on its own line under the value. The
     * Android gauge has one line of centred text, so it is appended instead.
     */
    fun valueTextOf(metric: Map<*, *>): String {
        val value = (metric["value"] as? Number)?.toDouble() ?: return ""
        return format(value) + (metric["unit"] as? String).orEmpty()
    }

    /**
     * Formats a metric number the way the iOS template does: whole numbers lose
     * their decimal point, everything else keeps one digit.
     */
    fun format(value: Double): String =
        if (!value.isNaN() && !value.isInfinite() && value == Math.floor(value)) {
            value.toLong().toString()
        } else {
            String.format("%.1f", value)
        }

    /**
     * The metrics rewritten into the shape `GaugeGlanceWidget.parseMetrics`
     * reads: a formatted `value` string and a ready `progress` fraction.
     */
    fun forDashboard(data: Map<String, Any?>): List<Map<String, Any?>> =
        metricsOf(data).map { metric ->
            mapOf(
                "label" to (metric["label"] as? String).orEmpty(),
                "value" to valueTextOf(metric),
                "color" to (metric["color"] as? Number)?.toInt(),
                "progress" to progressOf(metric)
            )
        }

    /**
     * Everything the radial gauge bitmap needs, or null when there is no usable
     * metric -- an empty list, a missing key, or an entry that is not a map. A
     * gauge with nothing to show is not an error; the caller draws its
     * "No gauge data" placeholder instead.
     */
    fun forRadial(
        data: Map<String, Any?>,
        accentColor: Int,
        isDark: Boolean
    ): RadialGaugeParams? {
        val metric = metricsOf(data).firstOrNull() ?: return null
        if (metric["value"] !is Number) return null
        val maxValue = (metric["maxValue"] as? Number)?.toDouble() ?: 0.0

        return RadialGaugeParams(
            progress = progressOf(metric),
            gaugeColor = (metric["color"] as? Number)?.toInt() ?: accentColor,
            trackColor = if (isDark) DARK_TRACK else LIGHT_TRACK,
            valueText = valueTextOf(metric),
            minLabel = "0",
            maxLabel = format(maxValue)
        )
    }
}

/** What [GaugeMetrics.forRadial] resolved out of the first metric. */
internal data class RadialGaugeParams(
    val progress: Float,
    val gaugeColor: Int,
    val trackColor: Int,
    val valueText: String,
    val minLabel: String,
    val maxLabel: String
)
