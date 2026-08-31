import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Draws the line and sparkline charts the iOS template lays out.
///
/// Unlike Android, nothing is rasterised here: `ChartWidget.swift` builds a
/// SwiftUI `Path` at the widget's real size, so the line runs edge to edge with
/// no padding and the dots are only drawn for twelve points or fewer.
class IosLineChartPainter extends CustomPainter {
  /// Draws [dataPoints] in [color]; [sparkline] drops the fill and the dots.
  const IosLineChartPainter({
    required this.dataPoints,
    required this.color,
    required this.strokeWidth,
    required this.dotSize,
    required this.sparkline,
  });

  /// The values to plot.
  final List<double> dataPoints;

  /// The line, fill and dot colour.
  final Color color;

  /// The line's width, which the template scales with the family.
  final double strokeWidth;

  /// The diameter of a data point dot.
  final double dotSize;

  /// Whether to draw the bare line, without the gradient or the dots.
  final bool sparkline;

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final minValue = dataPoints.reduce(math.min);
    final maxValue = dataPoints.reduce(math.max);
    final range = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;
    final stepX = size.width / (dataPoints.length - 1);
    double yAt(double value) =>
        size.height - ((value - minValue) / range) * size.height;

    if (!sparkline) {
      final fill = Path()..moveTo(0, size.height);
      for (var i = 0; i < dataPoints.length; i++) {
        fill.lineTo(i * stepX, yAt(dataPoints[i]));
      }
      fill
        ..lineTo((dataPoints.length - 1) * stepX, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.05),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    final line = Path()..moveTo(0, yAt(dataPoints.first));
    for (var i = 1; i < dataPoints.length; i++) {
      line.lineTo(i * stepX, yAt(dataPoints[i]));
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // The template stops drawing dots past twelve points, where they would run
    // into each other.
    if (!sparkline && dataPoints.length <= 12) {
      final dot = Paint()..color = color;
      for (var i = 0; i < dataPoints.length; i++) {
        canvas.drawCircle(
          Offset(i * stepX, yAt(dataPoints[i])),
          dotSize / 2,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(IosLineChartPainter oldDelegate) =>
      !listEquals(oldDelegate.dataPoints, dataPoints) ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dotSize != dotSize ||
      oldDelegate.sparkline != sparkline;
}

/// Draws the arc `GaugeWidget.swift` strokes for one metric.
///
/// A 270 degree sweep from 135 degrees, at the family's line width, sitting
/// inside the square it is given rather than in a fixed bitmap.
class IosGaugeArcPainter extends CustomPainter {
  /// Draws [progress] of the sweep in [color] over [trackColor].
  const IosGaugeArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  /// How far round the arc runs, from 0 to 1.
  final double progress;

  /// The filled arc's colour.
  final Color color;

  /// The unfilled arc's colour.
  final Color trackColor;

  /// The stroke width the family asks for.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - strokeWidth) / 2,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    const start = 135 * math.pi / 180;
    const sweep = 270 * math.pi / 180;

    canvas
      ..drawArc(rect, start, sweep, false, stroke..color = trackColor)
      ..drawArc(
        rect,
        start,
        sweep * progress.clamp(0.0, 1.0),
        false,
        stroke..color = color,
      );
  }

  @override
  bool shouldRepaint(IosGaugeArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// The ring `ProgressWidget.swift` draws for a circular progress widget.
///
/// A full circle track with the fill trimmed to the fraction, starting at the
/// top -- SwiftUI's `.trim(from:to:)` rotated by -90 degrees.
class IosProgressRingPainter extends CustomPainter {
  /// Draws [progress] of a ring in [color] over [trackColor].
  const IosProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  /// How far round the ring runs, from 0 to 1.
  final double progress;

  /// The filled ring's colour.
  final Color color;

  /// The unfilled ring's colour.
  final Color trackColor;

  /// The stroke width the family asks for.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - strokeWidth) / 2,
    );
    canvas
      ..drawCircle(
        size.center(Offset.zero),
        (size.shortestSide - strokeWidth) / 2,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      )
      ..drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(IosProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
