import 'package:flutter/widgets.dart';
import 'package:glance_widget/src/preview/android/android_painters.dart';
import 'package:glance_widget/src/preview/preview_context.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Draws [data] the way Jetpack Glance draws it on Android.
///
/// Every measurement here is transcribed from the composables in
/// `glance_widget_android/android/src/main/kotlin/.../templates/`. Glance's `sp`
/// and `dp` both map to Flutter's logical pixels at a text scale of 1, so the
/// numbers carry over unchanged; where they do not, the difference is called
/// out where it happens.
///
/// The differences from iOS are not accidents to be smoothed over. Android
/// centres the simple template and iOS stacks it; Android draws its chart and
/// gauge as rasterised bitmaps and iOS lays them out as views; Android's simple
/// template ignores `iconName` entirely. A preview that hid any of that would
/// be worse than no preview.
Widget buildAndroidPreview(PreviewContext context, WidgetData data) =>
    switch (data) {
      SimpleWidgetData() => _simple(context, data),
      ProgressWidgetData() => _progress(context, data),
      ListWidgetData() => _list(context, data),
      ImageWidgetData() => _image(context, data),
      ChartWidgetData() => _chart(context, data),
      CalendarWidgetData() => _calendar(context, data),
      GaugeWidgetData() => _gauge(context, data),
    };

/// The 16dp padding every Android template applies inside its background.
const EdgeInsets _padding = EdgeInsets.all(16);

/// Centres [child] and clips whatever does not fit.
///
/// A Glance widget cannot grow past the cell the launcher gave it: content that
/// does not fit is simply not drawn. Flutter would rather report an overflow,
/// so the clipping is made explicit here -- the preview has to be able to show
/// a layout that is too big for its slot, because that is the thing a developer
/// most needs to see.
Widget _clippedCenter(Widget child) => ClipRect(
  child: OverflowBox(
    maxHeight: double.infinity,
    alignment: Alignment.center,
    child: child,
  ),
);

TextStyle _style(Color color, double size, [FontWeight? weight]) =>
    TextStyle(color: color, fontSize: size, fontWeight: weight);

Widget _text(String value, TextStyle style, {int? maxLines}) => Text(
  value,
  style: style,
  maxLines: maxLines,
  overflow: maxLines == null ? null : TextOverflow.ellipsis,
);

// --- simple ------------------------------------------------------------------

Widget _simple(PreviewContext ctx, SimpleWidgetData data) => Padding(
  // `iconName` and `iconBase64` are not drawn: the Android template never
  // reads them, though the iOS one does. See the note on the file.
  padding: _padding,
  child: _clippedCenter(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _text(data.title, _style(ctx.secondaryText, 14, FontWeight.w500)),
        const SizedBox(height: 8),
        _text(data.value, _style(ctx.text, 28, FontWeight.bold)),
        if (data.subtitle case final subtitle?) ...[
          const SizedBox(height: 4),
          _text(
            subtitle,
            _style(
              data.subtitleColor ?? ctx.secondaryText,
              14,
              FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
  ),
);

// --- progress ----------------------------------------------------------------

Widget _progress(PreviewContext ctx, ProgressWidgetData data) {
  final progressColor = data.progressColor ?? ctx.accent;
  final trackColor = data.trackColor ?? ctx.track;
  final linear = data.progressType == ProgressType.linear;

  return Padding(
    padding: _padding,
    child: _clippedCenter(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _text(
            data.title,
            linear
                ? _style(ctx.text, 16, FontWeight.w500)
                : _style(ctx.secondaryText, 14, FontWeight.w500),
          ),
          const SizedBox(height: 12),
          if (linear)
            SizedBox(
              height: 8,
              width: double.infinity,
              child: _bar(
                progress: data.progress,
                color: progressColor,
                trackColor: trackColor,
              ),
            )
          else
            // The circular template draws a plain 80dp square filled with the
            // track colour and the percentage centred on it -- Glance has no
            // circular progress indicator, so there is no ring to draw.
            Container(
              width: 80,
              height: 80,
              color: trackColor,
              alignment: Alignment.center,
              child: _text(
                '${(data.progress * 100).toInt()}%',
                _style(ctx.text, 24, FontWeight.bold),
              ),
            ),
          if (data.subtitle case final subtitle?) ...[
            const SizedBox(height: 8),
            _text(subtitle, _style(ctx.secondaryText, linear ? 14 : 12)),
          ],
        ],
      ),
    ),
  );
}

/// A flat two-tone bar, the way Glance's `LinearProgressIndicator` draws --
/// square ends, no animation, no rounded cap.
Widget _bar({
  required double progress,
  required Color color,
  required Color trackColor,
}) => Stack(
  fit: StackFit.expand,
  children: [
    ColoredBox(color: trackColor),
    FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: progress.clamp(0.0, 1.0),
      child: ColoredBox(color: color),
    ),
  ],
);

// --- list --------------------------------------------------------------------

