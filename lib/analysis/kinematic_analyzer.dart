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
    required this.containmentScore,
    required this.smoothnessScore,
    required this.minorAxisErrorDeg,
    required this.passed,
    double? roundnessSmoothness,
  }) : roundnessSmoothness = roundnessSmoothness ?? smoothnessScore;

  final double overallAccuracy;     // 0.0 to 1.0
  final double tangencyScore;       // contact near 4 edge midpoints (0.0 to 1.0)
  final double containmentScore;    // in-bounds integrity (0.0 to 1.0)
  final double smoothnessScore;     // curvature regularity (0.0 to 1.0)
  final double minorAxisErrorDeg;   // PCA minor axis deviation from target
  final double roundnessSmoothness; // backwards compatibility alias
  final bool passed;

  int get overallScorePercent =>
      (overallAccuracy * 100).round().clamp(0, 100);
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
        containmentScore: 0.4,
        smoothnessScore: 0.5,
        minorAxisErrorDeg: 25.0,
        passed: false,
      );
    }

    // 1. Centroid calculation
    double sumX = 0;
    double sumY = 0;
    for (final pt in stroke.points) {
      sumX += pt.position.dx;
      sumY += pt.position.dy;
    }
    final strokeCount = stroke.points.length;
    final center = Offset(sumX / strokeCount, sumY / strokeCount);

    // Centroid of bounding quad
    double quadX = 0;
    double quadY = 0;
    for (final corner in quadCorners) {
      quadX += corner.dx;
      quadY += corner.dy;
    }
    final quadCenter = Offset(
      quadX / quadCorners.length,
      quadY / quadCorners.length,
    );

    // 2. Boundary Containment (penalizes overshoots/breaches)
    final containmentScore = _computeContainmentScore(
      stroke: stroke,
      quadCorners: quadCorners,
      quadCenter: quadCenter,
    );

    // 3. Strict Edge Tangency (contact near 4 edge midpoints)
    final tangencyScore = _computeTangencyScore(
      stroke: stroke,
      quadCorners: quadCorners,
      quadCenter: quadCenter,
    );

    // 4. Curvature Regularity & Kinematic Smoothness
    final smoothnessScore = _computeSmoothnessScore(stroke);

    // 5. Global PCA Minor Axis Orientation
    final minorAxisDelta = _computePcaMinorAxisDelta(
      stroke: stroke,
      center: center,
      expectedMinorAxisAngleDeg: expectedMinorAxisAngleDeg,
    );
    final axisScore = (1.0 - (minorAxisDelta / 25.0)).clamp(0.0, 1.0);

    // 6. Weighted Pedagogical Score
    final overall = (
      tangencyScore * 0.30 +
      containmentScore * 0.25 +
      smoothnessScore * 0.25 +
      axisScore * 0.20
    ).clamp(0.0, 1.0);

    return EllipseAnalysisResult(
      overallAccuracy: overall,
      tangencyScore: tangencyScore,
      containmentScore: containmentScore,
      smoothnessScore: smoothnessScore,
      minorAxisErrorDeg: minorAxisDelta,
      passed: overall >= 0.70,
    );
  }

  static double _computeContainmentScore({
    required Stroke stroke,
    required List<Offset> quadCorners,
    required Offset quadCenter,
  }) {
    if (quadCorners.length < 4) return 1.0;

    // Reference winding signs for each quad edge using quadCenter
    final refCrossSigns = <double>[];
    for (int i = 0; i < 4; i++) {
      final a = quadCorners[i];
      final b = quadCorners[(i + 1) % 4];
      final cpRef = (b.dx - a.dx) * (quadCenter.dy - a.dy) -
          (b.dy - a.dy) * (quadCenter.dx - a.dx);
      refCrossSigns.add(cpRef == 0 ? 1.0 : (cpRef > 0 ? 1.0 : -1.0));
    }

    int breachedPoints = 0;
    double maxBreach = 0.0;
    double totalBreach = 0.0;

    for (final pt in stroke.points) {
      double pointBreach = 0.0;
      for (int i = 0; i < 4; i++) {
        final a = quadCorners[i];
        final b = quadCorners[(i + 1) % 4];
        final cp = (b.dx - a.dx) * (pt.position.dy - a.dy) -
            (b.dy - a.dy) * (pt.position.dx - a.dx);
        final sign = cp == 0 ? 0.0 : (cp > 0 ? 1.0 : -1.0);

        if (sign != 0 && sign != refCrossSigns[i]) {
          final edgeLen = (b - a).distance;
          final d = _orthogonalDistanceToSegment(pt.position, a, b, edgeLen);
          if (d > pointBreach) {
            pointBreach = d;
          }
        }
      }

      if (pointBreach > 0.0) {
        breachedPoints++;
        totalBreach += pointBreach;
        if (pointBreach > maxBreach) {
          maxBreach = pointBreach;
        }
      }
    }

    if (breachedPoints == 0) return 1.0;

    final count = stroke.points.length;
    final breachRatio = count > 0 ? breachedPoints / count : 0.0;
    final avgBreach = count > 0 ? totalBreach / count : 0.0;

    // Grace buffer of 3px for stroke ink brush thickness
    final effMax = math.max(0.0, maxBreach - 3.0);
    final effAvg = math.max(0.0, avgBreach - 1.0);

    final maxPen = (effMax / 25.0).clamp(0.0, 1.0);
    final ratioPen = (breachRatio * 1.4).clamp(0.0, 1.0);
    final avgPen = (effAvg / 8.0).clamp(0.0, 1.0);

    return (1.0 - (maxPen * 0.50 + ratioPen * 0.30 + avgPen * 0.20))
        .clamp(0.0, 1.0);
  }

  static double _computeTangencyScore({
    required Stroke stroke,
    required List<Offset> quadCorners,
    required Offset quadCenter,
  }) {
    if (quadCorners.length < 4) return 0.5;

    double totalEdgeScore = 0.0;
    for (int i = 0; i < 4; i++) {
      final a = quadCorners[i];
      final b = quadCorners[(i + 1) % 4];
      final edgeVec = b - a;
      final edgeLen = edgeVec.distance;
      if (edgeLen == 0) continue;

      double minDistance = double.infinity;
      double bestT = 0.5;
      Offset bestPt = stroke.points.first.position;

      for (final pt in stroke.points) {
        final d = _orthogonalDistanceToSegment(pt.position, a, b, edgeLen);
        if (d < minDistance) {
          minDistance = d;
          bestPt = pt.position;
          final t = ((pt.position.dx - a.dx) * edgeVec.dx +
                  (pt.position.dy - a.dy) * edgeVec.dy) /
              (edgeLen * edgeLen);
          bestT = t.clamp(0.0, 1.0);
        }
      }

      double edgeScore = 0.0;
      if (minDistance <= 8.0) {
        edgeScore = 1.0;
      } else if (minDistance <= 30.0) {
        edgeScore = (1.0 - (minDistance - 8.0) / 22.0).clamp(0.0, 1.0);
      }

      // Penalize touches trapped in corners
      if (bestT < 0.12 || bestT > 0.88) {
        edgeScore *= 0.6;
      }

      // Penalize edge if the closest point overshoots beyond the wall
      final cp = (b.dx - a.dx) * (bestPt.dy - a.dy) -
          (b.dy - a.dy) * (bestPt.dx - a.dx);
      final cpRef = (b.dx - a.dx) * (quadCenter.dy - a.dy) -
          (b.dy - a.dy) * (quadCenter.dx - a.dx);
      if (cp != 0 && (cp > 0 ? 1 : -1) != (cpRef > 0 ? 1 : -1)) {
        final overshoot = minDistance;
        if (overshoot > 8.0) {
          final overshootPen = ((overshoot - 8.0) / 20.0).clamp(0.0, 0.5);
          edgeScore = (edgeScore - overshootPen).clamp(0.0, 1.0);
        }
      }

      totalEdgeScore += edgeScore;
    }

    return (totalEdgeScore / 4.0).clamp(0.0, 1.0);
  }

  static double _computeSmoothnessScore(Stroke stroke) {
    final points = stroke.points;
    if (points.length < 12) return 0.5;

    // 1. Count inflection reversals along stroke direction
    int inflections = 0;
    double prevTurn = 0.0;
    for (int i = 2; i < points.length - 2; i++) {
      final pPrev = points[i - 2].position;
      final pCurr = points[i].position;
      final pNext = points[i + 2].position;
      final d1 = pCurr - pPrev;
      final d2 = pNext - pCurr;
      final turn = d1.dx * d2.dy - d1.dy * d2.dx;
      if (turn.abs() > 20.0) {
        if (prevTurn != 0.0 && (turn * prevTurn < 0)) {
          inflections++;
        }
        prevTurn = turn;
      }
    }

    // 2. Kinematic deceleration spikes (hesitation)
    double hesitationSum = 0.0;
    for (int i = 0; i < points.length - 2; i++) {
      final pA = points[i];
      final pB = points[i + 1];
      final pC = points[i + 2];
      final dt1 = math.max(
        1.0,
        (pB.timestampMicros - pA.timestampMicros) / 1000.0,
      );
      final dt2 = math.max(
        1.0,
        (pC.timestampMicros - pB.timestampMicros) / 1000.0,
      );
      final v1 = (pB.position - pA.position).distance / dt1;
      final v2 = (pC.position - pB.position).distance / dt2;
      final acc = (v2 - v1) / dt2;
      if (acc < -0.05) {
        hesitationSum += acc.abs();
      }
    }

    final hesitationScore =
        (1.0 - (hesitationSum / math.max(1, points.length))).clamp(0.0, 1.0);
    final inflectionPen = (inflections / 6.0).clamp(0.0, 1.0);

    return (1.0 - (inflectionPen * 0.65 + (1.0 - hesitationScore) * 0.35))
        .clamp(0.0, 1.0);
  }

  static double _computePcaMinorAxisDelta({
    required Stroke stroke,
    required Offset center,
    required double expectedMinorAxisAngleDeg,
  }) {
    final count = stroke.points.length;
    if (count < 3) return 0.0;

    double muXX = 0.0;
    double muYY = 0.0;
    double muXY = 0.0;

    for (final pt in stroke.points) {
      final dx = pt.position.dx - center.dx;
      final dy = pt.position.dy - center.dy;
      muXX += dx * dx;
      muYY += dy * dy;
      muXY += dx * dy;
    }
    muXX /= count;
    muYY /= count;
    muXY /= count;

    final diff = muXX - muYY;
    final delta = math.sqrt(diff * diff + 4.0 * muXY * muXY);
    if (delta < 1.0) {
      return 0.0;
    }

    final majorAngleRad = 0.5 * math.atan2(2.0 * muXY, diff);
    final majorAngleDeg = (majorAngleRad * 180.0 / math.pi) % 180.0;
    final minorAngleDeg = (majorAngleDeg + 90.0) % 180.0;

    final angleDiff =
        ((minorAngleDeg - expectedMinorAxisAngleDeg).abs()) % 180.0;
    return angleDiff > 90.0 ? (180.0 - angleDiff) : angleDiff;
  }

  static double _orthogonalDistanceToLine(
    Offset p,
    Offset a,
    Offset b,
    double lineLength,
  ) {
    if (lineLength == 0) return (p - a).distance;
    return ((b.dy - a.dy) * p.dx - (b.dx - a.dx) * p.dy + b.dx * a.dy - b.dy * a.dx).abs() / lineLength;
  }

  static double _orthogonalDistanceToSegment(
    Offset p,
    Offset a,
    Offset b,
    double segmentLength,
  ) {
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
