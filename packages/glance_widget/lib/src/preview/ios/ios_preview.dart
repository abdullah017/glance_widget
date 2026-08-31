import 'package:flutter/widgets.dart';
import 'package:glance_widget/src/preview/glance_widget_size.dart';
import 'package:glance_widget/src/preview/ios/ios_fonts.dart';
import 'package:glance_widget/src/preview/ios/ios_painters.dart';
import 'package:glance_widget/src/preview/preview_context.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Draws [data] the way WidgetKit draws it on iOS.
///
/// Transcribed from the SwiftUI views in
/// `glance_widget_ios/example/ios/GlanceWidgets/`. Every measurement that
/// switches on `WidgetFamily` there switches on [GlanceWidgetSize] here, and
/// the semantic fonts resolve through [IosTextStyle].
///
/// Where this differs from the Android renderer, the two hosts differ. iOS
/// draws its charts and gauges as views rather than bitmaps, puts the calendar
/// day above its weekday instead of beside it, draws one gauge per metric where
/// Android draws only the first, and honours `iconName` in templates Android
/// ignores it in.
Widget buildIosPreview(PreviewContext context, WidgetData data) =>
    switch (data) {
      SimpleWidgetData() => _simple(context, data),
      ProgressWidgetData() => _progress(context, data),
      ListWidgetData() => _list(context, data),
      ImageWidgetData() => _image(context, data),
      ChartWidgetData() => _chart(context, data),
      CalendarWidgetData() => _calendar(context, data),
      GaugeWidgetData() => _gauge(context, data),
    };

/// Centres [child] and clips whatever does not fit.
///
/// A WidgetKit view is given a fixed family size and cannot grow past it.
/// Flutter would rather report an overflow, so the clipping is made explicit --
/// a layout that is too big for its slot is exactly what a developer opens the
/// preview to find out about.
Widget _clippedCenter(Widget child) => ClipRect(
  child: OverflowBox(
    maxHeight: double.infinity,
    alignment: Alignment.center,
    child: child,
  ),
);

Widget _text(String value, TextStyle style, {int? maxLines}) => Text(
  value,
  style: style,
  maxLines: maxLines,
  overflow: maxLines == null ? null : TextOverflow.ellipsis,
);

/// The padding Simple and Progress use: 12 / 16 / 20, wider on the sides for
/// Progress on the two larger families.
EdgeInsets _paddingSimple(GlanceWidgetSize size) => forFamily(
  size,
  small: const EdgeInsets.all(12),
  medium: const EdgeInsets.all(16),
  large: const EdgeInsets.all(20),
);

/// The padding List, Chart, Calendar and Gauge use: 10 / 14 / 16.
EdgeInsets _paddingCompact(GlanceWidgetSize size) => forFamily(
  size,
  small: const EdgeInsets.all(10),
  medium: const EdgeInsets.all(14),
  large: const EdgeInsets.all(16),
);

double _contentSpacing(GlanceWidgetSize size) =>
    forFamily(size, small: 6.0, medium: 8.0, large: 10.0);

// --- simple ------------------------------------------------------------------

Widget _simple(PreviewContext ctx, SimpleWidgetData data) {
  final size = ctx.size;
  // `dynamicSpacing(for:)` is 4% of the shorter side of the widget.
  final spacing = ctx.logicalSize.shortestSide * 0.04;

  return Padding(
    padding: _paddingSimple(size),
    child: _clippedCenter(
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: spacing,
        children: [
          if (data.iconName != null)
            // The template renders an SF Symbol, which only exists on the
            // device. A filled circle at the same point size holds the space it
            // takes without pretending to know the glyph.
            _sfSymbolStandIn(
              ctx.accent,
              forFamily(size, small: 20.0, medium: 28.0, large: 36.0),
            ),
          _text(
            data.title,
            forFamily(
              size,
              small: IosTextStyle.caption,
              medium: IosTextStyle.subheadline,
              large: IosTextStyle.headline,
            ).style(ctx.secondaryText, weight: FontWeight.w500),
            maxLines: 1,
          ),
          _text(
            data.value,
            forFamily(
                  size,
                  small: IosTextStyle.title2,
                  medium: IosTextStyle.largeTitle,
                  // `.system(size: 48, weight: .bold)` -- not a semantic style.
                  large: IosTextStyle.largeTitle,
                )
                .style(ctx.text, weight: FontWeight.bold)
                .copyWith(fontSize: size == GlanceWidgetSize.large ? 48 : null),
            maxLines: 1,
          ),
          if (data.subtitle case final subtitle?)
            _text(
              subtitle,
              forFamily(
                size,
                small: IosTextStyle.caption2,
                medium: IosTextStyle.subheadline,
                large: IosTextStyle.headline,
              ).style(
                data.subtitleColor ?? ctx.secondaryText,
                weight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
        ],
      ),
    ),
  );
}

/// Stands in for an SF Symbol, which is only resolvable on a device.
Widget _sfSymbolStandIn(Color color, double size) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.25),
    shape: BoxShape.circle,
    border: Border.all(color: color, width: 1.5),
  ),
);

