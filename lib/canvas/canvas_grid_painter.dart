import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CanvasGridPainter extends CustomPainter {
  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final Matrix4 transform;

  CanvasGridPainter({
    required this.theme,
    required this.gridStyle,
    required this.gridType,
    required this.transform,
  });

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
    const spacing = 32.0;
    const majorInterval = 4;

    final cols = (size.width / spacing).ceil();
    final rows = (size.height / spacing).ceil();

    if (gridStyle == GridStyle.dotted) {
      final dotPaint = Paint()..style = PaintingStyle.fill;
      for (int x = 0; x <= cols; x++) {
        for (int y = 0; y <= rows; y++) {
          final isMajor = (x % majorInterval == 0) && (y % majorInterval == 0);
          dotPaint.color = isMajor ? theme.gridLineMajor : theme.gridLineMinor;
          final radius = isMajor ? 2.0 : 1.2;
          canvas.drawCircle(Offset(x * spacing, y * spacing), radius, dotPaint);
        }
      }
      return;
    }

    // Solid or Dashed lines
    for (int x = 0; x <= cols; x++) {
      final isMajor = x % majorInterval == 0;
      final paint = isMajor ? majorPaint : minorPaint;
      final p1 = Offset(x * spacing, 0);
      final p2 = Offset(x * spacing, size.height);

      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }

    for (int y = 0; y <= rows; y++) {
      final isMajor = y % majorInterval == 0;
      final paint = isMajor ? majorPaint : minorPaint;
      final p1 = Offset(0, y * spacing);
      final p2 = Offset(size.width, y * spacing);

      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, paint);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  void _paintIsometricGrid(Canvas canvas, Size size, Paint majorPaint, Paint minorPaint) {
    const spacing = 40.0;
    const angle = 30.0 * math.pi / 180.0;
    final tanAngle = math.tan(angle);

    // 1. Vertical lines
    for (double x = 0; x < size.width; x += spacing * 1.5) {
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

    // 2. 30-degree upward lines
    final diagonalCount = (size.height + size.width * tanAngle) / spacing;
    for (int i = -diagonalCount.ceil(); i <= diagonalCount.ceil(); i++) {
      final yIntercept = i * spacing;
      final p1 = Offset(0, yIntercept);
      final p2 = Offset(size.width, yIntercept + size.width * tanAngle);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint);
      } else if (gridStyle == GridStyle.dotted) {
        _drawDottedLine(canvas, p1, p2, minorPaint);
      } else {
        canvas.drawLine(p1, p2, minorPaint);
      }
    }

    // 3. 30-degree downward lines
    for (int i = -diagonalCount.ceil(); i <= diagonalCount.ceil(); i++) {
      final yIntercept = i * spacing;
      final p1 = Offset(0, yIntercept);
      final p2 = Offset(size.width, yIntercept - size.width * tanAngle);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint);
      } else if (gridStyle == GridStyle.dotted) {
        _drawDottedLine(canvas, p1, p2, minorPaint);
      } else {
        canvas.drawLine(p1, p2, minorPaint);
      }
    }
  }

  void _paintPerspectiveGrid(Canvas canvas, Size size, Paint majorPaint, Paint minorPaint) {
    final horizonY = size.height * 0.42;
    final vp = Offset(size.width * 0.5, horizonY);

    // Horizon line
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), majorPaint);

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

    // Ground plane horizontal perspective lines (compressed toward horizon)
    for (double depth = 1.0; depth < 10.0; depth += 1.0) {
      final y = horizonY + (size.height - horizonY) * (depth / 10.0) * (depth / 10.0);
      final p1 = Offset(0, y);
      final p2 = Offset(size.width, y);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint);
      } else {
        canvas.drawLine(p1, p2, minorPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
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

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
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
        oldDelegate.theme.canvasBackground != theme.canvasBackground;
  }
}
