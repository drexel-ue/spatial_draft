import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

class CanvasGridPainter extends CustomPainter {
  CanvasGridPainter({
    required this.theme,
    required this.gridStyle,
    required this.gridType,
    required this.transform,
    this.viewportSize,
    super.repaint,
  });

  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final Matrix4 transform;
  final Size? viewportSize;

  double get _scale => transform.getMaxScaleOnAxis().clamp(0.0001, 50000.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (gridStyle == GridStyle.none) return;

    final scale = _scale;
    final majorPaint = Paint()
      ..color = theme.gridLineMajor
      ..strokeWidth = 1.2 / scale
      ..style = PaintingStyle.stroke;

    final minorPaint = Paint()
      ..color = theme.gridLineMinor
      ..strokeWidth = 0.8 / scale
      ..style = PaintingStyle.stroke;

    final visibleRect = _computeVisibleRect(size);

    switch (gridType) {
      case GridType.squareMetric:
        _paintSquareGrid(
          canvas,
          size,
          majorPaint,
          minorPaint,
          scale,
          visibleRect,
        );
        break;
      case GridType.isometric:
        _paintIsometricGrid(
          canvas,
          size,
          majorPaint,
          minorPaint,
          scale,
          visibleRect,
        );
        break;
      case GridType.perspective:
        _paintPerspectiveGrid(
          canvas,
          size,
          majorPaint,
          minorPaint,
          scale,
          visibleRect,
        );
        break;
    }
  }

  Rect _computeVisibleRect(Size size) {
    if (viewportSize == null ||
        viewportSize!.width <= 0 ||
        viewportSize!.height <= 0) {
      return Offset.zero & size;
    }
    try {
      final inverted = Matrix4.inverted(transform);
      final p0 = MatrixUtils.transformPoint(inverted, Offset.zero);
      final p1 = MatrixUtils.transformPoint(
        inverted,
        Offset(viewportSize!.width, 0),
      );
      final p2 = MatrixUtils.transformPoint(
        inverted,
        Offset(0, viewportSize!.height),
      );
      final p3 = MatrixUtils.transformPoint(
        inverted,
        Offset(viewportSize!.width, viewportSize!.height),
      );
      final left = math.min(math.min(p0.dx, p1.dx), math.min(p2.dx, p3.dx));
      final right = math.max(math.max(p0.dx, p1.dx), math.max(p2.dx, p3.dx));
      final top = math.min(math.min(p0.dy, p1.dy), math.min(p2.dy, p3.dy));
      final bottom = math.max(math.max(p0.dy, p1.dy), math.max(p2.dy, p3.dy));

      return Rect.fromLTRB(
        math.max(0.0, left),
        math.max(0.0, top),
        math.min(size.width, right),
        math.min(size.height, bottom),
      );
    } catch (_) {
      return Offset.zero & size;
    }
  }

  void _paintSquareGrid(
    Canvas canvas,
    Size size,
    Paint majorPaint,
    Paint minorPaint,
    double scale,
    Rect visibleRect,
  ) {
    // Octave subdivision keeping screen cell spacing between 24px and 64px
    final octave = (math.log(scale) / math.ln2).floor();
    final spacing = 32.0 / math.pow(2.0, octave);
    const majorInterval = 4;

    final startCol = (visibleRect.left / spacing).floor();
    final endCol = (visibleRect.right / spacing).ceil();
    final startRow = (visibleRect.top / spacing).floor();
    final endRow = (visibleRect.bottom / spacing).ceil();

    if (gridStyle == GridStyle.dotted) {
      final dotPaint = Paint()..style = PaintingStyle.fill;
      for (int x = startCol; x <= endCol; x++) {
        for (int y = startRow; y <= endRow; y++) {
          final isMajor = (x % majorInterval == 0) && (y % majorInterval == 0);
          dotPaint.color = isMajor ? theme.gridLineMajor : theme.gridLineMinor;
          final radius = (isMajor ? 2.0 : 1.2) / scale;
          canvas.drawCircle(Offset(x * spacing, y * spacing), radius, dotPaint);
        }
      }
      return;
    }

    // Vertical lines
    for (int x = startCol; x <= endCol; x++) {
      final isMajor = x % majorInterval == 0;
      final paint = isMajor ? majorPaint : minorPaint;
      final p1 = Offset(x * spacing, visibleRect.top);
      final p2 = Offset(x * spacing, visibleRect.bottom);

      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, paint, scale);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }

