import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/analysis/kinematic_analyzer.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';

void main() {
  group('KinematicAnalyzer - Ghosting Analysis', () {
    const p1 = Offset(100, 100);
    const p2 = Offset(500, 100); // Horizontal line length = 400

    test('returns fallback result when stroke has fewer than 3 points', () {
      final emptyStroke = Stroke(points: [], color: Colors.white);
      final resEmpty = KinematicAnalyzer.analyzeGhosting(
        stroke: emptyStroke,
        p1: p1,
        p2: p2,
      );
      expect(resEmpty.linearAccuracy, 0.5);
      expect(resEmpty.velocityConsistency, 0.5);
      expect(resEmpty.overallScorePercent, 50);

      final twoPointStroke = Stroke(
        points: [
          const StrokePoint(position: Offset(100, 100), timestampMicros: 1000),
          const StrokePoint(position: Offset(500, 100), timestampMicros: 2000),
        ],
        color: Colors.white,
      );
      final resTwo = KinematicAnalyzer.analyzeGhosting(
        stroke: twoPointStroke,
        p1: p1,
        p2: p2,
      );
      expect(resTwo.linearAccuracy, 0.5);
      expect(resTwo.startErrorPx, 0.0);
      expect(resTwo.endErrorPx, 0.0);
      expect(resTwo.heatmapColors.length, 2);
    });

    test('analyzes straight confident ballistic stroke with high accuracy and low jitter', () {
      final points = <StrokePoint>[];
      // 20 points along the exact line y = 100, advancing at constant speed
      for (int i = 0; i < 20; i++) {
        points.add(
          StrokePoint(
            position: Offset(100.0 + i * 20.0, 100.0),
            timestampMicros: 1000000 + i * 15000, // 15ms per segment
          ),
        );
      }

      final stroke = Stroke(points: points, color: Colors.white);
      final result = KinematicAnalyzer.analyzeGhosting(
        stroke: stroke,
        p1: p1,
        p2: const Offset(100.0 + 19 * 20.0, 100.0),
      );

      expect(result.linearAccuracy, greaterThanOrEqualTo(0.95));
      expect(result.velocityConsistency, greaterThan(0.70));
      expect(result.jitterIndex, lessThan(0.20));
      expect(result.averageDeviationPx, lessThan(0.01));
      expect(result.maxDeviationPx, lessThan(0.01));
      expect(result.startErrorPx, 0.0);
      expect(result.endErrorPx, 0.0);
      expect(result.overallScorePercent, greaterThanOrEqualTo(80));

      // Heatmap colors should all be confident green
      for (final color in result.heatmapColors) {
        expect(color, const Color(0xFF22C55E));
      }
    });

    test('penalizes hesitant stroke with high jitter and deviations', () {
      final points = <StrokePoint>[];
      // Alternating zig-zag points with extreme acceleration variations
      for (int i = 0; i < 15; i++) {
        final yOffset = i.isEven ? 35.0 : -35.0;
        final timeDelta = (i % 3 == 0) ? 100000 : 5000;
        points.add(
          StrokePoint(
            position: Offset(100.0 + i * 25.0, 100.0 + yOffset),
            timestampMicros: 1000000 + i * timeDelta,
          ),
        );
      }

      final stroke = Stroke(points: points, color: Colors.white);
      final result = KinematicAnalyzer.analyzeGhosting(
        stroke: stroke,
        p1: p1,
        p2: p2,
      );

      expect(result.linearAccuracy, lessThan(0.50));
      expect(result.averageDeviationPx, greaterThan(15.0));
      expect(result.heatmapColors, contains(const Color(0xFFEF4444)));
    });

    test('handles zero line length gracefully', () {
      final points = [
        const StrokePoint(position: Offset(50, 50), timestampMicros: 1000),
        const StrokePoint(position: Offset(55, 55), timestampMicros: 2000),
        const StrokePoint(position: Offset(60, 60), timestampMicros: 3000),
      ];
      final stroke = Stroke(points: points, color: Colors.white);
      final result = KinematicAnalyzer.analyzeGhosting(
        stroke: stroke,
        p1: const Offset(50, 50),
        p2: const Offset(50, 50),
      );

      expect(result.averageDeviationPx, greaterThanOrEqualTo(0.0));
    });
  });

  group('KinematicAnalyzer - Perspective Ellipse Analysis', () {
    final quadCorners = [
      const Offset(200, 200),
      const Offset(400, 200),
      const Offset(400, 400),
      const Offset(200, 400),
    ];

    test('returns fallback result when stroke has fewer than 10 points', () {
      final stroke = Stroke(
        points: List.generate(
          5,
          (i) => StrokePoint(position: Offset(250.0 + i * 10, 250), timestampMicros: i * 1000),
        ),
        color: Colors.white,
      );

      final result = KinematicAnalyzer.analyzePerspectiveEllipse(
        stroke: stroke,
        quadCorners: quadCorners,
        expectedMinorAxisAngleDeg: 90.0,
      );

      expect(result.passed, isFalse);
      expect(result.overallAccuracy, 0.4);
      expect(result.minorAxisErrorDeg, 25.0);
      expect(result.overallScorePercent, 40);
    });

    test('evaluates drawn ellipse touching bounding quad edges', () {
      // Generate a circular stroke centered at (300, 300) with radius 95
      const center = Offset(300, 300);
      const radius = 95.0;
      final points = <StrokePoint>[];

      for (int i = 0; i <= 36; i++) {
        points.add(
          StrokePoint(
            position: Offset(
              center.dx + radius * (i.isEven ? 1.0 : 0.98) * (i > 18 ? -1 : 1),
              center.dy + radius * (i > 9 && i < 27 ? 1 : -1),
            ),
            timestampMicros: i * 10000,
          ),
        );
      }

      final stroke = Stroke(points: points, color: Colors.white);
      final result = KinematicAnalyzer.analyzePerspectiveEllipse(
        stroke: stroke,
        quadCorners: quadCorners,
        expectedMinorAxisAngleDeg: 90.0,
      );

      expect(result.overallAccuracy, greaterThan(0.0));
      expect(result.tangencyScore, greaterThanOrEqualTo(0.0));
      expect(result.minorAxisErrorDeg, lessThanOrEqualTo(180.0));
    });

    test('penalizes overshooting stroke with low containment and fails pass',
        () {
      // Quad is [200, 200] to [400, 400]
      // Generate a stroke that bulges 35px above the top edge (y = 165)
      final points = <StrokePoint>[];
      for (int i = 0; i <= 36; i++) {
        final angle = i * 2.0 * math.pi / 36.0;
        final dx = 300.0 + 85.0 * math.cos(angle);
        // Top portion bulges up to y = 165 (35px outside the top wall at y = 200)
        final dy = 300.0 + (math.sin(angle) < 0 ? 135.0 : 85.0) * math.sin(angle);
        points.add(
          StrokePoint(
            position: Offset(dx, dy),
            timestampMicros: i * 10000,
          ),
        );
      }

      final stroke = Stroke(points: points, color: Colors.white);
      final result = KinematicAnalyzer.analyzePerspectiveEllipse(
        stroke: stroke,
        quadCorners: quadCorners,
        expectedMinorAxisAngleDeg: 90.0,
      );

      // Containment score should be severely penalized (< 0.60)
      expect(result.containmentScore, lessThan(0.60));
      // Overall score should be substantially lower than 95%
      expect(result.overallScorePercent, lessThan(75));
    });

    test('smooth inscribed ellipse achieves high accuracy and containment', () {
      // Inscribed circle in [200, 200] to [400, 400] centered at (300, 300) with r = 95
      const center = Offset(300, 300);
      const radius = 94.0;
      final points = <StrokePoint>[];

      for (int i = 0; i <= 60; i++) {
        final angle = i * 2.0 * math.pi / 60.0;
        points.add(
          StrokePoint(
            position: Offset(
              center.dx + radius * math.cos(angle),
              center.dy + radius * math.sin(angle),
            ),
            timestampMicros: i * 16000,
          ),
        );
      }

      final stroke = Stroke(points: points, color: Colors.white);
      final result = KinematicAnalyzer.analyzePerspectiveEllipse(
        stroke: stroke,
        quadCorners: quadCorners,
        expectedMinorAxisAngleDeg: 90.0,
      );

      expect(result.containmentScore, greaterThanOrEqualTo(0.90));
      expect(result.smoothnessScore, greaterThanOrEqualTo(0.85));
      expect(result.tangencyScore, greaterThanOrEqualTo(0.85));
      expect(result.passed, isTrue);
      expect(result.overallScorePercent, greaterThanOrEqualTo(80));
    });

    test('handles zero edge length gracefully in segment distance', () {
      final collapsedQuad = [
        const Offset(100, 100),
        const Offset(100, 100),
        const Offset(200, 200),
        const Offset(200, 200),
      ];

      final stroke = Stroke(
        points: List.generate(
          15,
          (i) => StrokePoint(
            position: Offset(120.0 + i * 5, 120.0 + i * 5),
            timestampMicros: i * 1000,
          ),
        ),
        color: Colors.white,
      );

      final result = KinematicAnalyzer.analyzePerspectiveEllipse(
        stroke: stroke,
        quadCorners: collapsedQuad,
        expectedMinorAxisAngleDeg: 45.0,
      );

      expect(result.overallAccuracy, greaterThanOrEqualTo(0.0));
    });
  });
}
