import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/core/models/stroke.dart';

class GhostingAnalysisResult {

  const GhostingAnalysisResult({
    required this.linearAccuracy,
    required this.velocityConsistency,
    required this.jitterIndex,
    required this.averageDeviationPx,
    required this.maxDeviationPx,
    required this.strokeAngleRadians,
    required this.startErrorPx,
    required this.endErrorPx,
    required this.heatmapColors,
  });
  final double linearAccuracy;       // 0.0 to 1.0 (1.0 = mathematically perfect line)
  final double velocityConsistency; // 0.0 to 1.0 (1.0 = constant speed, no hesitation)
  final double jitterIndex;          // 0.0 to 1.0 (lower is smoother)
  final double averageDeviationPx;   // in pixels
  final double maxDeviationPx;       // in pixels
  final double strokeAngleRadians;
  final double startErrorPx;
  final double endErrorPx;
  final List<Color> heatmapColors;

  int get overallScorePercent => ((linearAccuracy * 0.6 + velocityConsistency * 0.4) * 100).round().clamp(0, 100);
}

class EllipseAnalysisResult {

  const EllipseAnalysisResult({
    required this.overallAccuracy,
    required this.tangencyScore,
    required this.minorAxisErrorDeg,
    required this.roundnessSmoothness,
    required this.passed,
  });
  final double overallAccuracy;     // 0.0 to 1.0
  final double tangencyScore;       // contact with bounding quad (0.0 to 1.0)
  final double minorAxisErrorDeg;   // angle difference between drawn and true minor axis
  final double roundnessSmoothness; // 0.0 to 1.0
  final bool passed;

  int get overallScorePercent => (overallAccuracy * 100).round().clamp(0, 100);
}

class KinematicAnalyzer {
  /// Analyzes a single ghosting stroke connecting origin P1 to target P2
  static GhostingAnalysisResult analyzeGhosting({
    required Stroke stroke,
    required Offset p1,
    required Offset p2,
  }) {
    final points = stroke.points;
    if (points.length < 3) {
      return GhostingAnalysisResult(
        linearAccuracy: 0.5,
        velocityConsistency: 0.5,
        jitterIndex: 0.5,
        averageDeviationPx: 20.0,
        maxDeviationPx: 30.0,
        strokeAngleRadians: math.atan2(p2.dy - p1.dy, p2.dx - p1.dx),
        startErrorPx: (points.isNotEmpty ? (points.first.position - p1).distance : 20.0),
        endErrorPx: (points.isNotEmpty ? (points.last.position - p2).distance : 20.0),
        heatmapColors: List.generate(math.max(1, points.length), (_) => const Color(0xFFEF4444)),
      );
    }

    final lineVector = p2 - p1;
    final lineLength = lineVector.distance;
    final strokeAngle = math.atan2(lineVector.dy, lineVector.dx);

    double totalDeviation = 0.0;
    double maxDeviation = 0.0;

    // 1. Orthogonal Deviation Calculation
    for (final pt in points) {
      final dev = _orthogonalDistanceToLine(pt.position, p1, p2, lineLength);
      totalDeviation += dev;
      if (dev > maxDeviation) maxDeviation = dev;
    }
    final avgDev = totalDeviation / points.length;
    // Map average deviation to accuracy score: 0px -> 1.0, 25px -> 0.0
    final linearAcc = (1.0 - (avgDev / 25.0)).clamp(0.0, 1.0);

    // 2. Kinematic Velocity & Acceleration Analysis
    final velocities = <double>[];
    final accelerations = <double>[];

    for (int i = 0; i < points.length - 1; i++) {
      final pA = points[i];
      final pB = points[i + 1];
      final dist = (pB.position - pA.position).distance;
      final dt = math.max(1.0, (pB.timestampMicros - pA.timestampMicros) / 1000.0); // ms
      velocities.add(dist / dt); // px/ms
    }

    // Velocity consistency (coefficient of variation of velocity in the middle 80% of the stroke)
    double velocitySum = 0.0;
    for (final v in velocities) {
      velocitySum += v;
    }
    final meanVelocity = velocities.isNotEmpty ? velocitySum / velocities.length : 0.0;

    double varianceSum = 0.0;
    for (int i = 0; i < velocities.length - 1; i++) {
      final vA = velocities[i];
      final vB = velocities[i + 1];
      final dt = math.max(1.0, (points[i + 2].timestampMicros - points[i + 1].timestampMicros) / 1000.0);
      final acc = (vB - vA) / dt; // px/ms^2
      accelerations.add(acc);
      varianceSum += (vA - meanVelocity) * (vA - meanVelocity);
    }

    final stdDev = velocities.isNotEmpty ? math.sqrt(varianceSum / velocities.length) : 1.0;
    final cv = meanVelocity > 0 ? (stdDev / meanVelocity) : 1.0;
    final velocityConsistency = (1.0 - (cv * 0.7)).clamp(0.0, 1.0);

    // 3. Jitter calculation (sum of negative deceleration spikes indicating hesitation)
    double hesitationSum = 0.0;
    for (final acc in accelerations) {
      if (acc < -0.05) {
        hesitationSum += acc.abs();
      }
    }
    final jitter = (hesitationSum / math.max(1, accelerations.length)).clamp(0.0, 1.0);

    // 4. Heatmap color generation for each point
    final colors = <Color>[];
    for (int i = 0; i < points.length; i++) {
      final dev = _orthogonalDistanceToLine(points[i].position, p1, p2, lineLength);
      // Normalized quality factor (1.0 is great, 0.0 is poor)
      final localScore = (1.0 - (dev / 18.0)).clamp(0.0, 1.0);
      colors.add(_scoreToColor(localScore));
    }

    final startErr = (points.first.position - p1).distance;
    final endErr = (points.last.position - p2).distance;

    return GhostingAnalysisResult(
      linearAccuracy: linearAcc,
      velocityConsistency: velocityConsistency,
      jitterIndex: jitter,
      averageDeviationPx: avgDev,
      maxDeviationPx: maxDeviation,
      strokeAngleRadians: strokeAngle,
      startErrorPx: startErr,
      endErrorPx: endErr,
      heatmapColors: colors,
    );
  }

