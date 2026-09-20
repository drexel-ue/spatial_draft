import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/canvas/mental_canvas/mental_canvas_painter.dart';
import 'package:spatial_draft/canvas/mental_canvas/mental_canvas_turntable_dock.dart';
import 'package:spatial_draft/canvas/mental_canvas/mental_canvas_viewport.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

void main() {
  group('Mental Canvas 3D Engine Tests', () {
    test('MentalCanvasPainter projects 3D coordinates accurately to viewport',
        () {
      final painter = MentalCanvasPainter(
        theme: AppThemeTokens.blueprint(),
        planes: [CanvasPlane3D.primaryFront()],
        activePlaneId: 'plane_primary',
        strokes: [],
        cameraYaw: 0.0,
        cameraPitch: 0.0,
        cameraDistance: 900.0,
      );

      const center = Offset(500, 400);

      // World origin (0, 0, 0) should project to center
      final screenOrigin = painter.projectWorldToScreen(0, 0, 0, center);
      expect(screenOrigin, isNotNull);
      expect(screenOrigin!.dx, closeTo(500.0, 1e-2));
      expect(screenOrigin.dy, closeTo(400.0, 1e-2));

      // Coordinate behind camera should return null
      final behindScreen = painter.projectWorldToScreen(0, 0, -950, center);
      expect(behindScreen, isNull);
    });

    testWidgets('MentalCanvasTurntableDock responds to orbit and plane taps',
        (tester) async {
      double changedYaw = 0.0;
      double changedPitch = 0.0;
      bool snappedToPlane = false;
      bool resetOrbitCalled = false;

      final planes = [
        CanvasPlane3D.primaryFront(),
        CanvasPlane3D.groundFloor(),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentalCanvasTurntableDock(
              theme: AppThemeTokens.blueprint(),
              planes: planes,
              activePlaneId: 'plane_primary',
              cameraYaw: 0.0,
              cameraPitch: 0.0,
              onCameraChanged: (yaw, pitch) {
                changedYaw = yaw;
                changedPitch = pitch;
              },
              onSelectPlane: (_) {},
              onAddPlane: (_) {},
              onSnapToPlane: () => snappedToPlane = true,
              onResetOrbit: () => resetOrbitCalled = true,
            ),
          ),
        ),
      );

      // Verify active plane name is shown
      expect(find.text('Primary Canvas (XY)'), findsOneWidget);

      // Tap Face Plane button
      final snapBtn = find.byTooltip('Face Plane (Align Camera Normal)');
      expect(snapBtn, findsOneWidget);
      await tester.tap(snapBtn);
      await tester.pumpAndSettle();
      expect(snappedToPlane, isTrue);

      // Tap Orbit Right button (+15 deg)
      final orbitRightBtn = find.byTooltip('Orbit Right (+15°)');
      expect(orbitRightBtn, findsOneWidget);
      await tester.tap(orbitRightBtn);
      await tester.pumpAndSettle();
      expect(changedYaw, closeTo(15.0 * math.pi / 180.0, 1e-4));

      // Tap Tilt Up button (+10 deg)
      final tiltUpBtn = find.byTooltip('Tilt Up (+10°)');
      expect(tiltUpBtn, findsOneWidget);
      await tester.tap(tiltUpBtn);
      await tester.pumpAndSettle();
      expect(changedPitch, closeTo(10.0 * math.pi / 180.0, 1e-4));

      // Tap Reset Camera button
      final resetBtn = find.byTooltip('Reset 3D Camera');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();
      expect(resetOrbitCalled, isTrue);
    });

    testWidgets('MentalCanvasViewport captures drawing on active 3D plane',
        (tester) async {
      Stroke? completedStroke;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: MentalCanvasViewport(
                theme: AppThemeTokens.blueprint(),
                planes: [CanvasPlane3D.primaryFront()],
                activePlaneId: 'plane_primary',
                strokes: const [],
                cameraYaw: 0.0,
                cameraPitch: 0.0,
                cameraDistance: 900.0,
                onStrokeCompleted: (s) => completedStroke = s,
                onCameraChanged: (yaw, pitch, dist) {},
              ),
            ),
          ),
        ),
      );

      // Draw stroke from (400, 300) to (450, 320)
      final gesture = await tester.startGesture(const Offset(400, 300));
      await tester.pump();
      await gesture.moveTo(const Offset(450, 320));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(completedStroke, isNotNull);
      expect(completedStroke!.planeId, equals('plane_primary'));
      expect(completedStroke!.points.length, greaterThanOrEqualTo(2));
      // First point should hit close to center (u=0, v=0 -> x=2000, y=2000)
      expect(completedStroke!.points.first.position.dx, closeTo(2000.0, 5.0));
      expect(completedStroke!.points.first.position.dy, closeTo(2000.0, 5.0));
    });
  });
}