// --- progress ----------------------------------------------------------------

Widget _progress(PreviewContext ctx, ProgressWidgetData data) {
  final size = ctx.size;
  final progressColor = data.progressColor ?? ctx.accent;
  final trackColor = data.trackColor ?? ctx.track;
  // `percentageFont(for:)` in the template.
  final percentageStyle = forFamily(
    size,
    small: IosTextStyle.caption,
    medium: IosTextStyle.title3,
    large: IosTextStyle.title,
  ).style(ctx.text, weight: FontWeight.bold);

  return Padding(
    padding: forFamily(
      size,
      small: const EdgeInsets.all(12),
      medium: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      large: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    ),
    child: _clippedCenter(
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          _text(
            data.title,
            forFamily(
              size,
              small: IosTextStyle.caption,
              medium: IosTextStyle.subheadline,
              large: IosTextStyle.headline,
            ).style(ctx.secondaryText, weight: FontWeight.w500),
            maxLines: 1,
          ),
          if (data.progressType == ProgressType.linear)
            Column(
              spacing: 8,
              children: [
                _text('${(data.progress * 100).toInt()}%', percentageStyle),
                SizedBox(
                  height: forFamily(
                    size,
                    small: 8.0,
                    medium: 12.0,
                    large: 16.0,
                  ),
                  width: double.infinity,
                  child: _roundedBar(
                    progress: data.progress,
                    color: progressColor,
                    trackColor: trackColor,
                    radius: 4,
                  ),
                ),
              ],
            )
          else
            SizedBox.square(
              dimension:
                  ctx.logicalSize.shortestSide *
                  forFamily(size, small: 0.45, medium: 0.5, large: 0.35),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: IosProgressRingPainter(
                      progress: data.progress,
                      color: progressColor,
                      trackColor: trackColor,
                      strokeWidth: forFamily(
                        size,
                        small: 6.0,
                        medium: 8.0,
                        large: 10.0,
                      ),
                    ),
                  ),
                  _text('${(data.progress * 100).toInt()}%', percentageStyle),
                ],
              ),
            ),
          if (data.subtitle case final subtitle?)
            _text(
              subtitle,
              forFamily(
                size,
                small: IosTextStyle.caption2,
                medium: IosTextStyle.caption,
                large: IosTextStyle.subheadline,
              ).style(ctx.secondaryText),
              maxLines: 1,
            ),
        ],
      ),
    ),
  );
}

/// A rounded two-tone bar, the shape SwiftUI's stacked `RoundedRectangle`s make.
Widget _roundedBar({
  required double progress,
  required Color color,
  required Color trackColor,
  required double radius,
}) => ClipRRect(
  borderRadius: BorderRadius.circular(radius),
  child: Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: trackColor),
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: ColoredBox(color: color),
      ),
    ],
  ),
);

// --- list --------------------------------------------------------------------

