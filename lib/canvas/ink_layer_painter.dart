import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

class InkLayerPainter extends CustomPainter {
  InkLayerPainter({
    required this.completedStrokes,
    this.activeStroke,
    required this.theme,
    this.showHeatmap = false,
    this.currentScale = 1.0,
    super.repaint,
  });

  final List<Stroke> completedStrokes;
  final Stroke? activeStroke;
  final AppThemeTokens theme;
  final bool showHeatmap;
  final double currentScale;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw all completed strokes
    for (final stroke in completedStrokes) {
      _paintStroke(canvas, stroke);
    }

    // 2. Draw live active stroke
    if (activeStroke != null && !activeStroke!.isEmpty) {
      _paintStroke(canvas, activeStroke!);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final authorScale = stroke.authoringScale > 0.0
        ? stroke.authoringScale
        : 1.0;
    final rawBaseWidth = (stroke.lineWeight.baseWidth *
            stroke.brushStyle.widthMultiplier) /
        authorScale;

    // Macro stroke dampening: if zoomed in significantly beyond authoring
    // scale, prevent strokes from ballooning into screen-blocking bars.
    final zoomRatio = currentScale / authorScale;
    final scaleFactor = zoomRatio > 6.0
        ? (6.0 + 2.0 * math.log(1.0 + zoomRatio - 6.0)) / zoomRatio
        : 1.0;
    final baseWidth = rawBaseWidth * scaleFactor;

    final strokeColor = stroke.color.withOpacity(
      (stroke.color.opacity * stroke.brushStyle.opacityMultiplier).clamp(
        0.0,
        1.0,
      ),
    );

    // If heatmapped (e.g. from ghosting analysis)
    if (showHeatmap &&
        stroke.segmentColors != null &&
        stroke.segmentColors!.length >= stroke.points.length) {
      _paintHeatmappedStroke(canvas, stroke);
      return;
    }

    // If dashed (hidden geometry line)
    if (stroke.lineWeight.isDashed) {
      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = baseWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        stroke.toDashedPath(scaleWithAuthoring: true),
        paint,
      );
      return;
    }

    // High performance smooth path rendering
    if (stroke.points.length < 3) {
      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = baseWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        stroke.toSmoothedPath(scaleWithAuthoring: true),
        paint,
      );
      return;
    }

    // Draw variable-width segments based on stylus pressure
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];

      // Scale width between 0.6x and 1.4x based on pressure
      final avgPressure = (p1.pressure + p2.pressure) / 2.0;
      final dynamicWidth = baseWidth * (0.6 + avgPressure * 0.8);

      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = dynamicWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1.position, p2.position, paint);
    }
  }

  void _paintHeatmappedStroke(Canvas canvas, Stroke stroke) {
    final colors = stroke.segmentColors!;
    final authorScale = stroke.authoringScale > 0.0
        ? stroke.authoringScale
        : 1.0;
    final strokeWidth = (stroke.lineWeight.baseWidth * 1.2) / authorScale;

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      final segmentColor = colors[i];

      final paint = Paint()
        ..color = segmentColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1.position, p2.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant InkLayerPainter oldDelegate) {
    return true; // Repaint during live drawing
  }
}