Widget _list(PreviewContext ctx, ListWidgetData data) => Padding(
  padding: _padding,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Flexible(
              child: _text(
                data.title,
                _style(ctx.text, 18, FontWeight.bold),
                maxLines: 1,
              ),
            ),
            const Spacer(),
            // The count is of every item, not of the ones that fit.
            _text('${data.items.length}', _style(ctx.secondaryText, 14)),
          ],
        ),
      ),
      Container(height: 1, color: ctx.track),
      const SizedBox(height: 8),
      Expanded(
        child: data.items.isEmpty
            ? Center(child: _text('No items', _style(ctx.secondaryText, 14)))
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final (index, item) in data.items.indexed)
                    _listRow(ctx, data, item, index),
                ],
              ),
      ),
    ],
  ),
);

Widget _listRow(
  PreviewContext ctx,
  ListWidgetData data,
  GlanceListItem item,
  int index,
) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      if (data.showCheckboxes)
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _checkbox(
            checked: item.checked,
            color: item.checked ? ctx.accent : ctx.secondaryText,
          ),
        ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              item.text,
              _style(
                item.checked && data.showCheckboxes
                    ? ctx.secondaryText
                    : ctx.text,
                14,
              ),
              maxLines: 1,
            ),
            if (item.secondaryText case final secondary?
                when secondary.isNotEmpty)
              _text(secondary, _style(ctx.secondaryText, 12), maxLines: 1),
          ],
        ),
      ),
    ],
  ),
);

/// Glance's `CheckBox` at the size and colours the list template gives it.
///
/// Drawn from shapes rather than the Material icon font, which is only bundled
/// when the host app sets `uses-material-design`. A preview that vanished in an
/// app built on `WidgetsApp` would be a poor tool.
Widget _checkbox({required bool checked, required Color color}) => SizedBox(
  width: 20,
  height: 20,
  child: CustomPaint(
    painter: _CheckboxPainter(checked: checked, color: color),
  ),
);

class _CheckboxPainter extends CustomPainter {
  const _CheckboxPainter({required this.checked, required this.color});

  final bool checked;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(2),
    );
    if (!checked) {
      canvas.drawRRect(
        box,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      return;
    }
    canvas.drawRRect(box, Paint()..color = color);
    final tick = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.34);
    canvas.drawPath(
      tick,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckboxPainter oldDelegate) =>
      oldDelegate.checked != checked || oldDelegate.color != color;
}

// --- image -------------------------------------------------------------------

Widget _image(PreviewContext ctx, ImageWidgetData data) => Padding(
  padding: _padding,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (data.title.isNotEmpty) ...[
        _text(data.title, _style(ctx.text, 16, FontWeight.bold)),
        const SizedBox(height: 8),
      ],
      Expanded(
        child: _placeholder(
          ctx,
          // The plugin downloads and downsamples the picture on the device;
          // there is nothing here that could fetch it, and inventing one would
          // make the preview show a layout the widget never has while the
          // download is still running.
          data.imageUrl == null && data.imageBase64 == null
              ? 'No image'
              : 'Image',
        ),
      ),
      if (data.subtitle case final subtitle? when subtitle.isNotEmpty) ...[
        const SizedBox(height: 8),
        _text(subtitle, _style(ctx.secondaryText, 14), maxLines: 2),
      ],
    ],
  ),
);

Widget _placeholder(PreviewContext ctx, String message) => Container(
  width: double.infinity,
  color: ctx.track,
  alignment: Alignment.center,
  child: _text(message, _style(ctx.secondaryText, 12)),
);

// --- chart -------------------------------------------------------------------

Widget _chart(PreviewContext ctx, ChartWidgetData data) => Padding(
  padding: _padding,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (data.title.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Flexible(
                child: _text(
                  data.title,
                  _style(ctx.text, 16, FontWeight.bold),
                  maxLines: 1,
                ),
              ),
              const Spacer(),
              _text(
                _capitalise(data.chartType.name),
                _style(ctx.secondaryText, 12),
              ),
            ],
          ),
        ),
      Expanded(
        child: data.dataPoints.isEmpty
            ? _placeholder(ctx, 'No chart data')
            : CustomPaint(
                size: Size.infinite,
                painter: AndroidChartPainter(
                  dataPoints: data.dataPoints,
                  chartType: data.chartType,
                  color: data.color ?? ctx.accent,
                  isDark: ctx.theme.isDark,
                ),
              ),
      ),
      if (data.subtitle case final subtitle? when subtitle.isNotEmpty) ...[
        const SizedBox(height: 8),
        _text(subtitle, _style(ctx.secondaryText, 14), maxLines: 1),
      ],
    ],
  ),
);

