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
    Matrix4? transform,
    double? currentScale,
    super.repaint,
  }) : transform = transform ??
            (currentScale != null
                ? (Matrix4.identity()..scale(currentScale, currentScale))
                : Matrix4.identity());

  final List<Stroke> completedStrokes;
  final Stroke? activeStroke;
  final AppThemeTokens theme;
  final bool showHeatmap;
  final Matrix4 transform;

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

    final scale = transform.getMaxScaleOnAxis().clamp(0.0001, 100000.0);
    final authorScale = stroke.authoringScale > 0.0
        ? stroke.authoringScale
        : 1.0;
    final zoomRatio = scale / authorScale;
    final scaleFactor = zoomRatio > 6.0
        ? (6.0 + 2.0 * math.log(1.0 + zoomRatio - 6.0)) / zoomRatio
        : 1.0;

    double avgPressure = 0.5;
    double totalPressure = 0.0;
    for (final pt in stroke.points) {
      totalPressure += pt.pressure;
    }
    avgPressure = (totalPressure / stroke.points.length).clamp(0.1, 1.0);

    final baseScreenWidth = stroke.lineWeight.baseWidth *
        stroke.brushStyle.widthMultiplier *
        zoomRatio *
        scaleFactor;
    final screenWidth =
        (baseScreenWidth * (0.6 + avgPressure * 0.8)).clamp(0.2, 300.0);

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
      _paintHeatmappedStroke(canvas, stroke, screenWidth);
      return;
    }

    // Convert points to screen coordinates via 64-bit CPU transform
    final screenPoints = <Offset>[];
    for (final pt in stroke.points) {
      screenPoints.add(MatrixUtils.transformPoint(transform, pt.position));
    }

    if (screenPoints.length == 1) {
      final p0 = screenPoints.first;
      final dotPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p0, screenWidth / 2.0, dotPaint);
      return;
    }

    // Continuous midpoint quadratic Bezier path in screen space
    final path = Path();
    path.moveTo(screenPoints[0].dx, screenPoints[0].dy);

    if (screenPoints.length == 2) {
      path.lineTo(screenPoints[1].dx, screenPoints[1].dy);
    } else {
      for (int i = 0; i < screenPoints.length - 1; i++) {
        final p0 = screenPoints[i];
        final p1 = screenPoints[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2.0, (p0.dy + p1.dy) / 2.0);
        if (i == 0) {
          path.lineTo(mid.dx, mid.dy);
        } else {
          path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
        }
      }
      path.lineTo(screenPoints.last.dx, screenPoints.last.dy);
    }

    // If dashed (hidden geometry line)
    if (stroke.lineWeight.isDashed) {
      final dashed = _toDashedPath(path, dashLength: 8.0, dashSpace: 5.0);
      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = screenWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(dashed, paint);
      return;
    }

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = screenWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  Path _toDashedPath(
    Path source, {
    double dashLength = 8.0,
    double dashSpace = 5.0,
  }) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : dashSpace;
        if (draw) {
          dashed.addPath(
            metric.extractPath(
              distance,
              (distance + length).clamp(0.0, metric.length),
            ),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dashed;
  }

  void _paintHeatmappedStroke(
    Canvas canvas,
    Stroke stroke,
    double screenWidth,
  ) {
    final colors = stroke.segmentColors!;
    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 =
          MatrixUtils.transformPoint(transform, stroke.points[i].position);
      final p2 = MatrixUtils.transformPoint(
        transform,
        stroke.points[i + 1].position,
      );
      final segmentColor = colors[i];

      final paint = Paint()
        ..color = segmentColor
        ..strokeWidth = screenWidth * 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant InkLayerPainter oldDelegate) {
    return true; // Repaint during live drawing and camera motion
  }
}
