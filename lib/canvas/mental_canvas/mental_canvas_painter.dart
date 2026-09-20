import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Renders multi-plane 3D spatial sketches with perspective parallax.
class MentalCanvasPainter extends CustomPainter {
  /// Creates a [MentalCanvasPainter].
  MentalCanvasPainter({
    required this.theme,
    required this.planes,
    required this.activePlaneId,
    required this.strokes,
    this.activeStroke,
    required this.cameraYaw,
    required this.cameraPitch,
    this.cameraDistance = 900.0,
    this.showPlaneBoundaries = true,
    this.showAxes = true,
  });

  /// Design theme tokens.
  final AppThemeTokens theme;

  /// All 3D sketching planes in the scene.
  final List<CanvasPlane3D> planes;

  /// The active plane ID receiving drawing input.
  final String activePlaneId;

  /// All vector strokes in the project document.
  final List<Stroke> strokes;

  /// In-progress active stroke currently being drawn.
  final Stroke? activeStroke;

  /// Camera turntable yaw rotation in radians.
  final double cameraYaw;

  /// Camera pitch tilt in radians.
  final double cameraPitch;

  /// Camera focal distance for perspective depth.
  final double cameraDistance;

  /// Whether to render plane boundary wireframes.
  final bool showPlaneBoundaries;

  /// Whether to render 3D orientation axis widget.
  final bool showAxes;

  /// Projects a 3D world coordinate (wx, wy, wz) into 2D screen viewport.
  Offset? projectWorldToScreen(
    double wx,
    double wy,
    double wz,
    Offset center,
  ) {
    // 1. Yaw rotation (around Y)
    final cosY = math.cos(cameraYaw);
    final sinY = math.sin(cameraYaw);
    final x1 = wx * cosY + wz * sinY;
    final y1 = wy;
    final z1 = -wx * sinY + wz * cosY;

    // 2. Pitch rotation (around X)
    final cosX = math.cos(cameraPitch);
    final sinX = math.sin(cameraPitch);
    final x2 = x1;
    final y2 = y1 * cosX - z1 * sinX;
    final z2 = y1 * sinX + z1 * cosX;

    // 3. Perspective division
    final depth = cameraDistance + z2;
    if (depth <= 20.0) return null; // Behind camera clipping

    final fovFactor = cameraDistance / depth;
    return Offset(
      center.dx + x2 * fovFactor,
      center.dy + y2 * fovFactor,
    );
  }

  /// Calculates camera-space depth Z for sorting.
  double getCameraDepth(double wx, double wy, double wz) {
    final cosY = math.cos(cameraYaw);
    final sinY = math.sin(cameraYaw);
    final z1 = -wx * sinY + wz * cosY;

    final cosX = math.cos(cameraPitch);
    final sinX = math.sin(cameraPitch);
    return wy * sinX + z1 * cosX;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);

    // Group strokes by planeId
    final strokesByPlane = <String, List<Stroke>>{};
    for (final s in strokes) {
      strokesByPlane.putIfAbsent(s.planeId, () => []).add(s);
    }

    // Sort planes by camera depth (back to front)
    final sortedPlanes = List<CanvasPlane3D>.from(planes);
    sortedPlanes.sort((a, b) {
      final depthA = getCameraDepth(a.originX, a.originY, a.originZ);
      final depthB = getCameraDepth(b.originX, b.originY, b.originZ);
      return depthA.compareTo(depthB); // furthest (smallest z) first
    });

    for (final plane in sortedPlanes) {
      final isActive = plane.id == activePlaneId;

      // 1. Draw Plane 3D Boundary & Grid
      if (showPlaneBoundaries) {
        _drawPlaneBoundary(canvas, plane, center, isActive);
      }

      // 2. Draw Plane Vector Strokes
      final planeStrokes = strokesByPlane[plane.id] ?? const [];
      for (final stroke in planeStrokes) {
        _drawStrokeOnPlane(canvas, stroke, plane, center, isActive);
      }

      // 3. Draw active stroke if on this plane
      if (activeStroke != null && isActive) {
        _drawStrokeOnPlane(canvas, activeStroke!, plane, center, true);
      }
    }