    // Horizontal lines
    for (int y = startRow; y <= endRow; y++) {
      final isMajor = y % majorInterval == 0;
      final paint = isMajor ? majorPaint : minorPaint;
      final p1 = Offset(visibleRect.left, y * spacing);
      final p2 = Offset(visibleRect.right, y * spacing);

      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, paint, scale);
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
    double scale,
    Rect visibleRect,
  ) {
    final octave = (math.log(scale) / math.ln2).floor();
    final spacing = 40.0 / math.pow(2.0, octave);
    const angle = 30.0 * math.pi / 180.0;
    final tanAngle = math.tan(angle);

    // 1. Vertical lines
    final stepX = spacing * 1.5;
    final startX = (visibleRect.left / stepX).floor() * stepX;
    for (double x = startX; x <= visibleRect.right; x += stepX) {
      final p1 = Offset(x, visibleRect.top);
      final p2 = Offset(x, visibleRect.bottom);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint, scale);
      } else if (gridStyle == GridStyle.dotted) {
        _drawDottedLine(canvas, p1, p2, minorPaint, scale);
      } else {
        canvas.drawLine(p1, p2, minorPaint);
      }
    }

    // 2. 30-degree upward lines
    final minDiag =
        (visibleRect.top - visibleRect.right * tanAngle) / spacing;
    final maxDiag =
        (visibleRect.bottom - visibleRect.left * tanAngle) / spacing;
    for (int i = minDiag.floor(); i <= maxDiag.ceil(); i++) {
      final yIntercept = i * spacing;
      final p1 = Offset(
        visibleRect.left,
        yIntercept + visibleRect.left * tanAngle,
      );
      final p2 = Offset(
        visibleRect.right,
        yIntercept + visibleRect.right * tanAngle,
      );
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint, scale);
      } else if (gridStyle == GridStyle.dotted) {
        _drawDottedLine(canvas, p1, p2, minorPaint, scale);
      } else {
        canvas.drawLine(p1, p2, minorPaint);
      }
    }

    // 3. 30-degree downward lines
    final minDown =
        (visibleRect.top + visibleRect.left * tanAngle) / spacing;
    final maxDown =
        (visibleRect.bottom + visibleRect.right * tanAngle) / spacing;
    for (int i = minDown.floor(); i <= maxDown.ceil(); i++) {
      final yIntercept = i * spacing;
      final p1 = Offset(
        visibleRect.left,
        yIntercept - visibleRect.left * tanAngle,
      );
      final p2 = Offset(
        visibleRect.right,
        yIntercept - visibleRect.right * tanAngle,
      );
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint, scale);
      } else if (gridStyle == GridStyle.dotted) {
        _drawDottedLine(canvas, p1, p2, minorPaint, scale);
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
    double scale,
    Rect visibleRect,
  ) {
    final horizonY = size.height * 0.42;
    final vp = Offset(size.width * 0.5, horizonY);

    // Horizon line
    canvas.drawLine(
      Offset(visibleRect.left, horizonY),
      Offset(visibleRect.right, horizonY),
      majorPaint,
    );

    // Perspective rays originating from vanishing point
    const rayCount = 18;
    for (int i = 0; i <= rayCount; i++) {
      final targetX = (size.width / rayCount) * i;
      final targetBottom = Offset(targetX, size.height);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, vp, targetBottom, minorPaint, scale);
      } else if (gridStyle == GridStyle.dotted) {
        _drawDottedLine(canvas, vp, targetBottom, minorPaint, scale);
      } else {
        canvas.drawLine(vp, targetBottom, minorPaint);
      }
    }

    // Ground plane horizontal perspective lines
    for (double depth = 1.0; depth < 10.0; depth += 1.0) {
      final y =
          horizonY + (size.height - horizonY) * (depth / 10.0) * (depth / 10.0);
      final p1 = Offset(visibleRect.left, y);
      final p2 = Offset(visibleRect.right, y);
      if (gridStyle == GridStyle.dashed) {
        _drawDashedLine(canvas, p1, p2, minorPaint, scale);
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
    double scale,
  ) {
    final dashLength = 8.0 / scale;
    final dashSpace = 6.0 / scale;
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
    double scale,
  ) {
    final dotInterval = 10.0 / scale;
    final totalDist = (p2 - p1).distance;
    if (totalDist == 0) return;

    final unitVector = (p2 - p1) / totalDist;
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    for (double dist = 0; dist < totalDist; dist += dotInterval) {
      canvas.drawCircle(p1 + unitVector * dist, 1.4 / scale, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasGridPainter oldDelegate) {
    return oldDelegate.gridStyle != gridStyle ||
        oldDelegate.gridType != gridType ||
        oldDelegate.theme.mode != theme.mode ||
        oldDelegate.theme.canvasBackground != theme.canvasBackground ||
        oldDelegate.transform != transform ||
        oldDelegate.viewportSize != viewportSize;
  }
}