Widget _list(PreviewContext ctx, ListWidgetData data) {
  final size = ctx.size;
  // The template caps how many rows it draws per family, then takes the
  // smaller of that and the app's `maxItems`.
  final cap = forFamily(size, small: 3, medium: 4, large: 8);
  final items = data.items.take(cap.clamp(0, data.maxItems)).toList();

  return Padding(
    padding: _paddingCompact(size),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Row(
          children: [
            _text(
              data.title,
              forFamily(
                size,
                small: IosTextStyle.subheadline,
                medium: IosTextStyle.headline,
                large: IosTextStyle.title3,
              ).style(ctx.text, weight: FontWeight.bold),
              maxLines: 1,
            ),
            const Spacer(),
            _text(
              '${data.items.length}',
              forFamily(
                size,
                small: IosTextStyle.caption2,
                medium: IosTextStyle.subheadline,
                large: IosTextStyle.headline,
              ).style(ctx.secondaryText),
            ),
          ],
        ),
        Container(height: 1, color: ctx.track),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: _text(
                    'No items',
                    IosTextStyle.subheadline.style(ctx.secondaryText),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: forFamily(size, small: 4.0, medium: 6.0, large: 8.0),
                  children: [
                    for (final item in items) _listRow(ctx, data, item),
                  ],
                ),
        ),
      ],
    ),
  );
}

Widget _listRow(PreviewContext ctx, ListWidgetData data, GlanceListItem item) {
  final size = ctx.size;
  final struck = item.checked && data.showCheckboxes;

  return Row(
    spacing: 8,
    children: [
      if (data.showCheckboxes)
        _checkCircle(
          checked: item.checked,
          color: item.checked ? ctx.accent : ctx.secondaryText,
          diameter: forFamily(size, small: 12.0, medium: 17.0, large: 20.0),
        ),
      if (item.iconName != null)
        _sfSymbolStandIn(
          ctx.accent,
          forFamily(size, small: 12.0, medium: 15.0, large: 17.0),
        ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            _text(
              item.text,
              forFamily(
                    size,
                    small: IosTextStyle.caption,
                    medium: IosTextStyle.subheadline,
                    large: IosTextStyle.body,
                  )
                  .style(struck ? ctx.secondaryText : ctx.text)
                  .copyWith(
                    decoration: struck ? TextDecoration.lineThrough : null,
                    decorationColor: ctx.secondaryText,
                  ),
              maxLines: 1,
            ),
            if (item.secondaryText case final secondary?
                when secondary.isNotEmpty)
              _text(
                secondary,
                forFamily(
                  size,
                  small: IosTextStyle.caption2,
                  medium: IosTextStyle.caption,
                  large: IosTextStyle.subheadline,
                ).style(ctx.secondaryText),
                maxLines: 1,
              ),
          ],
        ),
      ),
    ],
  );
}

/// `checkmark.circle.fill` / `circle`, as circles rather than SF Symbols.
Widget _checkCircle({
  required bool checked,
  required Color color,
  required double diameter,
}) => Container(
  width: diameter,
  height: diameter,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: checked ? color : null,
    border: Border.all(color: color, width: 1.5),
  ),
  child: checked
      ? const CustomPaint(painter: _TickPainter(color: Color(0xFFFFFFFF)))
      : null,
);

class _TickPainter extends CustomPainter {
  const _TickPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.27, size.height * 0.52)
        ..lineTo(size.width * 0.44, size.height * 0.69)
        ..lineTo(size.width * 0.74, size.height * 0.33),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) => oldDelegate.color != color;
}

// --- image -------------------------------------------------------------------