String _capitalise(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

// --- calendar ----------------------------------------------------------------

Widget _calendar(PreviewContext ctx, CalendarWidgetData data) {
  final events = data.events.take(data.maxEvents).toList();
  final hidden = data.events.length - events.length;

  return Padding(
    padding: _padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                color: ctx.accent,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _text(
                      '${data.date.day}',
                      _style(const Color(0xFFFFFFFF), 24, FontWeight.bold),
                    ),
                    _text(
                      _weekdayNames[data.date.weekday - 1].toUpperCase(),
                      _style(const Color(0xFFFFFFFF), 10, FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _text(
                      data.title,
                      _style(ctx.text, 18, FontWeight.bold),
                      maxLines: 1,
                    ),
                    _text(
                      '${_monthNames[data.date.month - 1]} ${data.date.year}',
                      _style(ctx.secondaryText, 14),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: ctx.track),
        const SizedBox(height: 8),
        Expanded(
          child: events.isEmpty
              ? Center(child: _text('No events', _style(ctx.secondaryText, 14)))
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [for (final event in events) _eventRow(ctx, event)],
                ),
        ),
        if (hidden > 0) ...[
          const SizedBox(height: 4),
          _text('+$hidden more events', _style(ctx.secondaryText, 12)),
        ],
      ],
    ),
  );
}

Widget _eventRow(PreviewContext ctx, CalendarEvent event) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(
    children: [
      Container(width: 10, height: 10, color: event.color ?? ctx.accent),
      const SizedBox(width: 10),
      _text(event.time, _style(ctx.secondaryText, 12, FontWeight.w500)),
      const SizedBox(width: 10),
      Flexible(child: _text(event.title, _style(ctx.text, 14), maxLines: 1)),
    ],
  ),
);

// --- gauge -------------------------------------------------------------------

Widget _gauge(PreviewContext ctx, GaugeWidgetData data) => Padding(
  padding: _padding,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (data.title.isNotEmpty) ...[
        _text(data.title, _style(ctx.text, 16, FontWeight.bold)),
        const SizedBox(height: 8),
      ],
      Expanded(
        child: switch (data.gaugeType) {
          GaugeType.radial => _radialGauge(ctx, data),
          GaugeType.dashboard => _dashboardGauge(ctx, data),
        },
      ),
    ],
  ),
);

Widget _radialGauge(PreviewContext ctx, GaugeWidgetData data) {
  // Only the first metric is drawn. The bitmap the plugin rasterises holds one
  // arc, so the rest of the list is not shown at all -- iOS draws one gauge per
  // metric side by side.
  final metric = data.metrics.firstOrNull;
  if (metric == null) return _placeholder(ctx, 'No gauge data');

  final progress = metric.maxValue > 0
      ? (metric.value / metric.maxValue).clamp(0.0, 1.0)
      : 0.0;

  return Center(
    child: AspectRatio(
      aspectRatio: 1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: AndroidGaugePainter(
              progress: progress,
              color: metric.color ?? ctx.accent,
              trackColor: ctx.track,
            ),
          ),
          // The bitmap is 400px wide and drawn with a 56px value and 28px
          // labels, then fitted into the box; the text scales with it.
          FittedBox(
            child: SizedBox(
              width: AndroidGaugePainter.bitmapSize,
              height: AndroidGaugePainter.bitmapSize,
              child: Stack(
                children: [
                  Center(
                    child: _text(
                      _gaugeValueText(metric),
                      _style(ctx.text, 56, FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _text('0', _style(ctx.secondaryText, 28)),
                          _text(
                            _formatNumber(metric.maxValue),
                            _style(ctx.secondaryText, 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _dashboardGauge(PreviewContext ctx, GaugeWidgetData data) {
  if (data.metrics.isEmpty) return _placeholder(ctx, 'No metrics');

  final rows = <List<GaugeMetric>>[
    for (var i = 0; i < data.metrics.length; i += 2)
      data.metrics.sublist(i, (i + 2).clamp(0, data.metrics.length)),
  ];

  return _clippedCenter(
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                for (final (index, metric) in row.indexed) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(child: _metricCard(ctx, metric)),
                ],
                if (row.length == 1) const Spacer(),
              ],
            ),
          ),
      ],
    ),
  );
}

Widget _metricCard(PreviewContext ctx, GaugeMetric metric) => Padding(
  padding: const EdgeInsets.all(8),
  child: Container(
    color: Color(ctx.theme.isDark ? 0xFF2A2A3E : 0xFFF5F5F5),
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _text(
          metric.label,
          _style(ctx.secondaryText, 11, FontWeight.w500),
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        _text(
          _gaugeValueText(metric),
          _style(ctx.text, 20, FontWeight.bold),
          maxLines: 1,
        ),
        const SizedBox(height: 6),
        // The template stacks a full-width bar on the track, so the fill always
        // covers it whatever the fraction says. Drawn as the template draws it.
        Container(
          height: 4,
          width: double.infinity,
          color: metric.color ?? ctx.accent,
        ),
      ],
    ),
  ),
);

/// The day and month names the preview writes.
///
/// The device formats these with `SimpleDateFormat` and its own locale, so a
/// phone set to Turkish shows `PZT` and `Ağustos` where this shows `MON` and
/// `August`. Pulling in a localisation package to match would put a dependency
/// on every app that uses the plugin for the sake of a development-time
/// preview; the layout is what this is here to show.
const List<String> _weekdayNames = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _gaugeValueText(GaugeMetric metric) =>
    _formatNumber(metric.value) + (metric.unit ?? '');

/// Whole numbers lose their decimal point; everything else keeps one digit.
String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
