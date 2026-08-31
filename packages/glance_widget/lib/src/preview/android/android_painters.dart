import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart';

/// Redraws the chart bitmap Android builds in `GlanceWidgetManager`.
///
/// The Android chart template does not lay out a chart at all: the plugin
/// rasterises one into a 600x300 bitmap with `android.graphics.Canvas` and the
/// template stretches it with `ContentScale.FillBounds`. The stretch is why
/// this painter draws into that same 600x300 space and scales the result --
/// drawing at the widget's real size would give crisper lines than the device
/// ever shows.
class AndroidChartPainter extends CustomPainter {
  /// Draws [dataPoints] as [chartType] in [color], over [isDark] grid lines.
  const AndroidChartPainter({
    required this.dataPoints,
    required this.chartType,
    required this.color,
    required this.isDark,
  });

  /// The values to plot.
  final List<double> dataPoints;

  /// Which of the three shapes to draw.
  final ChartType chartType;

  /// The line, bar and dot colour.
  final Color color;

  /// Whether the grid lines are drawn light-on-dark.
  final bool isDark;

  /// The bitmap size the plugin rasterises at.
  static const Size bitmapSize = Size(600, 300);

  static const double _padding = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    canvas.scale(
      size.width / bitmapSize.width,
      size.height / bitmapSize.height,
    );

    final chartWidth = bitmapSize.width - _padding * 2;
    final chartHeight = bitmapSize.height - _padding * 2;
    final minValue = dataPoints.reduce(math.min);
    final maxValue = dataPoints.reduce(math.max);
    final range = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;

    final grid = Paint()
      ..color = Color(isDark ? 0x33FFFFFF : 0x33000000)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i <= 4; i++) {
      final y = _padding + chartHeight * i / 4;
      canvas.drawLine(
        Offset(_padding, y),
        Offset(bitmapSize.width - _padding, y),
        grid,
      );
    }

    double xAt(int index) =>
        _padding + (index / math.max(dataPoints.length - 1, 1)) * chartWidth;
    double yAt(double value) =>
        _padding + chartHeight - ((value - minValue) / range) * chartHeight;

    switch (chartType) {
      case ChartType.bar:
        final slot = chartWidth / dataPoints.length;
        final barWidth = slot * 0.7;
        final gap = slot * 0.3;
        final paint = Paint()
          ..color = color.withValues(alpha: 200 / 255)
          ..style = PaintingStyle.fill;
        for (var i = 0; i < dataPoints.length; i++) {
          final top = yAt(dataPoints[i]);
          final left = _padding + i * (barWidth + gap);
          canvas.drawRect(
            Rect.fromLTRB(left, top, left + barWidth, _padding + chartHeight),
            paint,
          );
        }
      case ChartType.sparkline:
        final line = Path();
        final fill = Path();
        for (var i = 0; i < dataPoints.length; i++) {
          final point = Offset(xAt(i), yAt(dataPoints[i]));
          if (i == 0) {
            line.moveTo(point.dx, point.dy);
            fill
              ..moveTo(point.dx, _padding + chartHeight)
              ..lineTo(point.dx, point.dy);
          } else {
            line.lineTo(point.dx, point.dy);
            fill.lineTo(point.dx, point.dy);
          }
        }
        fill
          ..lineTo(_padding + chartWidth, _padding + chartHeight)
          ..close();
        canvas.drawPath(
          fill,
          Paint()..color = color.withValues(alpha: 40 / 255),
        );
        canvas.drawPath(
          line,
          Paint()
            ..color = color
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      case ChartType.line:
        final line = Path();
        for (var i = 0; i < dataPoints.length; i++) {
          final point = Offset(xAt(i), yAt(dataPoints[i]));
          if (i == 0) {
            line.moveTo(point.dx, point.dy);
          } else {
            line.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(
          line,
          Paint()
            ..color = color
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
        final dot = Paint()..color = color;
        for (var i = 0; i < dataPoints.length; i++) {
          canvas.drawCircle(Offset(xAt(i), yAt(dataPoints[i])), 5, dot);
        }
    }
  }

  @override
  bool shouldRepaint(AndroidChartPainter oldDelegate) =>
      !listEquals(oldDelegate.dataPoints, dataPoints) ||
      oldDelegate.chartType != chartType ||
      oldDelegate.color != color ||
      oldDelegate.isDark != isDark;
}

/// Redraws the radial gauge bitmap Android builds in `GlanceWidgetManager`.
///
/// Like the chart, this is a rasterised bitmap -- 400x400, drawn with a 28px
/// stroke and a 270 degree sweep starting at 135 degrees -- so the painter works
/// in that space and scales. The template fits rather than stretches it, which
/// is why the caller gives this painter a square.
class AndroidGaugePainter extends CustomPainter {
  /// Draws an arc [progress] of the way round, in [color] over [trackColor].
  const AndroidGaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  /// How far round the arc runs, from 0 to 1.
  final double progress;

  /// The filled arc's colour.
  final Color color;

  /// The unfilled arc's colour.
  final Color trackColor;

  /// The bitmap size the plugin rasterises at.
  static const double bitmapSize = 400;

  static const double _strokeWidth = 28;
  static const double _startAngle = 135 * math.pi / 180;
  static const double _sweepAngle = 270 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / bitmapSize, size.height / bitmapSize);

    const padding = _strokeWidth / 2 + 20;
    const rect = Rect.fromLTRB(
      padding,
      padding,
      bitmapSize - padding,
      bitmapSize - padding,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawArc(
        rect,
        _startAngle,
        _sweepAngle,
        false,
        stroke..color = trackColor,
      )
      ..drawArc(
        rect,
        _startAngle,
        _sweepAngle * progress.clamp(0.0, 1.0),
        false,
        stroke..color = color,
      );
  }

  @override
  bool shouldRepaint(AndroidGaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