Widget _image(PreviewContext ctx, ImageWidgetData data) {
  final size = ctx.size;
  final imageFraction = forFamily(size, small: 0.6, medium: 0.6, large: 0.7);
  final hasSource = data.imageUrl != null || data.imageBase64 != null;

  return ClipRRect(
    borderRadius: BorderRadius.circular(ctx.cornerRadius),
    child: Column(
      children: [
        // The picture fills the top of the widget edge to edge -- the iOS
        // template has no outer padding, only padding around the caption.
        SizedBox(
          height: ctx.logicalSize.height * imageFraction,
          width: double.infinity,
          child: ColoredBox(
            color: ctx.secondaryText.withValues(alpha: 0.1),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  _sfSymbolStandIn(
                    ctx.secondaryText.withValues(alpha: 0.4),
                    forFamily(size, small: 20.0, medium: 22.0, large: 28.0),
                  ),
                  if (hasSource)
                    _text(
                      'Image',
                      IosTextStyle.caption2.style(
                        ctx.secondaryText.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: forFamily(
              size,
              small: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              medium: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              large: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                _text(
                  data.title,
                  forFamily(
                    size,
                    small: IosTextStyle.caption,
                    medium: IosTextStyle.subheadline,
                    large: IosTextStyle.headline,
                  ).style(ctx.text, weight: FontWeight.bold),
                  maxLines: 1,
                ),
                if (data.subtitle case final subtitle? when subtitle.isNotEmpty)
                  _text(
                    subtitle,
                    forFamily(
                      size,
                      small: IosTextStyle.caption2,
                      medium: IosTextStyle.caption,
                      large: IosTextStyle.subheadline,
                    ).style(ctx.secondaryText),
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// --- chart -------------------------------------------------------------------

Widget _chart(PreviewContext ctx, ChartWidgetData data) {
  final size = ctx.size;
  final sparkline = data.chartType == ChartType.sparkline;
  final header = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 2,
    children: [
      _text(
        data.title,
        forFamily(
          size,
          small: IosTextStyle.caption,
          medium: IosTextStyle.subheadline,
          large: IosTextStyle.headline,
        ).style(ctx.text, weight: FontWeight.bold),
        maxLines: 1,
      ),
      if (data.subtitle case final subtitle? when subtitle.isNotEmpty)
        _text(
          subtitle,
          forFamily(
            size,
            small: IosTextStyle.caption2,
            medium: IosTextStyle.caption,
            large: IosTextStyle.subheadline,
          ).style(ctx.secondaryText),
          maxLines: 1,
        ),
    ],
  );

  return Padding(
    padding: _paddingCompact(size),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: _contentSpacing(size),
      children: [
        // A sparkline puts its label under the line instead of over it.
        if (!sparkline) header,
        Expanded(child: _chartBody(ctx, data, sparkline: sparkline)),
        if (sparkline)
          Row(
            children: [
              _text(
                data.title,
                forFamily(
                  size,
                  small: IosTextStyle.caption,
                  medium: IosTextStyle.subheadline,
                  large: IosTextStyle.headline,
                ).style(ctx.text, weight: FontWeight.bold),
                maxLines: 1,
              ),
              const Spacer(),
              if (data.subtitle case final subtitle? when subtitle.isNotEmpty)
                _text(
                  subtitle,
                  forFamily(
                    size,
                    small: IosTextStyle.caption2,
                    medium: IosTextStyle.caption,
                    large: IosTextStyle.subheadline,
                  ).style(ctx.secondaryText),
                  maxLines: 1,
                ),
            ],
          ),
      ],
    ),
  );
}

Widget _chartBody(
  PreviewContext ctx,
  ChartWidgetData data, {
  required bool sparkline,
}) {
  final size = ctx.size;
  if (data.dataPoints.isEmpty) {
    return Center(
      child: _text(
        'No data',
        forFamily(
          size,
          small: IosTextStyle.caption2,
          medium: IosTextStyle.caption,
          large: IosTextStyle.subheadline,
        ).style(ctx.secondaryText),
      ),
    );
  }

  final color = data.color ?? ctx.accent;
  if (data.chartType == ChartType.bar) {
    // Bars are measured against the maximum alone, so the shortest bar is not
    // flattened to nothing the way a min-to-max scale would flatten it.
    final maxValue = data.dataPoints.reduce((a, b) => a > b ? a : b);
    final spacing = forFamily(size, small: 2.0, medium: 3.0, large: 4.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: spacing,
      children: [
        for (final value in data.dataPoints)
          Expanded(
            child: FractionallySizedBox(
              heightFactor: maxValue > 0
                  ? (value / maxValue).clamp(0.0, 1.0)
                  : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(
                    forFamily(size, small: 2.0, medium: 3.0, large: 4.0),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  return CustomPaint(
    size: Size.infinite,
    painter: IosLineChartPainter(
      dataPoints: data.dataPoints,
      color: color,
      strokeWidth: forFamily(size, small: 1.5, medium: 2.0, large: 2.5),
      dotSize: forFamily(size, small: 4.0, medium: 5.0, large: 6.0),
      sparkline: sparkline,
    ),
  );
}

// --- calendar ----------------------------------------------------------------

Widget _calendar(PreviewContext ctx, CalendarWidgetData data) {
  final size = ctx.size;
  final cap = forFamily(size, small: 2, medium: 3, large: 8);
  final events = data.events.take(cap.clamp(0, data.maxEvents)).toList();

  return Padding(
    padding: _paddingCompact(size),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: _contentSpacing(size),
      children: [
        Row(
          spacing: 10,
          children: [
            // iOS stacks the weekday over the day number and tints only the
            // weekday; Android puts both inside an accent-filled square.
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                _text(
                  weekdayName(data.date).toUpperCase(),
                  forFamily(
                    size,
                    small: IosTextStyle.caption2,
                    medium: IosTextStyle.caption,
                    large: IosTextStyle.subheadline,
                  ).style(ctx.accent, weight: FontWeight.w500),
                ),
                _text(
                  '${data.date.day}',
                  forFamily(
                    size,
                    small: IosTextStyle.title3,
                    medium: IosTextStyle.title2,
                    large: IosTextStyle.title,
                  ).style(ctx.text, weight: FontWeight.bold),
                ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  _text(
                    data.title,
                    forFamily(
                      size,
                      small: IosTextStyle.subheadline,
                      medium: IosTextStyle.headline,
                      large: IosTextStyle.title3,
                    ).style(ctx.text, weight: FontWeight.bold),
                    maxLines: 1,
                  ),
                  _text(
                    '${monthName(data.date)} ${data.date.year}',
                    forFamily(
                      size,
                      small: IosTextStyle.caption2,
                      medium: IosTextStyle.caption,
                      large: IosTextStyle.subheadline,
                    ).style(ctx.secondaryText),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(height: 1, color: ctx.track),
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: _text(
                    'No events',
                    IosTextStyle.subheadline.style(ctx.secondaryText),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: forFamily(size, small: 4.0, medium: 6.0, large: 8.0),
                  children: [for (final event in events) _eventRow(ctx, event)],
                ),
        ),
      ],
    ),
  );
}

Widget _eventRow(PreviewContext ctx, CalendarEvent event) {
  final size = ctx.size;
  final dot = forFamily(size, small: 6.0, medium: 8.0, large: 10.0);

  return Row(
    spacing: 8,
    children: [
      Container(
        width: dot,
        height: dot,
        decoration: BoxDecoration(
          color: event.color ?? ctx.accent,
          shape: BoxShape.circle,
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 1,
          children: [
            _text(
              event.title,
              forFamily(
                size,
                small: IosTextStyle.caption,
                medium: IosTextStyle.subheadline,
                large: IosTextStyle.body,
              ).style(ctx.text),
              maxLines: 1,
            ),
            _text(
              event.isAllDay ? 'All day' : event.time,
              forFamily(
                size,
                small: IosTextStyle.caption2,
                medium: IosTextStyle.caption,
                large: IosTextStyle.subheadline,
              ).style(ctx.secondaryText),
              maxLines: 1,
            ),
          ],
        ),
      ),
    ],
  );
}

// --- gauge -------------------------------------------------------------------

Widget _gauge(PreviewContext ctx, GaugeWidgetData data) {
  final size = ctx.size;

  return Padding(
    padding: _paddingCompact(size),
    child: Column(
      spacing: _contentSpacing(size),
      children: [
        _text(
          data.title,
          forFamily(
            size,
            small: IosTextStyle.caption,
            medium: IosTextStyle.subheadline,
            large: IosTextStyle.headline,
          ).style(ctx.text, weight: FontWeight.bold),
          maxLines: 1,
        ),
        Expanded(
          child: data.metrics.isEmpty
              ? Center(
                  child: _text(
                    'No metrics',
                    forFamily(
                      size,
                      small: IosTextStyle.caption2,
                      medium: IosTextStyle.caption,
                      large: IosTextStyle.subheadline,
                    ).style(ctx.secondaryText),
                  ),
                )
              : switch (data.gaugeType) {
                  GaugeType.radial => _radial(ctx, data),
                  GaugeType.dashboard => _dashboard(ctx, data),
                },
        ),
      ],
    ),
  );
}

Widget _radial(PreviewContext ctx, GaugeWidgetData data) {
  final size = ctx.size;
  // iOS draws every metric, side by side -- Android draws only the first.
  final metrics = data.metrics;

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: forFamily(size, small: 8.0, medium: 12.0, large: 16.0),
    children: [
      for (final metric in metrics)
        Flexible(child: _radialGauge(ctx, metric, metrics.length)),
    ],
  );
}

Widget _radialGauge(PreviewContext ctx, GaugeMetric metric, int count) {
  final size = ctx.size;
  final progress = metric.maxValue > 0
      ? (metric.value / metric.maxValue).clamp(0.0, 1.0)
      : 0.0;
  final arcWidth = forFamily(size, small: 6.0, medium: 7.0, large: 8.0);

  return Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      Flexible(
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: IosGaugeArcPainter(
                  progress: progress,
                  color: metric.color ?? ctx.accent,
                  trackColor: ctx.track,
                  strokeWidth: arcWidth,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _text(
                    formatNumber(metric.value),
                    forFamily(
                      size,
                      small: IosTextStyle.title3,
                      medium: IosTextStyle.title3,
                      large: IosTextStyle.title2,
                    ).style(ctx.text, weight: FontWeight.bold),
                  ),
                  if (metric.unit case final unit? when unit.isNotEmpty)
                    _text(
                      unit,
                      forFamily(
                        size,
                        small: IosTextStyle.caption2,
                        medium: IosTextStyle.caption,
                        large: IosTextStyle.subheadline,
                      ).style(ctx.secondaryText),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      _text(
        metric.label,
        forFamily(
          size,
          small: IosTextStyle.caption2,
          medium: IosTextStyle.caption,
          large: IosTextStyle.subheadline,
        ).style(ctx.secondaryText),
        maxLines: 1,
      ),
    ],
  );
}

Widget _dashboard(PreviewContext ctx, GaugeWidgetData data) {
  final size = ctx.size;
  final spacing = forFamily(size, small: 6.0, medium: 8.0, large: 10.0);

  // A small widget stacks the cards; the other two lay them out two to a row.
  if (size == GlanceWidgetSize.small) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: spacing,
      children: [for (final metric in data.metrics) _card(ctx, metric)],
    );
  }

  final rows = <List<GaugeMetric>>[
    for (var i = 0; i < data.metrics.length; i += 2)
      data.metrics.sublist(i, (i + 2).clamp(0, data.metrics.length)),
  ];

  return Column(
    mainAxisSize: MainAxisSize.min,
    spacing: spacing,
    children: [
      for (final row in rows)
        Row(
          spacing: spacing,
          children: [
            for (final metric in row) Expanded(child: _card(ctx, metric)),
          ],
        ),
    ],
  );
}

Widget _card(PreviewContext ctx, GaugeMetric metric) {
  final size = ctx.size;
  final progress = metric.maxValue > 0
      ? (metric.value / metric.maxValue).clamp(0.0, 1.0)
      : 0.0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      Row(
        children: [
          Flexible(
            child: _text(
              metric.label,
              forFamily(
                size,
                small: IosTextStyle.caption2,
                medium: IosTextStyle.caption,
                large: IosTextStyle.subheadline,
              ).style(ctx.secondaryText),
              maxLines: 1,
            ),
          ),
          const Spacer(),
          _text(
            formatNumber(metric.value),
            forFamily(
              size,
              small: IosTextStyle.caption,
              medium: IosTextStyle.subheadline,
              large: IosTextStyle.body,
            ).style(ctx.text, weight: FontWeight.w600),
          ),
          if (metric.unit case final unit? when unit.isNotEmpty) ...[
            const SizedBox(width: 2),
            _text(
              unit,
              forFamily(
                size,
                small: IosTextStyle.caption2,
                medium: IosTextStyle.caption,
                large: IosTextStyle.subheadline,
              ).style(ctx.secondaryText),
            ),
          ],
        ],
      ),
      SizedBox(
        height: forFamily(size, small: 4.0, medium: 6.0, large: 8.0),
        width: double.infinity,
        child: _roundedBar(
          progress: progress,
          color: metric.color ?? ctx.accent,
          trackColor: ctx.secondaryText.withValues(alpha: 0.2),
          radius: 3,
        ),
      ),
    ],
  );
}

/// Whole numbers lose their decimal point; everything else keeps one digit.
///
/// `formattedValue(_:)` in `GaugeWidget.swift`.
String formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

/// The abbreviated weekday name the preview writes.
///
/// The device formats this with `DateFormatter` and its own locale.
String weekdayName(DateTime date) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

/// The full month name the preview writes, under the same caveat.
String monthName(DateTime date) => const [
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
][date.month - 1];
