import 'package:flutter/material.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Renders a precision hover reticle under Apple Pencil / stylus prior to ink.
class StylusHoverReticle extends StatelessWidget {
  /// Creates a [StylusHoverReticle].
  const StylusHoverReticle({
    super.key,
    required this.theme,
    required this.position,
    required this.currentLineWeight,
    this.isVisible = true,
  });

  /// Design theme tokens.
  final AppThemeTokens theme;

  /// Viewport coordinate of the hovering stylus tip.
  final Offset position;

  /// Active line weight setting.
  final LineWeightType currentLineWeight;

  /// Whether the reticle is currently visible.
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final penRadius = currentLineWeight.baseWidth / 2.0;
    const ringRadius = 14.0;

    return Positioned(
      left: position.dx - ringRadius,
      top: position.dy - ringRadius,
      child: IgnorePointer(
        child: SizedBox(
          width: ringRadius * 2.0,
          height: ringRadius * 2.0,
          child: CustomPaint(
            painter: _ReticlePainter(
              color: theme.accentCyan,
              penRadius: penRadius,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({
    required this.color,
    required this.penRadius,
  });

  final Color color;
  final double penRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final outerRadius = size.width / 2.0 - 2.0;

    // Outer faint targeting ring
    final ringPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, outerRadius, ringPaint);

    // Crosshair ticks
    final tickPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const tickLen = 4.0;
    // Top tick
    canvas.drawLine(
      Offset(center.dx, center.dy - outerRadius - 1),
      Offset(center.dx, center.dy - outerRadius + tickLen),
      tickPaint,
    );
    // Bottom tick
    canvas.drawLine(
      Offset(center.dx, center.dy + outerRadius + 1),
      Offset(center.dx, center.dy + outerRadius - tickLen),
      tickPaint,
    );
    // Left tick
    canvas.drawLine(
      Offset(center.dx - outerRadius - 1, center.dy),
      Offset(center.dx - outerRadius + tickLen, center.dy),
      tickPaint,
    );
    // Right tick
    canvas.drawLine(
      Offset(center.dx + outerRadius + 1, center.dy),
      Offset(center.dx + outerRadius - tickLen, center.dy),
      tickPaint,
    );

    // Inner physical stroke gauge circle
    final penPaint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final clampedRadius = penRadius.clamp(1.0, outerRadius - 2.0);
    canvas.drawCircle(center, clampedRadius, penPaint);
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.penRadius != penRadius;
  }
}
