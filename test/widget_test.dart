import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/analysis/kinematic_analyzer.dart';
import 'package:spatial_draft/core/models/skill_profile.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/main.dart';

void main() {
  testWidgets('SpatialDraftApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SpatialDraftApp());
    await tester.pump();

    // Verify logo and top bar render
    expect(find.text('SPATIAL DRAFT'), findsOneWidget);
    expect(find.text('Line Quality'), findsOneWidget);
  });

  test('KinematicAnalyzer correctly scores a straight line', () {
    const p1 = Offset(100, 100);
    const p2 = Offset(500, 100); // Perfectly horizontal line of length 400px

    final points = <StrokePoint>[];
    for (int i = 0; i <= 20; i++) {
      points.add(
        StrokePoint(
          position: Offset(100.0 + (i * 20.0), 100.0),
          pressure: 0.5,
          timestampMicros: i * 16000, // 16ms intervals
        ),
      );
    }

    final stroke = Stroke(points: points, color: Colors.black);
    final analysis = KinematicAnalyzer.analyzeGhosting(stroke: stroke, p1: p1, p2: p2);

    expect(analysis.linearAccuracy, greaterThan(0.95));
    expect(analysis.averageDeviationPx, lessThan(0.1));
    expect(analysis.overallScorePercent, greaterThan(85));
  });

  test('SkillProfile adaptively identifies weakest angle', () {
    final profile = SkillProfile();

    // Record good strokes for sector 0 (0 degrees)
    for (int i = 0; i < 5; i++) {
      profile.recordGhostingAnalysis(
        angleRadians: 0.0,
        accuracy: 0.98,
        jitter: 0.05,
        velocityConsistency: 0.95,
      );
    }

    // Record poor strokes for sector 4 (90 degrees, upward)
    for (int i = 0; i < 5; i++) {
      profile.recordGhostingAnalysis(
        angleRadians: 1.57, // ~90 deg
        accuracy: 0.40,
        jitter: 0.50,
        velocityConsistency: 0.45,
      );
    }

    // Adaptive target angle should point towards the struggling sector (~90 deg)
    final targetAngle = profile.getAdaptiveTargetAngle();
    expect(targetAngle, inInclusiveRange(70.0, 110.0));
  });
}