    // 4. Draw 3D Orientation Axes
    if (showAxes) {
      _drawOrientationAxes(canvas, size);
    }
  }

  void _drawPlaneBoundary(
    Canvas canvas,
    CanvasPlane3D plane,
    Offset center,
    bool isActive,
  ) {
    final hw = plane.width / 2.0;
    final hh = plane.height / 2.0;

    final corners2D = [
      Offset(-hw, -hh),
      Offset(hw, -hh),
      Offset(hw, hh),
      Offset(-hw, hh),
    ];

    final projected = <Offset>[];
    for (final c in corners2D) {
      final p3 = plane.project2Dto3D(c);
      final sp = projectWorldToScreen(p3[0], p3[1], p3[2], center);
      if (sp != null) projected.add(sp);
    }

    if (projected.length < 4) return;

    final path = Path()
      ..moveTo(projected[0].dx, projected[0].dy)
      ..lineTo(projected[1].dx, projected[1].dy)
      ..lineTo(projected[2].dx, projected[2].dy)
      ..lineTo(projected[3].dx, projected[3].dy)
      ..close();

    // Subtle plane fill
    final planeColor = plane.color;
    final fillPaint = Paint()
      ..color = planeColor.withOpacity(isActive ? 0.05 : 0.015)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Plane outline border
    final borderPaint = Paint()
      ..color = planeColor.withOpacity(isActive ? 0.75 : 0.25)
      ..strokeWidth = isActive ? 1.8 : 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, borderPaint);

    // Draw active plane grid subdivisions (3x3 grid)
    if (isActive) {
      final gridPaint = Paint()
        ..color = planeColor.withOpacity(0.12)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      for (int i = 1; i <= 3; i++) {
        final t = i / 4.0;
        final u = -hw + plane.width * t;
        final top3 = plane.project2Dto3D(Offset(u, -hh));
        final bot3 = plane.project2Dto3D(Offset(u, hh));
        final pTop = projectWorldToScreen(top3[0], top3[1], top3[2], center);
        final pBot = projectWorldToScreen(bot3[0], bot3[1], bot3[2], center);
        if (pTop != null && pBot != null) {
          canvas.drawLine(pTop, pBot, gridPaint);
        }

        final v = -hh + plane.height * t;
        final left3 = plane.project2Dto3D(Offset(-hw, v));
        final right3 = plane.project2Dto3D(Offset(hw, v));
        final pLeft = projectWorldToScreen(left3[0], left3[1], left3[2], center);
        final pRight = projectWorldToScreen(
          right3[0],
          right3[1],
          right3[2],
          center,
        );
        if (pLeft != null && pRight != null) {
          canvas.drawLine(pLeft, pRight, gridPaint);
        }
      }
    }
  }

  void _drawStrokeOnPlane(
    Canvas canvas,
    Stroke stroke,
    CanvasPlane3D plane,
    Offset center,
    bool isActive,
  ) {
    if (stroke.points.isEmpty) return;

    // Map 2D stroke points to 3D world, then project to screen
    final screenPoints = <Offset>[];
    for (final pt in stroke.points) {
      // Stroke points are authored on a 4000x4000 canvas centered at (2000, 2000)
      final u = pt.position.dx - 2000.0;
      final v = pt.position.dy - 2000.0;

      final p3 = plane.project2Dto3D(Offset(u, v));
      final sp = projectWorldToScreen(p3[0], p3[1], p3[2], center);
      if (sp != null) {
        screenPoints.add(sp);
      }
    }

    if (screenPoints.isEmpty) return;

    // Depth-based line weight compensation
    final p03 = plane.project2Dto3D(Offset(
      stroke.points.first.position.dx - 2000.0,
      stroke.points.first.position.dy - 2000.0,
    ));
    final depth = cameraDistance + getCameraDepth(p03[0], p03[1], p03[2]);
    final depthFactor = (cameraDistance / math.max(50.0, depth)).clamp(
      0.3,
      3.0,
    );

    final strokeWidth = stroke.lineWeight.baseWidth * depthFactor;
    final opacity = isActive ? stroke.color.opacity : stroke.color.opacity * 0.55;

    final paint = Paint()
      ..color = stroke.color.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (screenPoints.length == 1) {
      canvas.drawCircle(
        screenPoints.first,
        strokeWidth / 2.0,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path()..moveTo(screenPoints[0].dx, screenPoints[0].dy);
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

    canvas.drawPath(path, paint);
  }

  void _drawOrientationAxes(Canvas canvas, Size size) {
    final origin = Offset(size.width - 55.0, 48.0);
    const axisLen = 26.0;

    Offset rotate3D(double x, double y, double z) {
      final cosY = math.cos(cameraYaw);
      final sinY = math.sin(cameraYaw);
      final x1 = x * cosY + z * sinY;
      final y1 = y;
      final z1 = -x * sinY + z * cosY;

      final cosX = math.cos(cameraPitch);
      final sinX = math.sin(cameraPitch);
      final x2 = x1;
      final y2 = y1 * cosX - z1 * sinX;

      return Offset(origin.dx + x2, origin.dy + y2);
    }

    final xEnd = rotate3D(axisLen, 0, 0);
    final yEnd = rotate3D(0, axisLen, 0);
    final zEnd = rotate3D(0, 0, axisLen);

    // X Axis (Red)
    canvas.drawLine(
      origin,
      xEnd,
      Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = 2.0,
    );
    // Y Axis (Green)
    canvas.drawLine(
      origin,
      yEnd,
      Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 2.0,
    );
    // Z Axis (Blue)
    canvas.drawLine(
      origin,
      zEnd,
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant MentalCanvasPainter oldDelegate) {
    return oldDelegate.cameraYaw != cameraYaw ||
        oldDelegate.cameraPitch != cameraPitch ||
        oldDelegate.cameraDistance != cameraDistance ||
        oldDelegate.activePlaneId != activePlaneId ||
        oldDelegate.strokes != strokes ||
        oldDelegate.activeStroke != activeStroke ||
        oldDelegate.planes != planes;
  }
}