  /// Evaluates an ellipse drawn inside a 4-point perspective quadrilateral
  static EllipseAnalysisResult analyzePerspectiveEllipse({
    required Stroke stroke,
    required List<Offset> quadCorners,
    required double expectedMinorAxisAngleDeg,
  }) {
    if (stroke.points.length < 10) {
      return const EllipseAnalysisResult(
        overallAccuracy: 0.4,
        tangencyScore: 0.4,
        minorAxisErrorDeg: 25.0,
        roundnessSmoothness: 0.5,
        passed: false,
      );
    }

    // Centroid of drawn stroke
    double sumX = 0;
    double sumY = 0;
    for (final pt in stroke.points) {
      sumX += pt.position.dx;
      sumY += pt.position.dy;
    }
    final center = Offset(sumX / stroke.points.length, sumY / stroke.points.length);

    // Centroid of bounding quad
    double quadX = 0;
    double quadY = 0;
    for (final corner in quadCorners) {
      quadX += corner.dx;
      quadY += corner.dy;
    }
    final quadCenter = Offset(quadX / quadCorners.length, quadY / quadCorners.length);
    final centerOffset = (center - quadCenter).distance;

    // Check contact points with quad edges
    int touchedEdges = 0;
    for (int i = 0; i < quadCorners.length; i++) {
      final e1 = quadCorners[i];
      final e2 = quadCorners[(i + 1) % quadCorners.length];
      final edgeLen = (e2 - e1).distance;

      double minDistance = double.infinity;
      for (final pt in stroke.points) {
        final d = _orthogonalDistanceToSegment(pt.position, e1, e2, edgeLen);
        if (d < minDistance) minDistance = d;
      }
      if (minDistance < 20.0) touchedEdges++;
    }

    final tangencyScore = (touchedEdges / 4.0).clamp(0.0, 1.0);
    final centerScore = (1.0 - (centerOffset / 30.0)).clamp(0.0, 1.0);

    // Approximate drawn minor axis by finding minimum radius from center
    double minRadius = double.infinity;
    Offset minorPoint = stroke.points.first.position;
    for (final pt in stroke.points) {
      final r = (pt.position - center).distance;
      if (r < minRadius) {
        minRadius = r;
        minorPoint = pt.position;
      }
    }
    final drawnMinorAngleDeg = (math.atan2(minorPoint.dy - center.dy, minorPoint.dx - center.dx) * 180 / math.pi) % 180;
    final angleDiff = ((drawnMinorAngleDeg - expectedMinorAxisAngleDeg).abs()) % 180;
    final minorAxisDelta = angleDiff > 90 ? (180 - angleDiff) : angleDiff;

    final axisScore = (1.0 - (minorAxisDelta / 30.0)).clamp(0.0, 1.0);
    final overall = (tangencyScore * 0.4 + centerScore * 0.3 + axisScore * 0.3).clamp(0.0, 1.0);

    return EllipseAnalysisResult(
      overallAccuracy: overall,
      tangencyScore: tangencyScore,
      minorAxisErrorDeg: minorAxisDelta,
      roundnessSmoothness: axisScore,
      passed: overall >= 0.70,
    );
  }

  static double _orthogonalDistanceToLine(Offset p, Offset a, Offset b, double lineLength) {
    if (lineLength == 0) return (p - a).distance;
    return ((b.dy - a.dy) * p.dx - (b.dx - a.dx) * p.dy + b.dx * a.dy - b.dy * a.dx).abs() / lineLength;
  }

  static double _orthogonalDistanceToSegment(Offset p, Offset a, Offset b, double segmentLength) {
    if (segmentLength == 0) return (p - a).distance;
    final t = ((p.dx - a.dx) * (b.dx - a.dx) + (p.dy - a.dy) * (b.dy - a.dy)) / (segmentLength * segmentLength);
    final clampedT = t.clamp(0.0, 1.0);
    final projection = Offset(a.dx + clampedT * (b.dx - a.dx), a.dy + clampedT * (b.dy - a.dy));
    return (p - projection).distance;
  }

  static Color _scoreToColor(double score) {
    if (score >= 0.85) {
      return const Color(0xFF22C55E); // Confident green
    } else if (score >= 0.65) {
      return const Color(0xFFFBBF24); // Amber warning
    } else {
      return const Color(0xFFEF4444); // Red hesitation
    }
  }
}
