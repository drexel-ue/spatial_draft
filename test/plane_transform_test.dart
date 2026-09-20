import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/canvas/mental_canvas/plane_transform_sheet.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

void main() {
  group('3D Plane Transformation & Gizmo Tests', () {
    test('CanvasPlane3D visibility and opacity properties toggle cleanly', () {
      final plane = CanvasPlane3D.primaryFront();
      expect(plane.isVisible, isTrue);
      expect(plane.opacity, equals(0.85));

      final hidden = plane.copyWith(isVisible: false, opacity: 0.5);
      expect(hidden.isVisible, isFalse);
      expect(hidden.opacity, equals(0.5));

      final json = hidden.toJson();
      expect(json['isVisible'], isFalse);
      expect(json['opacity'], equals(0.5));

      final decoded = CanvasPlane3D.fromJson(json);
      expect(decoded.isVisible, isFalse);
      expect(decoded.opacity, equals(0.5));
    });

    test(
      'Euler yaw/pitch/roll rotations transform coordinates in 3D space',
      () {
      const plane = CanvasPlane3D(
        id: 'test_yaw',
        name: 'Rotated Plane',
        yaw: math.pi / 2.0, // 90 degree yaw
        originX: 100.0,
      );

      // Local point (100, 0) rotated by 90 yaw should move along Z
      final p3 = plane.project2Dto3D(const Offset(100.0, 0.0));
      // x3 = 100 * cos(90) = 0 -> world X = originX + 0 = 100
      // z3 = -100 * sin(90) = -100 -> world Z = -100
      expect(p3[0], closeTo(100.0, 0.001));
      expect(p3[1], closeTo(0.0, 0.001));
      expect(p3[2], closeTo(-100.0, 0.001));
    });

    testWidgets('PlaneTransformSheet displays controls and updates transforms',
        (tester) async {
      CanvasPlane3D activePlane = CanvasPlane3D.primaryFront();
      bool duplicateCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    PlaneTransformSheet.show(
                      context: ctx,
                      theme: AppThemeTokens.blueprint(),
                      plane: activePlane,
                      onPlaneUpdated: (p) => activePlane = p,
                      onDuplicatePlane: () => duplicateCalled = true,
                      onDeletePlane: () {},
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify title and headers render
      expect(find.text('Primary Canvas (XY)'), findsOneWidget);
      expect(find.text('ALIGNMENT PRESETS'), findsOneWidget);
      expect(find.text('ROTATION (EULER ANGLES)'), findsOneWidget);
      expect(find.text('WORLD POSITION OFFSET'), findsOneWidget);

      // Tap preset "Ground (XZ)"
      final groundPreset = find.text('Ground (XZ)');
      expect(groundPreset, findsOneWidget);
      await tester.tap(groundPreset);
      await tester.pumpAndSettle();

      // Plane pitch should now be 90 degrees
      expect(activePlane.pitch, closeTo(math.pi / 2.0, 0.01));

      // Test Visibility toggle
      final hideBtn = find.byTooltip('Hide Plane');
      expect(hideBtn, findsOneWidget);
      await tester.tap(hideBtn);
      expect(activePlane.isVisible, isFalse);

      // Test Lock toggle
      final lockBtn = find.byTooltip('Lock Plane');
      expect(lockBtn, findsOneWidget);
      await tester.tap(lockBtn);
      expect(activePlane.isLocked, isTrue);

      // Test Duplicate action
      final duplicateBtn = find.widgetWithText(
        OutlinedButton,
        'Duplicate Plane',
      );
      await tester.scrollUntilVisible(
        duplicateBtn,
        200.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(duplicateBtn);
      expect(duplicateCalled, isTrue);
    });
  });
}
