import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/core/models/skill_profile.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

void main() {
  group('StrokePoint Model', () {
    test('instantiates with defaults and custom properties', () {
      const pt = StrokePoint(
        position: Offset(10, 20),
        timestampMicros: 1234567,
      );

      expect(pt.position, const Offset(10, 20));
      expect(pt.pressure, 0.5);
      expect(pt.tilt, 0.0);
      expect(pt.timestampMicros, 1234567);
    });

    test('copyWith creates updated clone correctly', () {
      const pt = StrokePoint(
        position: Offset(10, 20),
        pressure: 0.8,
        tilt: 0.2,
        timestampMicros: 1000,
      );

      final updated = pt.copyWith(
        position: const Offset(30, 40),
        pressure: 0.95,
        tilt: 0.5,
        timestampMicros: 2000,
      );

      expect(updated.position, const Offset(30, 40));
      expect(updated.pressure, 0.95);
      expect(updated.tilt, 0.5);
      expect(updated.timestampMicros, 2000);

      final unmodified = pt.copyWith();
      expect(unmodified.position, pt.position);
      expect(unmodified.pressure, pt.pressure);
      expect(unmodified.tilt, pt.tilt);
      expect(unmodified.timestampMicros, pt.timestampMicros);
    });
  });

  group('LineWeightType Extension', () {
    test('provides accurate widths, dashed properties, and labels', () {
      expect(LineWeightType.silhouette.baseWidth, 3.5);
      expect(LineWeightType.silhouette.isDashed, isFalse);
      expect(LineWeightType.silhouette.label, contains('Silhouette'));

      expect(LineWeightType.crease.baseWidth, 2.0);
      expect(LineWeightType.crease.isDashed, isFalse);
      expect(LineWeightType.crease.label, contains('Crease'));

      expect(LineWeightType.hidden.baseWidth, 1.2);
      expect(LineWeightType.hidden.isDashed, isTrue);
      expect(LineWeightType.hidden.label, contains('Hidden'));

      expect(LineWeightType.dimension.baseWidth, 0.8);
      expect(LineWeightType.dimension.isDashed, isFalse);
      expect(LineWeightType.dimension.label, contains('Guide'));
    });
  });

  group('Stroke Model', () {
    test('handles empty and single-point strokes', () {
      final empty = Stroke(points: [], color: Colors.blue);
      expect(empty.isEmpty, isTrue);
      expect(empty.length, 0);
      expect(empty.first, isNull);
      expect(empty.last, isNull);
      expect(empty.durationMs, 0.0);
      expect(empty.totalLength, 0.0);
      expect(empty.averageVelocity, 0.0);
      expect(empty.toSmoothedPath().getBounds().isEmpty, isTrue);

      final single = Stroke(
        points: [const StrokePoint(position: Offset(50, 50), timestampMicros: 1000)],
        color: Colors.red,
        lineWeight: LineWeightType.silhouette,
      );
      expect(single.isEmpty, isFalse);
      expect(single.length, 1);
      expect(single.first?.position, const Offset(50, 50));
      expect(single.last?.position, const Offset(50, 50));
      expect(single.durationMs, 0.0);
      expect(single.totalLength, 0.0);
      expect(single.averageVelocity, 0.0);

      final singlePath = single.toSmoothedPath();
      expect(singlePath.getBounds().isEmpty, isFalse);
    });

    test('computes physical kinematics and paths for multi-point strokes', () {
      final points = [
        const StrokePoint(position: Offset.zero, timestampMicros: 1000000),
        const StrokePoint(position: Offset(100, 0), timestampMicros: 1050000), // 50ms, 100px -> 2.0 px/ms
        const StrokePoint(position: Offset(200, 0), timestampMicros: 1100000), // 100ms, 200px
      ];

      final stroke = Stroke(
        points: points,
        color: Colors.green,
        lineWeight: LineWeightType.hidden,
      );

      expect(stroke.length, 3);
      expect(stroke.durationMs, 100.0);
      expect(stroke.totalLength, 200.0);
      expect(stroke.averageVelocity, 2.0);

      final smoothedPath = stroke.toSmoothedPath();
      expect(smoothedPath.getBounds().width, closeTo(200.0, 1.0));

      final dashedPath = stroke.toDashedPath(dashLength: 10.0, dashSpace: 5.0);
      expect(dashedPath.getBounds().width, greaterThan(0));

      // Two-point stroke path branch
      final twoPoints = Stroke(
        points: [
          const StrokePoint(position: Offset.zero, timestampMicros: 1000),
          const StrokePoint(position: Offset(100, 100), timestampMicros: 2000),
        ],
        color: Colors.white,
      );
      expect(twoPoints.toSmoothedPath().getBounds().isEmpty, isFalse);
    });
  });

  group('AngleSectorStats', () {
    test('initializes and calculates rolling averages', () {
      final stats = AngleSectorStats(sectorIndex: 4); // 4 * 22.5 = 90 deg
      expect(stats.sectorIndex, 4);
      expect(stats.centerAngleDegrees, 90.0);
      expect(stats.sampleCount, 0);
      expect(stats.averageAccuracy, 0.75); // default fallback
      expect(stats.averageJitter, 0.20);   // default fallback

      stats.addSample(accuracy: 0.90, jitter: 0.10);
      stats.addSample(accuracy: 0.80, jitter: 0.20);

      expect(stats.sampleCount, 2);
      expect(stats.totalAccuracy, closeTo(1.70, 0.001));
      expect(stats.totalJitter, closeTo(0.30, 0.001));
      expect(stats.averageAccuracy, closeTo(0.85, 0.001));
      expect(stats.averageJitter, closeTo(0.15, 0.001));
    });
  });

  group('SkillProfile Model', () {
    test('initializes default 16 sectors and overall metrics', () {
      final profile = SkillProfile();
      expect(profile.angleSectors.length, 16);
      expect(profile.totalStrokesCompleted, 0);
      expect(profile.totalDrillsCompleted, 0);
      expect(profile.overallAccuracy, 0.80);
      expect(profile.overallVelocityConsistency, 0.82);
      expect(profile.averageJitter, 0.15);
      expect(profile.ellipseAccuracy, 0.75);
      expect(profile.isometricAccuracy, 0.78);
      expect(profile.formGestureAccuracy, 0.76);
    });

    test('getAdaptiveTargetAngle prioritizes untested or weak angle sectors', () {
      final profile = SkillProfile();

      // Give high scores to all sectors except sector 6 (135 deg)
      for (int i = 0; i < 16; i++) {
        profile.angleSectors[i].addSample(accuracy: 0.95, jitter: 0.05);
      }
      profile.angleSectors[6].addSample(accuracy: 0.40, jitter: 0.45);

      final targetAngle = profile.getAdaptiveTargetAngle();
      // Target angle should be clustered around 135 deg (+/- 8 deg jitter)
      expect(targetAngle, greaterThanOrEqualTo(125.0));
      expect(targetAngle, lessThanOrEqualTo(145.0));
    });

    test('records ghosting, ellipse, isometric, and form drill analyses', () {
      final profile = SkillProfile();

      // Negative angle normalization test
      profile.recordGhostingAnalysis(
        angleRadians: -0.5,
        accuracy: 0.90,
        jitter: 0.10,
        velocityConsistency: 0.88,
      );
      expect(profile.totalStrokesCompleted, 1);
      expect(profile.totalDrillsCompleted, 1);
      expect(profile.overallAccuracy, isNot(0.80));

      profile.recordEllipseAnalysis(
        accuracy: 0.85,
        minorAxisErrorDeg: 4.0,
        eccentricity: 0.5,
      );
      expect(profile.totalDrillsCompleted, 2);
      expect(profile.ellipseAccuracy, isNot(0.75));

      profile.recordIsometricAnalysis(
        accuracy: 0.92,
        lineWeightFidelity: 0.95,
      );
      expect(profile.totalDrillsCompleted, 3);
      expect(profile.isometricAccuracy, isNot(0.78));

      profile.recordFormAnalysis(accuracy: 0.89);
      expect(profile.totalDrillsCompleted, 4);
      expect(profile.formGestureAccuracy, isNot(0.76));
    });
  });

  group('AppThemeTokens', () {
    test('generates complete design tokens across all 3 studio modes', () {
      final light = AppThemeTokens.light();
      expect(light.mode, AppThemeMode.light);
      expect(light.canvasBackground, const Color(0xFFF8F9FB));
      expect(light.defaultInk, const Color(0xFF111827));
      expect(light.headingStyle.fontFamily, 'SpaceGrotesk');
      expect(light.bodyStyle.fontFamily, 'Inter');
      expect(light.monoStyle.fontFamily, 'JetBrainsMono');

      final dark = AppThemeTokens.dark();
      expect(dark.mode, AppThemeMode.dark);
      expect(dark.canvasBackground, const Color(0xFF0F1115));
      expect(dark.defaultInk, const Color(0xFFFFFFFF));

      final blueprint = AppThemeTokens.blueprint();
      expect(blueprint.mode, AppThemeMode.blueprint);
      expect(blueprint.canvasBackground, const Color(0xFF0B2046));
      expect(blueprint.defaultInk, const Color(0xFFF0F9FF));

      // Factory switch
      expect(AppThemeTokens.of(AppThemeMode.light).mode, AppThemeMode.light);
      expect(AppThemeTokens.of(AppThemeMode.dark).mode, AppThemeMode.dark);
      expect(AppThemeTokens.of(AppThemeMode.blueprint).mode, AppThemeMode.blueprint);
    });
  });
}
