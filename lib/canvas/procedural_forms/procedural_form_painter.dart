import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/core/models/procedural_form.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Renders mathematical procedural geometric and anatomical forms.
class ProceduralFormPainter extends CustomPainter {
  ProceduralFormPainter({
    required this.theme,
    required this.formId,
    required this.config,
    this.overrideCenter,
    this.opacityMultiplier = 1.0,
  });

  final AppThemeTokens theme;
  final ProceduralFormId formId;
  final ProceduralFormConfig config;
  final Offset? overrideCenter;
  final double opacityMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    final center = overrideCenter ?? Offset(size.width / 2, size.height / 2);

    final silhouettePaint = Paint()
      ..color = theme.defaultInk.withOpacity(0.9 * opacityMultiplier)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final creasePaint = Paint()
      ..color = theme.borderHighlight.withOpacity(0.85 * opacityMultiplier)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final hiddenPaint = Paint()
      ..color = theme.secondaryInk.withOpacity(0.35 * opacityMultiplier)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final crossContourPaint = Paint()
      ..color = theme.accentCyan.withOpacity(0.60 * opacityMultiplier)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = theme.accentAmber.withOpacity(0.75 * opacityMultiplier)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final fillSubtle = Paint()
      ..color = theme.accentCyan.withOpacity(0.04 * opacityMultiplier)
      ..style = PaintingStyle.fill;

