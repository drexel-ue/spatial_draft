import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

class CanvasGridPainter extends CustomPainter {
  CanvasGridPainter({
    required this.theme,
    required this.gridStyle,
    required this.gridType,
    required this.transform,
    super.repaint,
  });

  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final Matrix4 transform;

  double get _scale => transform.getMaxScaleOnAxis().clamp(0.0001, 100000.0);
  double get _tx => transform.storage[12];
  double get _ty => transform.storage[13];

  @override
  void paint(Canvas canvas, Size size) {
    if (gridStyle == GridStyle.none) return;

    final majorPaint = Paint()
      ..color = theme.gridLineMajor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final minorPaint = Paint()
      ..color = theme.gridLineMinor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    switch (gridType) {
      case GridType.squareMetric:
        _paintSquareGrid(canvas, size, majorPaint, minorPaint);
        break;
      case GridType.isometric:
        _paintIsometricGrid(canvas, size, majorPaint, minorPaint);
        break;
      case GridType.perspective:
        _paintPerspectiveGrid(canvas, size, majorPaint, minorPaint);
        break;
    }
  }

  void _paintSquareGrid(
    Canvas canvas,
    Size size,
    Paint majorPaint,
    Paint minorPaint,
  ) {
    final scale = _scale;
    final tx = _tx;
    final ty = _ty;

    // Octave subdivision: screen spacing is always between 32px and 64px
    final octave = (math.log(scale) / math.ln2).floor();
    final worldSpacing = 32.0 / math.pow(2.0, octave);
    final screenSpacing = worldSpacing * scale;
    const majorInterval = 4;

    // Screen offsets derived modulo screenSpacing
    final startX = ((tx % screenSpacing) + screenSpacing) % screenSpacing;
    final startY = ((ty % screenSpacing) + screenSpacing) % screenSpacing;

    if (gridStyle == GridStyle.dotted) {
      final dotPaint = Paint()..style = PaintingStyle.fill;
      for (double x = startX; x <= size.width; x += screenSpacing) {
        final worldX = (x - tx) / scale;
        final kx = (worldX / worldSpacing).round();
        for (double y = startY; y <= size.height; y += screenSpacing) {
          final worldY = (y - ty) / scale;
          final ky = (worldY / worldSpacing).round();
          final isMajor = (kx % majorInterval == 0) &&
              (ky % majorInterval == 0);
          dotPaint.color =
              isMajor ? theme.gridLineMajor : theme.gridLineMinor;
          final radius = isMajor ? 2.0 : 1.2;
          canvas.drawCircle(Offset(x, y), radius, dotPaint);
        }
      }
      return;
    }

    // Vertical grid lines in screen space
    for (double x = startX; x <= size.width; x += screenSpacing) {
      final worldX = (x - tx) / scale;
      final k = (worldX / worldSpacing).round();
      final isMajor = k % majorInterval == 0;
      final paint = isMajor ? majorPaint : minorPaint;
      final p1 = Offset(x, 0);
      final p2 = Offset(x, size.height);

      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }

    // Horizontal grid lines in screen space
    for (double y = startY; y <= size.height; y += screenSpacing) {
      final worldY = (y - ty) / scale;
      final k = (worldY / worldSpacing).round();
      final isMajor = k % majorInterval == 0;
      final paint = isMajor ? majorPaint : minorPaint;
      final p1 = Offset(0, y);
      final p2 = Offset(size.width, y);

      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  void _paintIsometricGrid(
    Canvas canvas,
    Size size,
    Paint majorPaint,
    Paint minorPaint,
  ) {
    final scale = _scale;
    final tx = _tx;
    final ty = _ty;

    final octave = (math.log(scale) / math.ln2).floor();
    final worldSpacing = 40.0 / math.pow(2.0, octave);
    final screenSpacing = worldSpacing * scale;
    const angle = 30.0 * math.pi / 180.0;
    final tanAngle = math.tan(angle);

    // 1. Vertical lines in screen space
    final stepX = screenSpacing * 1.5;
    final startX = ((tx % stepX) + stepX) % stepX;
    for (double x = startX; x <= size.width; x += stepX) {
      final p1 = Offset(x, 0);
      final p2 = Offset(x, size.height);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint);
      } else if (gridStyle == GridStyle.dotted) {
        _drawDottedLine(canvas, p1, p2, minorPaint);
      } else {
        canvas.drawLine(p1, p2, minorPaint);
      }
    }

    // 2. 30-degree upward diagonal lines
    final interceptStep = screenSpacing;
    final c0Up = ty - tanAngle * tx;
    final startCUp =
        ((c0Up % interceptStep) + interceptStep) % interceptStep;
    final minCUp = -tanAngle * size.width;
    final maxCUp = size.height;

    final countUpStart = ((minCUp - startCUp) / interceptStep).floor();
    final countUpEnd = ((maxCUp - startCUp) / interceptStep).ceil();

    for (int i = countUpStart; i <= countUpEnd; i++) {
      final c = startCUp + i * interceptStep;
      final p1 = Offset(0, c);
      final p2 = Offset(size.width, c + size.width * tanAngle);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint);
      } else if (gridStyle == GridStyle.dotted) {
        _drawDottedLine(canvas, p1, p2, minorPaint);
      } else {
        canvas.drawLine(p1, p2, minorPaint);
      }
    }

    // 3. 30-degree downward diagonal lines
    final c0Down = ty + tanAngle * tx;
    final startCDown =
        ((c0Down % interceptStep) + interceptStep) % interceptStep;
    const minCDown = 0.0;
    final maxCDown = size.height + tanAngle * size.width;

    final countDownStart =
        ((minCDown - startCDown) / interceptStep).floor();
    final countDownEnd =
        ((maxCDown - startCDown) / interceptStep).ceil();

    for (int i = countDownStart; i <= countDownEnd; i++) {
      final c = startCDown + i * interceptStep;
      final p1 = Offset(0, c);
      final p2 = Offset(size.width, c - size.width * tanAngle);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint);
      } else if (gridStyle == GridStyle.dotted) {
        _drawDottedLine(canvas, p1, p2, minorPaint);
      } else {
        canvas.drawLine(p1, p2, minorPaint);
      }
    }
  }

  void _paintPerspectiveGrid(
    Canvas canvas,
    Size size,
    Paint majorPaint,
    Paint minorPaint,
  ) {
    final scale = _scale;
    final tx = _tx;
    final ty = _ty;

    final horizonY = ty + 4000.0 * 0.42 * scale;
    final vpX = tx + 4000.0 * 0.5 * scale;
    final vp = Offset(vpX, horizonY);

    // Horizon line
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      majorPaint,
    );

    // Perspective rays originating from vanishing point
    const rayCount = 18;
    for (int i = 0; i <= rayCount; i++) {
      final targetX = (size.width / rayCount) * i;
      final targetBottom = Offset(targetX, size.height);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, vp, targetBottom, minorPaint);
      } else if (gridStyle == GridStyle.dotted) {
        _drawDottedLine(canvas, vp, targetBottom, minorPaint);
      } else {
        canvas.drawLine(vp, targetBottom, minorPaint);
      }
    }

    // Ground plane horizontal perspective lines
    for (double depth = 1.0; depth < 10.0; depth += 1.0) {
      final y =
          horizonY + (size.height - horizonY) * (depth / 10.0) * (depth / 10.0);
      final p1 = Offset(0, y);
      final p2 = Offset(size.width, y);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint);
      } else {
        canvas.drawLine(p1, p2, minorPaint);
      }
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
  ) {
    const dashLength = 8.0;
    const dashSpace = 6.0;
    final totalDist = (p2 - p1).distance;
    if (totalDist == 0) return;

    final unitVector = (p2 - p1) / totalDist;
    double currentDist = 0.0;

    while (currentDist < totalDist) {
      final start = p1 + unitVector * currentDist;
      final end =
          p1 + unitVector * math.min(currentDist + dashLength, totalDist);
      canvas.drawLine(start, end, paint);
      currentDist += dashLength + dashSpace;
    }
  }

  void _drawDottedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
  ) {
    const dotInterval = 10.0;
    final totalDist = (p2 - p1).distance;
    if (totalDist == 0) return;

    final unitVector = (p2 - p1) / totalDist;
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    for (double dist = 0; dist < totalDist; dist += dotInterval) {
      canvas.drawCircle(p1 + unitVector * dist, 1.4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasGridPainter oldDelegate) {
    return oldDelegate.gridStyle != gridStyle ||
        oldDelegate.gridType != gridType ||
        oldDelegate.theme.mode != theme.mode ||
        oldDelegate.theme.canvasBackground != theme.canvasBackground ||
        oldDelegate.transform != transform;
  }
}