    switch (formId) {
      // 2D Primitives
      case ProceduralFormId.circleAxes:
        _paintCircleAxes(
          canvas,
          center,
          silhouettePaint,
          axisPaint,
          creasePaint,
        );
        break;
      case ProceduralFormId.perspectiveQuad:
        _paintPerspectiveQuad(
          canvas,
          center,
          silhouettePaint,
          axisPaint,
          fillSubtle,
        );
        break;
      case ProceduralFormId.dynamicPolygon:
        _paintDynamicPolygon(
          canvas,
          center,
          silhouettePaint,
          axisPaint,
          creasePaint,
        );
        break;
      case ProceduralFormId.rhythmSCurve:
        _paintRhythmSCurve(
          canvas,
          center,
          silhouettePaint,
          axisPaint,
          creasePaint,
        );
        break;
      case ProceduralFormId.goldenSpiral:
        _paintGoldenSpiral(
          canvas,
          center,
          silhouettePaint,
          creasePaint,
          hiddenPaint,
        );
        break;

      // 3D Volumes
      case ProceduralFormId.cubeVoxel:
        _paintCubeVoxel(
          canvas,
          center,
          silhouettePaint,
          creasePaint,
          hiddenPaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.cylinderAxle:
        _paintCylinderAxle(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.coneFrustum:
        _paintConeFrustum(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.sphereContours:
        _paintSphereContours(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.torusRing:
        _paintTorusRing(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.inclineWedge:
        _paintInclineWedge(
          canvas,
          center,
          silhouettePaint,
          creasePaint,
          hiddenPaint,
        );
        break;
      case ProceduralFormId.compoundVolumes:
        _paintCompoundVolumes(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          hiddenPaint,
        );
        break;

      // Facial Anatomy
      case ProceduralFormId.eyeOrbit:
        _paintEyeOrbit(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          axisPaint,
          creasePaint,
        );
        break;
      case ProceduralFormId.nosePrism:
        _paintNosePrism(
          canvas,
          center,
          silhouettePaint,
          creasePaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.mouthBarrel:
        _paintMouthBarrel(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          creasePaint,
        );
        break;
      case ProceduralFormId.earPlane:
        _paintEarPlane(
          canvas,
          center,
          silhouettePaint,
          creasePaint,
          crossContourPaint,
        );
        break;

      // Appendages
      case ProceduralFormId.armCylinders:
        _paintArmCylinders(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.legVolumes:
        _paintLegVolumes(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.handSpade:
        _paintHandSpade(
          canvas,
          center,
          silhouettePaint,
          creasePaint,
          crossContourPaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.footWedge:
        _paintFootWedge(
          canvas,
          center,
          silhouettePaint,
          creasePaint,
          axisPaint,
        );
        break;

      // Core & Torso
      case ProceduralFormId.ribcageEgg:
        _paintRibcageEgg(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.pelvisBucket:
        _paintPelvisBucket(
          canvas,
          center,
          silhouettePaint,
          creasePaint,
          axisPaint,
        );
        break;
      case ProceduralFormId.spinalAction:
        _paintSpinalAction(
          canvas,
          center,
          silhouettePaint,
          crossContourPaint,
          axisPaint,
        );
        break;
    }
  }

  // ----------------- 3D Projection Math -----------------

  Offset _project(double x, double y, double z, Offset center) {
    // 3D rotation: yaw (Y-axis), pitch (X-axis), roll (Z-axis)
    final cosY = math.cos(config.yaw);
    final sinY = math.sin(config.yaw);
    final x1 = x * cosY + z * sinY;
    final y1 = y;
    final z1 = -x * sinY + z * cosY;

    final cosX = math.cos(config.pitch);
    final sinX = math.sin(config.pitch);
    final x2 = x1;
    final y2 = y1 * cosX - z1 * sinX;
    final z2 = y1 * sinX + z1 * cosX;

    const cameraDist = 800.0;
    final perspective = cameraDist / (cameraDist + z2);
    final scale = config.scale * perspective;

    return Offset(
      center.dx + x2 * scale,
      center.dy + y2 * scale,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dist = (p2 - p1).distance;
    if (dist <= 0) return;
    const dashLength = 6.0;
    const gapLength = 4.0;
    final dx = (p2.dx - p1.dx) / dist;
    final dy = (p2.dy - p1.dy) / dist;
    double curr = 0.0;
    while (curr < dist) {
      final end = math.min(curr + dashLength, dist);
      canvas.drawLine(
        Offset(p1.dx + dx * curr, p1.dy + dy * curr),
        Offset(p1.dx + dx * end, p1.dy + dy * end),
        paint,
      );
      curr += dashLength + gapLength;
    }
  }

  // ----------------- 2D Primitives -----------------

  void _paintCircleAxes(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint axis,
    Paint crease,
  ) {
    final r = 90.0 * config.scale;
    canvas.drawCircle(center, r, silhouette);

    if (config.showBoundingBox) {
      canvas.drawRect(
        Rect.fromCircle(center: center, radius: r),
        crease,
      );
    }
    if (config.showAxes) {
      canvas.drawLine(
        Offset(center.dx - r * 1.3, center.dy),
        Offset(center.dx + r * 1.3, center.dy),
        axis,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - r * 1.3),
        Offset(center.dx, center.dy + r * 1.3),
        axis,
      );
    }
  }

  void _paintPerspectiveQuad(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint axis,
    Paint fill,
  ) {
    final wTop = 130.0 * config.scale;
    final wBot = 210.0 * config.scale;
    final h = 130.0 * config.scale;

    final p0 = Offset(center.dx - wTop / 2, center.dy - h / 2);
    final p1 = Offset(center.dx + wTop / 2, center.dy - h / 2);
    final p2 = Offset(center.dx + wBot / 2, center.dy + h / 2);
    final p3 = Offset(center.dx - wBot / 2, center.dy + h / 2);

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, silhouette);

    if (config.showAxes) {
      // Diagonals
      canvas.drawLine(p0, p2, axis);
      canvas.drawLine(p1, p3, axis);
      // Perspective center
      final midTop = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      final midBot = Offset((p3.dx + p2.dx) / 2, (p3.dy + p2.dy) / 2);
      final midLeft = Offset((p0.dx + p3.dx) / 2, (p0.dy + p3.dy) / 2);
      final midRight = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      canvas.drawLine(midTop, midBot, axis);
      canvas.drawLine(midLeft, midRight, axis);
    }
  }

  void _paintDynamicPolygon(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint axis,
    Paint crease,
  ) {
    const sides = 5;
    final r = 95.0 * config.scale;
    final vertices = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2.0 * math.pi / sides) - math.pi / 2.0 + config.yaw;
      vertices.add(
        Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle)),
      );
    }

    final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
    for (int i = 1; i < sides; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();
    canvas.drawPath(path, silhouette);

    if (config.showAxes) {
      for (int i = 0; i < sides; i++) {
        final oppMid = Offset(
          (vertices[(i + 2) % sides].dx + vertices[(i + 3) % sides].dx) / 2,
          (vertices[(i + 2) % sides].dy + vertices[(i + 3) % sides].dy) / 2,
        );
        canvas.drawLine(vertices[i], oppMid, axis);
      }
      canvas.drawCircle(center, 4.0, crease);
    }
  }

  void _paintRhythmSCurve(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint axis,
    Paint crease,
  ) {
    final s = 110.0 * config.scale;
    final p0 = Offset(center.dx - s, center.dy - s * 0.9);
    final c1 = Offset(center.dx + s * 0.7, center.dy - s * 0.6);
    final c2 = Offset(center.dx - s * 0.7, center.dy + s * 0.6);
    final p3 = Offset(center.dx + s, center.dy + s * 0.9);

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p3.dx, p3.dy);
    canvas.drawPath(path, silhouette);

    if (config.showAxes) {
      canvas.drawCircle(center, 4.0, axis);
      canvas.drawLine(p0, c1, crease);
      canvas.drawLine(p3, c2, crease);
    }
  }

  void _paintGoldenSpiral(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crease,
    Paint hidden,
  ) {
    final path = Path();
    const turns = 2.5;
    const steps = 70;
    final b = 0.22 * config.scale;
    for (int i = 0; i <= steps; i++) {
      final theta = i * (turns * 2 * math.pi) / steps;
      final r = 12.0 * math.exp(b * theta) * config.scale;
      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, silhouette);

    if (config.showBoundingBox) {
      final boundW = 190.0 * config.scale;
      final boundH = 120.0 * config.scale;
      canvas.drawRect(
        Rect.fromCenter(center: center, width: boundW, height: boundH),
        crease,
      );
    }
  }

  // ----------------- 3D Volumes -----------------

  void _paintCubeVoxel(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crease,
    Paint hidden,
    Paint axis,
  ) {
    const s = 80.0;
    // 8 vertices in local coordinates
    final v = [
      _project(-s, -s, -s, center), // 0: Top-Back-Left
      _project(s, -s, -s, center),  // 1: Top-Back-Right
      _project(s, s, -s, center),   // 2: Bot-Back-Right
      _project(-s, s, -s, center),  // 3: Bot-Back-Left
      _project(-s, -s, s, center),  // 4: Top-Front-Left
      _project(s, -s, s, center),   // 5: Top-Front-Right
      _project(s, s, s, center),    // 6: Bot-Front-Right
      _project(-s, s, s, center),   // 7: Bot-Front-Left
    ];

    // Front face
    canvas.drawLine(v[4], v[5], silhouette);
    canvas.drawLine(v[5], v[6], silhouette);
    canvas.drawLine(v[6], v[7], silhouette);
    canvas.drawLine(v[7], v[4], silhouette);

    // Connecting ribs
    canvas.drawLine(v[0], v[4], crease);
    canvas.drawLine(v[1], v[5], silhouette);
    canvas.drawLine(v[2], v[6], silhouette);
    canvas.drawLine(v[3], v[7], crease);

    // Top & side front edges
    canvas.drawLine(v[0], v[1], crease);
    canvas.drawLine(v[1], v[2], crease);

    // Hidden back edges
    if (config.showHiddenLines) {
      _drawDashedLine(canvas, v[0], v[3], hidden);
      _drawDashedLine(canvas, v[3], v[2], hidden);
    }

    if (config.showAxes) {
      final topC = Offset((v[0].dx + v[1].dx + v[4].dx + v[5].dx) / 4,
          (v[0].dy + v[1].dy + v[4].dy + v[5].dy) / 4);
      final botC = Offset((v[3].dx + v[2].dx + v[7].dx + v[6].dx) / 4,
          (v[3].dy + v[2].dy + v[7].dy + v[6].dy) / 4);
      canvas.drawLine(topC, botC, axis);
    }
  }

  void _paintCylinderAxle(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint axis,
  ) {
    const r = 60.0;
    const h = 100.0;
    const steps = 32;

    final topPts = <Offset>[];
    final botPts = <Offset>[];
    for (int i = 0; i <= steps; i++) {
      final a = i * 2.0 * math.pi / steps;
      topPts.add(_project(r * math.cos(a), -h, r * math.sin(a), center));
      botPts.add(_project(r * math.cos(a), h, r * math.sin(a), center));
    }

    final topPath = Path()..moveTo(topPts.first.dx, topPts.first.dy);
    for (final p in topPts) {
      topPath.lineTo(p.dx, p.dy);
    }
    final botPath = Path()..moveTo(botPts.first.dx, botPts.first.dy);
    for (final p in botPts) {
      botPath.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(topPath, silhouette);
    canvas.drawPath(botPath, silhouette);

    // Outer silhouette generator rails
    canvas.drawLine(topPts[0], botPts[0], silhouette);
    canvas.drawLine(topPts[steps ~/ 2], botPts[steps ~/ 2], silhouette);

    // Cross-contours along the shaft
    if (config.showWireframe) {
      for (int k = 1; k < config.crossContourCount; k++) {
        final t = -h + (2.0 * h * k / config.crossContourCount);
        final ringPts = <Offset>[];
        for (int i = 0; i <= steps; i++) {
          final a = i * 2.0 * math.pi / steps;
          ringPts.add(_project(r * math.cos(a), t, r * math.sin(a), center));
        }
        final ringPath = Path()..moveTo(ringPts.first.dx, ringPts.first.dy);
        for (final p in ringPts) {
          ringPath.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(ringPath, crossContour);
      }
    }

    if (config.showAxes) {
      final topC = _project(0, -h * 1.25, 0, center);
      final botC = _project(0, h * 1.25, 0, center);
      canvas.drawLine(topC, botC, axis);
    }
  }

  void _paintConeFrustum(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint axis,
  ) {
    const rBot = 75.0;
    const rTop = 25.0;
    const h = 100.0;
    const steps = 28;

    final botPts = <Offset>[];
    final topPts = <Offset>[];
    for (int i = 0; i <= steps; i++) {
      final a = i * 2.0 * math.pi / steps;
      botPts.add(_project(rBot * math.cos(a), h, rBot * math.sin(a), center));
      topPts.add(_project(rTop * math.cos(a), -h * 0.4, rTop * math.sin(a), center));
    }

    final botPath = Path()..moveTo(botPts.first.dx, botPts.first.dy);
    for (final p in botPts) {
      botPath.lineTo(p.dx, p.dy);
    }
    final topPath = Path()..moveTo(topPts.first.dx, topPts.first.dy);
    for (final p in topPts) {
      topPath.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(botPath, silhouette);
    canvas.drawPath(topPath, crossContour);

    // Apex & silhouette rails
    final apex = _project(0, -h * 1.1, 0, center);
    canvas.drawLine(botPts[0], apex, silhouette);
    canvas.drawLine(botPts[steps ~/ 2], apex, silhouette);

    if (config.showAxes) {
      final botCenter = _project(0, h, 0, center);
      canvas.drawLine(apex, botCenter, axis);
    }
  }

  void _paintSphereContours(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint axis,
  ) {
    const r = 85.0;
    // Outer silhouette is always a circle in 3D orthographic/perspective
    canvas.drawCircle(center, r * config.scale, silhouette);

    const steps = 36;
    if (config.showWireframe) {
      // Latitude bands (equator + 2 parallels)
      final lats = [-45.0, 0.0, 45.0];
      for (final lat in lats) {
        final rad = lat * math.pi / 180.0;
        final y = r * math.sin(rad);
        final ringR = r * math.cos(rad);
        final pts = <Offset>[];
        for (int i = 0; i <= steps; i++) {
          final a = i * 2.0 * math.pi / steps;
          pts.add(_project(ringR * math.cos(a), y, ringR * math.sin(a), center));
        }
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final p in pts) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, crossContour);
      }

      // Longitude great circles
      final longs = [0.0, 60.0, 120.0];
      for (final lon in longs) {
        final rad = lon * math.pi / 180.0;
        final pts = <Offset>[];
        for (int i = 0; i <= steps; i++) {
          final a = i * 2.0 * math.pi / steps;
          final x = r * math.cos(a) * math.cos(rad);
          final y = r * math.sin(a);
          final z = r * math.cos(a) * math.sin(rad);
          pts.add(_project(x, y, z, center));
        }
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final p in pts) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, crossContour);
      }
    }

    if (config.showAxes) {
      final pNorth = _project(0, -r * 1.3, 0, center);
      final pSouth = _project(0, r * 1.3, 0, center);
      canvas.drawLine(pNorth, pSouth, axis);
    }
  }

  void _paintTorusRing(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint axis,
  ) {
    const rMajor = 75.0;
    const rMinor = 28.0;
    const uSteps = 24;
    const vSteps = 16;

    for (int i = 0; i < uSteps; i += 3) {
      final u = i * 2.0 * math.pi / uSteps;
      final pts = <Offset>[];
      for (int j = 0; j <= vSteps; j++) {
        final v = j * 2.0 * math.pi / vSteps;
        final x = (rMajor + rMinor * math.cos(v)) * math.cos(u);
        final y = rMinor * math.sin(v);
        final z = (rMajor + rMinor * math.cos(v)) * math.sin(u);
        pts.add(_project(x, y, z, center));
      }
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, crossContour);
    }

    // Outer & inner rim contours
    final outerPts = <Offset>[];
    final innerPts = <Offset>[];
    for (int i = 0; i <= uSteps; i++) {
      final u = i * 2.0 * math.pi / uSteps;
      outerPts.add(_project(
        (rMajor + rMinor) * math.cos(u),
        0,
        (rMajor + rMinor) * math.sin(u),
        center,
      ));
      innerPts.add(_project(
        (rMajor - rMinor) * math.cos(u),
        0,
        (rMajor - rMinor) * math.sin(u),
        center,
      ));
    }
    final outerPath = Path()..moveTo(outerPts.first.dx, outerPts.first.dy);
    for (final p in outerPts) {
      outerPath.lineTo(p.dx, p.dy);
    }
    final innerPath = Path()..moveTo(innerPts.first.dx, innerPts.first.dy);
    for (final p in innerPts) {
      innerPath.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(outerPath, silhouette);
    canvas.drawPath(innerPath, silhouette);
  }

  void _paintInclineWedge(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crease,
    Paint hidden,
  ) {
    const w = 70.0;
    const l = 90.0;
    const h = 80.0;

    // 6 vertices of triangular prism
    final v0 = _project(-w, h, -l, center); // Back-left base
    final v1 = _project(w, h, -l, center);  // Back-right base
    final v2 = _project(w, h, l, center);   // Front-right base
    final v3 = _project(-w, h, l, center);  // Front-left base
    final v4 = _project(-w, -h, -l, center); // Back-left apex
    final v5 = _project(w, -h, -l, center);  // Back-right apex

    // Inclined ramp plane
    canvas.drawLine(v4, v5, silhouette);
    canvas.drawLine(v5, v2, silhouette);
    canvas.drawLine(v2, v3, silhouette);
    canvas.drawLine(v3, v4, silhouette);

    // Vertical back plane
    canvas.drawLine(v4, v0, crease);
    canvas.drawLine(v5, v1, silhouette);
    canvas.drawLine(v1, v2, silhouette);

    if (config.showHiddenLines) {
      _drawDashedLine(canvas, v0, v1, hidden);
      _drawDashedLine(canvas, v0, v3, hidden);
    }
  }

  void _paintCompoundVolumes(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint hidden,
  ) {
    // Base Box
    const s = 65.0;
    final b0 = _project(-s, -s * 0.5, -s, center);
    final b1 = _project(s, -s * 0.5, -s, center);
    final b2 = _project(s, s, -s, center);
    final b3 = _project(-s, s, -s, center);
    final b4 = _project(-s, -s * 0.5, s, center);
    final b5 = _project(s, -s * 0.5, s, center);
    final b6 = _project(s, s, s, center);
    final b7 = _project(-s, s, s, center);

    canvas.drawLine(b4, b5, silhouette);
    canvas.drawLine(b5, b6, silhouette);
    canvas.drawLine(b6, b7, silhouette);
    canvas.drawLine(b7, b4, silhouette);
    canvas.drawLine(b0, b4, silhouette);
    canvas.drawLine(b1, b5, silhouette);
    canvas.drawLine(b2, b6, silhouette);
    canvas.drawLine(b0, b1, silhouette);

    if (config.showHiddenLines) {
      _drawDashedLine(canvas, b0, b3, hidden);
      _drawDashedLine(canvas, b3, b2, hidden);
      _drawDashedLine(canvas, b3, b7, hidden);
    }

    // Intersecting penetrating cylinder poking out of top
    const cylR = 32.0;
    const cylH = -115.0;
    const steps = 24;
    final cylPts = <Offset>[];
    for (int i = 0; i <= steps; i++) {
      final a = i * 2.0 * math.pi / steps;
      cylPts.add(_project(cylR * math.cos(a), cylH, cylR * math.sin(a), center));
    }
    final cylPath = Path()..moveTo(cylPts.first.dx, cylPts.first.dy);
    for (final p in cylPts) {
      cylPath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(cylPath, silhouette);
    canvas.drawLine(
      _project(-cylR, cylH, 0, center),
      _project(-cylR, -s * 0.5, 0, center),
      crossContour,
    );
    canvas.drawLine(
      _project(cylR, cylH, 0, center),
      _project(cylR, -s * 0.5, 0, center),
      crossContour,
    );
  }

  // ----------------- Facial Anatomy -----------------

  void _paintEyeOrbit(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint axis,
    Paint crease,
  ) {
    const eyeR = 65.0;

    // 1. Eyeball sphere wireframe
    canvas.drawCircle(center, eyeR * config.scale, crossContour);

    // 2. Orbital socket bone rim (outer boxy rim)
    final oTopL = _project(-90, -75, -20, center);
    final oTopR = _project(85, -70, -20, center);
    final oBotR = _project(80, 75, -20, center);
    final oBotL = _project(-85, 80, -20, center);
    final orbitPath = Path()
      ..moveTo(oTopL.dx, oTopL.dy)
      ..lineTo(oTopR.dx, oTopR.dy)
      ..lineTo(oBotR.dx, oBotR.dy)
      ..lineTo(oBotL.dx, oBotL.dy)
      ..close();
    canvas.drawPath(orbitPath, crease);

    // 3. Iris & Pupil in perspective
    const irisR = 26.0;
    const pupilR = 11.0;
    final irisCenter = _project(10, 0, 55, center);
    canvas.drawCircle(irisCenter, irisR * config.scale, silhouette);
    final pupilPaint = Paint()
      ..color = theme.defaultInk.withOpacity(0.85 * opacityMultiplier)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(irisCenter, pupilR * config.scale, pupilPaint);

    // 4. Upper eyelid wrapping curve
    final tearDuct = _project(-55, 6, 20, center);
    final outerCorner = _project(60, -4, 20, center);
    final upperPeak = _project(5, -34, 52, center);
    final lowerDip = _project(8, 28, 48, center);

    final upperLid = Path()
      ..moveTo(tearDuct.dx, tearDuct.dy)
      ..quadraticBezierTo(upperPeak.dx, upperPeak.dy, outerCorner.dx, outerCorner.dy);
    canvas.drawPath(upperLid, silhouette);

    // Upper lid crease fold
    final foldPeak = _project(5, -52, 42, center);
    final foldPath = Path()
      ..moveTo(tearDuct.dx - 10, tearDuct.dy - 12)
      ..quadraticBezierTo(foldPeak.dx, foldPeak.dy, outerCorner.dx + 12, outerCorner.dy - 8);
    canvas.drawPath(foldPath, crease);

    // 5. Lower eyelid wrapping curve
    final lowerLid = Path()
      ..moveTo(tearDuct.dx, tearDuct.dy)
      ..quadraticBezierTo(lowerDip.dx, lowerDip.dy, outerCorner.dx, outerCorner.dy);
    canvas.drawPath(lowerLid, silhouette);

    // Eye gaze vector axis
    if (config.showAxes) {
      final gazeEnd = _project(25, 0, 130, center);
      canvas.drawLine(irisCenter, gazeEnd, axis);
    }
  }

  void _paintNosePrism(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crease,
    Paint axis,
  ) {
    // Keystone glabella
    final gTopL = _project(-35, -100, -10, center);
    final gTopR = _project(35, -100, -10, center);
    final gBotL = _project(-20, -60, 10, center);
    final gBotR = _project(20, -60, 10, center);

    // Bridge ridge
    final bTipL = _project(-18, 30, 45, center);
    final bTipR = _project(18, 30, 45, center);

    // Ball of nose
    final ballApex = _project(0, 50, 65, center);
    final ballL = _project(-24, 60, 48, center);
    final ballR = _project(24, 60, 48, center);

    // Nostril wings (alar)
    final alarL = _project(-50, 65, 15, center);
    final alarR = _project(50, 65, 15, center);

    // Under-plane base
    final septum = _project(0, 75, 25, center);

    // Keystone
    canvas.drawLine(gTopL, gTopR, crease);
    canvas.drawLine(gTopL, gBotL, crease);
    canvas.drawLine(gTopR, gBotR, crease);
    canvas.drawLine(gBotL, gBotR, crease);

    // Bridge top plane
    canvas.drawLine(gBotL, bTipL, silhouette);
    canvas.drawLine(gBotR, bTipR, silhouette);
    canvas.drawLine(bTipL, bTipR, crease);

    // Bridge side slopes to cheek
    final cheekL = _project(-55, 25, -20, center);
    final cheekR = _project(55, 25, -20, center);
    canvas.drawLine(gBotL, cheekL, crease);
    canvas.drawLine(bTipL, cheekL, crease);
    canvas.drawLine(gBotR, cheekR, crease);
    canvas.drawLine(bTipR, cheekR, crease);

    // Ball volume & nostrils
    final ballPath = Path()
      ..moveTo(bTipL.dx, bTipL.dy)
      ..lineTo(ballApex.dx, ballApex.dy)
      ..lineTo(bTipR.dx, bTipR.dy)
      ..lineTo(ballR.dx, ballR.dy)
      ..lineTo(septum.dx, septum.dy)
      ..lineTo(ballL.dx, ballL.dy)
      ..close();
    canvas.drawPath(ballPath, silhouette);

    // Nostril wings
    canvas.drawLine(ballL, alarL, silhouette);
    canvas.drawLine(alarL, septum, silhouette);
    canvas.drawLine(ballR, alarR, silhouette);
    canvas.drawLine(alarR, septum, silhouette);

    if (config.showAxes) {
      canvas.drawLine(_project(0, -110, 0, center), septum, axis);
    }
  }

  void _paintMouthBarrel(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint crease,
  ) {
    // Cylindrical barrel cross-contours
    const r = 85.0;
    final barrelPts = <Offset>[];
    for (int i = 0; i <= 24; i++) {
      final a = -math.pi * 0.45 + (i * math.pi * 0.9 / 24);
      barrelPts.add(_project(r * math.sin(a), 0, r * math.cos(a) - 60, center));
    }
    final barrelPath = Path()..moveTo(barrelPts.first.dx, barrelPts.first.dy);
    for (final p in barrelPts) {
      barrelPath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(barrelPath, crossContour);

    // Upper lip M-contour
    final cL = _project(-65, 0, 10, center);
    final cR = _project(65, 0, 10, center);
    final mCenter = _project(0, -18, 55, center);
    final mDip = _project(0, -5, 52, center);
    final nodL = _project(-22, -16, 46, center);
    final nodR = _project(22, -16, 46, center);

    final upperLipTop = Path()
      ..moveTo(cL.dx, cL.dy)
      ..lineTo(nodL.dx, nodL.dy)
      ..lineTo(mCenter.dx, mCenter.dy)
      ..lineTo(nodR.dx, nodR.dy)
      ..lineTo(cR.dx, cR.dy);
    canvas.drawPath(upperLipTop, silhouette);

    // Mouth parting line
    final partLine = Path()
      ..moveTo(cL.dx, cL.dy)
      ..quadraticBezierTo(nodL.dx, nodL.dy + 6, mDip.dx, mDip.dy)
      ..quadraticBezierTo(nodR.dx, nodR.dy + 6, cR.dx, cR.dy);
    canvas.drawPath(partLine, silhouette);

    // Lower lip double pillows
    final lowBot = _project(0, 24, 48, center);
    final lowL = _project(-26, 20, 42, center);
    final lowR = _project(26, 20, 42, center);

    final lowerLipBot = Path()
      ..moveTo(cL.dx, cL.dy)
      ..quadraticBezierTo(lowL.dx, lowL.dy, lowBot.dx, lowBot.dy)
      ..quadraticBezierTo(lowR.dx, lowR.dy, cR.dx, cR.dy);
    canvas.drawPath(lowerLipBot, silhouette);

    // Philtrum column
    canvas.drawLine(
      _project(-12, -45, 45, center),
      _project(-8, -18, 52, center),
      crease,
    );
    canvas.drawLine(
      _project(12, -45, 45, center),
      _project(8, -18, 52, center),
      crease,
    );
  }

  void _paintEarPlane(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crease,
    Paint crossContour,
  ) {
    final root = _project(-15, -60, 0, center);
    final helixApex = _project(25, -95, 10, center);
    final helixBack = _project(55, -30, 0, center);
    final lobeBot = _project(15, 70, -5, center);
    final lobeAtt = _project(-15, 45, 0, center);

    // Outer helix rim C-curve
    final helix = Path()
      ..moveTo(root.dx, root.dy)
      ..cubicTo(helixApex.dx, helixApex.dy, helixBack.dx, helixBack.dy, lobeBot.dx, lobeBot.dy)
      ..lineTo(lobeAtt.dx, lobeAtt.dy);
    canvas.drawPath(helix, silhouette);

    // Antihelix Y-fork
    final yStem = _project(28, 15, 12, center);
    final yBranchTop = _project(10, -55, 14, center);
    final yBranchMid = _project(-8, -40, 10, center);
    final antihelix = Path()
      ..moveTo(lobeBot.dx - 10, lobeBot.dy - 20)
      ..lineTo(yStem.dx, yStem.dy)
      ..lineTo(yBranchTop.dx, yBranchTop.dy)
      ..moveTo(yStem.dx, yStem.dy)
      ..lineTo(yBranchMid.dx, yBranchMid.dy);
    canvas.drawPath(antihelix, crease);

    // Concha bowl
    final concha = Path()
      ..moveTo(root.dx + 5, root.dy + 15)
      ..quadraticBezierTo(yStem.dx - 15, yStem.dy, lobeAtt.dx + 10, lobeAtt.dy - 10);
    canvas.drawPath(concha, crossContour);

    // Tragus notch
    canvas.drawCircle(_project(-12, 0, 5, center), 6.0, crease);
  }

  // ----------------- Appendages -----------------

  void _paintArmCylinders(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint axis,
  ) {
    // Shoulder Deltoid teardrop
    final sTop = _project(0, -110, 0, center);
    final sL = _project(-42, -75, 15, center);
    final sR = _project(42, -75, 15, center);
    final sTip = _project(0, -35, 25, center);

    final deltoid = Path()
      ..moveTo(sTop.dx, sTop.dy)
      ..lineTo(sL.dx, sL.dy)
      ..lineTo(sTip.dx, sTip.dy)
      ..lineTo(sR.dx, sR.dy)
      ..close();
    canvas.drawPath(deltoid, silhouette);

    // Bicep/Tricep upper cylinder
    final elbC = _project(5, 25, -10, center);
    canvas.drawCircle(elbC, 24.0 * config.scale, crossContour);
    canvas.drawLine(sL, _project(-28, 20, 5, center), silhouette);
    canvas.drawLine(sR, _project(32, 20, 5, center), silhouette);

    // Forearm tapering wedge toward wrist
    final wL = _project(-18, 120, 20, center);
    final wR = _project(20, 120, 20, center);
    canvas.drawLine(_project(-28, 20, 5, center), wL, silhouette);
    canvas.drawLine(_project(32, 20, 5, center), wR, silhouette);
    canvas.drawLine(wL, wR, silhouette);

    // Wrapping cross-contour bands
    canvas.drawLine(
      _project(-22, -10, 20, center),
      _project(22, -10, 20, center),
      crossContour,
    );
    canvas.drawLine(
      _project(-24, 70, 15, center),
      _project(26, 70, 15, center),
      crossContour,
    );

    if (config.showAxes) {
      canvas.drawLine(sTop, elbC, axis);
      canvas.drawLine(elbC, Offset((wL.dx + wR.dx) / 2, (wL.dy + wR.dy) / 2), axis);
    }
  }

  void _paintLegVolumes(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint axis,
  ) {
    // Hip joint
    final hip = _project(0, -115, 0, center);

    // Thigh cylinder forward sweep
    final tL = _project(-38, -100, 10, center);
    final tR = _project(38, -100, 10, center);

    // Knee box (patella)
    final kC = _project(10, -5, 25, center);
    final kRect = Rect.fromCenter(
      center: kC,
      width: 32.0 * config.scale,
      height: 38.0 * config.scale,
    );
    canvas.drawRect(kRect, silhouette);

    canvas.drawLine(tL, _project(-22, -15, 15, center), silhouette);
    canvas.drawLine(tR, _project(30, -15, 15, center), silhouette);

    // Lower leg S-curve & calf gastrocnemius
    final aL = _project(-16, 115, -10, center);
    final aR = _project(18, 115, -10, center);

    // Calf curve
    final calfPath = Path()
      ..moveTo(_project(-22, 10, 15, center).dx, _project(-22, 10, 15, center).dy)
      ..quadraticBezierTo(
        _project(-42, 45, 10, center).dx,
        _project(-42, 45, 10, center).dy,
        aL.dx,
        aL.dy,
      );
    canvas.drawPath(calfPath, silhouette);

    final shinPath = Path()
      ..moveTo(_project(26, 10, 15, center).dx, _project(26, 10, 15, center).dy)
      ..lineTo(aR.dx, aR.dy);
    canvas.drawPath(shinPath, silhouette);
    canvas.drawLine(aL, aR, silhouette);

    if (config.showAxes) {
      canvas.drawLine(hip, kC, axis);
      canvas.drawLine(kC, Offset((aL.dx + aR.dx) / 2, (aL.dy + aR.dy) / 2), axis);
    }
  }

  void _paintHandSpade(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crease,
    Paint crossContour,
    Paint axis,
  ) {
    // Palm spade wedge (carpal to metacarpal heads)
    final wristL = _project(-35, 75, 0, center);
    final wristR = _project(35, 75, 0, center);
    final knuckleL = _project(-48, -10, 15, center);
    final knuckleR = _project(48, -10, 15, center);

    final palm = Path()
      ..moveTo(wristL.dx, wristL.dy)
      ..lineTo(knuckleL.dx, knuckleL.dy)
      ..lineTo(knuckleR.dx, knuckleR.dy)
      ..lineTo(wristR.dx, wristR.dy)
      ..close();
    canvas.drawPath(palm, silhouette);

    // Thenar thumb pad wedge
    final thumbBase = _project(-58, 40, 12, center);
    final thumbTip = _project(-72, -15, 25, center);
    canvas.drawLine(wristL, thumbBase, silhouette);
    canvas.drawLine(thumbBase, thumbTip, silhouette);
    canvas.drawLine(thumbTip, knuckleL, silhouette);

    // 4 Finger rays
    final fingerXs = [-36.0, -12.0, 12.0, 36.0];
    final fingerLens = [70.0, 85.0, 80.0, 65.0];
    for (int i = 0; i < 4; i++) {
      final kPt = _project(fingerXs[i], -10, 15, center);
      final tipPt = _project(fingerXs[i] * 1.1, -10 - fingerLens[i], 20, center);
      canvas.drawLine(kPt, tipPt, silhouette);
      // Joint nodes
      final j1 = Offset(
        kPt.dx + (tipPt.dx - kPt.dx) * 0.45,
        kPt.dy + (tipPt.dy - kPt.dy) * 0.45,
      );
      final j2 = Offset(
        kPt.dx + (tipPt.dx - kPt.dx) * 0.75,
        kPt.dy + (tipPt.dy - kPt.dy) * 0.75,
      );
      canvas.drawCircle(j1, 3.0, crease);
      canvas.drawCircle(j2, 2.5, crease);
    }
  }

  void _paintFootWedge(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crease,
    Paint axis,
  ) {
    // Heel calcaneus block
    final hBack = _project(0, -25, -75, center);
    final hTop = _project(0, -65, -45, center);
    final hBot = _project(0, 50, -65, center);

    // Instep high medial arch
    final archPeak = _project(-18, 0, -10, center);
    final ballOfFoot = _project(-22, 50, 45, center);
    final lateralBall = _project(32, 50, 40, center);
    final toeTip = _project(0, 50, 85, center);

    // Sole footprint
    final sole = Path()
      ..moveTo(hBot.dx, hBot.dy)
      ..lineTo(ballOfFoot.dx, ballOfFoot.dy)
      ..lineTo(toeTip.dx, toeTip.dy)
      ..lineTo(lateralBall.dx, lateralBall.dy)
      ..close();
    canvas.drawPath(sole, silhouette);

    // Ankle bridge
    canvas.drawLine(hTop, hBack, silhouette);
    canvas.drawLine(hTop, archPeak, crease);
    canvas.drawLine(archPeak, ballOfFoot, silhouette);
    canvas.drawLine(hTop, lateralBall, crease);
  }

  // ----------------- Core & Torso -----------------

  void _paintRibcageEgg(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint axis,
  ) {
    const rx = 65.0;
    const ry = 85.0;

    // Thoracic egg
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: rx * 2 * config.scale,
        height: ry * 2 * config.scale,
      ),
      silhouette,
    );

    // Sternum anterior centerline
    final sTop = _project(0, -ry * 0.8, rx * 0.8, center);
    final sBot = _project(0, ry * 0.3, rx * 0.85, center);
    canvas.drawLine(sTop, sBot, axis);

    // Clavicle handlebars
    final cL = _project(-rx * 1.1, -ry * 0.85, 0, center);
    final cR = _project(rx * 1.1, -ry * 0.85, 0, center);
    canvas.drawLine(cL, sTop, silhouette);
    canvas.drawLine(cR, sTop, silhouette);

    // Thoracic arch (inverted V at base)
    final aL = _project(-rx * 0.65, ry * 0.75, rx * 0.6, center);
    final aR = _project(rx * 0.65, ry * 0.75, rx * 0.6, center);
    canvas.drawLine(sBot, aL, silhouette);
    canvas.drawLine(sBot, aR, silhouette);

    if (config.showWireframe) {
      for (int i = 1; i <= 3; i++) {
        final y = -ry * 0.5 + i * 35.0;
        final ringW = (rx * 1.8) * math.sqrt(1 - (y * y) / (ry * ry * 1.5));
        canvas.drawOval(
          Rect.fromCenter(
            center: _project(0, y, 0, center),
            width: ringW * config.scale,
            height: 25.0 * config.scale,
          ),
          crossContour,
        );
      }
    }
  }

  void _paintPelvisBucket(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crease,
    Paint axis,
  ) {
    // Pelvic bowl bucket wedge
    const w = 75.0;
    const h = 55.0;

    final pTopL = _project(-w, -h, 0, center);
    final pTopR = _project(w, -h, 0, center);
    final pBotL = _project(-w * 0.65, h, 20, center);
    final pBotR = _project(w * 0.65, h, 20, center);
    final pubic = _project(0, h * 0.9, 35, center);

    // Iliac crest rim
    final crest = Path()
      ..moveTo(pTopL.dx, pTopL.dy)
      ..quadraticBezierTo(_project(0, -h * 1.3, -10, center).dx,
          _project(0, -h * 1.3, -10, center).dy, pTopR.dx, pTopR.dy);
    canvas.drawPath(crest, silhouette);

    // Side walls to pubic crest
    canvas.drawLine(pTopL, pBotL, silhouette);
    canvas.drawLine(pTopR, pBotR, silhouette);
    canvas.drawLine(pBotL, pubic, silhouette);
    canvas.drawLine(pBotR, pubic, silhouette);

    // ASIS landmark pins
    canvas.drawCircle(pTopL, 4.0, crease);
    canvas.drawCircle(pTopR, 4.0, crease);

    if (config.showAxes) {
      canvas.drawLine(
        _project(0, -h * 1.2, 0, center),
        pubic,
        axis,
      );
    }
  }

  void _paintSpinalAction(
    Canvas canvas,
    Offset center,
    Paint silhouette,
    Paint crossContour,
    Paint axis,
  ) {
    const len = 130.0;
    final c1 = _project(0, -len, -15, center);
    final t6 = _project(0, -len * 0.35, 25, center);
    final l3 = _project(0, len * 0.35, -20, center);
    final s1 = _project(0, len, 15, center);

    // S-curve spine line of action
    final spinePath = Path()
      ..moveTo(c1.dx, c1.dy)
      ..cubicTo(t6.dx, t6.dy, l3.dx, l3.dy, s1.dx, s1.dy);
    canvas.drawPath(spinePath, axis);

    // Vertebral cross-contour disc ellipses stacked along spine
    const discs = 7;
    for (int i = 0; i <= discs; i++) {
      final t = i / discs;
      final y = -len + (2.0 * len * t);
      // S-curve offset for z
      final z = math.sin(t * math.pi * 2.0) * 22.0;
      final discCenter = _project(0, y, z, center);
      canvas.drawOval(
        Rect.fromCenter(
          center: discCenter,
          width: (45.0 + math.sin(t * math.pi) * 15.0) * config.scale,
          height: 14.0 * config.scale,
        ),
        crossContour,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProceduralFormPainter oldDelegate) {
    return oldDelegate.formId != formId ||
        oldDelegate.config.yaw != config.yaw ||
        oldDelegate.config.pitch != config.pitch ||
        oldDelegate.config.scale != config.scale ||
        oldDelegate.config.showWireframe != config.showWireframe ||
        oldDelegate.config.showAxes != config.showAxes ||
        oldDelegate.config.showBoundingBox != config.showBoundingBox ||
        oldDelegate.config.showHiddenLines != config.showHiddenLines ||
        oldDelegate.opacityMultiplier != opacityMultiplier ||
        oldDelegate.theme != theme;
  }
}
