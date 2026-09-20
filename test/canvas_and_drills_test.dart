import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/canvas/canvas_grid_painter.dart';
import 'package:spatial_draft/canvas/ink_layer_painter.dart';
import 'package:spatial_draft/canvas/interactive_canvas.dart';
import 'package:spatial_draft/core/models/skill_profile.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/core/widgets/skill_profile_dialog.dart';
import 'package:spatial_draft/drills/common/coachmark_tooltip.dart';
import 'package:spatial_draft/drills/common/concept_guide_sheet.dart';
import 'package:spatial_draft/drills/form/loomis_head_drill.dart';
import 'package:spatial_draft/drills/form/pose_mannequin_drill.dart';
import 'package:spatial_draft/drills/precision/ellipse_drill.dart';
import 'package:spatial_draft/drills/precision/ghosting_drill.dart';
import 'package:spatial_draft/drills/precision/isometric_drill.dart';
import 'package:spatial_draft/drills/sandbox/freeform_sandbox.dart';
import 'package:spatial_draft/main.dart';
import 'package:spatial_draft/onboarding/onboarding_modal.dart';
import 'package:spatial_draft/onboarding/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ipadLandscape = Size(1133, 744);

  group('CanvasGridPainter & InkLayerPainter', () {
    final theme = AppThemeTokens.dark();

    test('CanvasGridPainter paints across all styles and grid types without error', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      for (final type in GridType.values) {
        for (final style in GridStyle.values) {
          final painter = CanvasGridPainter(
            gridStyle: style,
            gridType: type,
            theme: theme,
            transform: Matrix4.identity(),
          );
          painter.paint(canvas, size);
          expect(painter.shouldRepaint(painter), isFalse);
        }
      }
    });

    test('InkLayerPainter paints all stroke variations', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 600);

      final regularStroke = Stroke(
        points: [
          const StrokePoint(position: Offset(10, 10), timestampMicros: 1000, pressure: 0.8),
          const StrokePoint(position: Offset(50, 50), timestampMicros: 2000, pressure: 0.6),
          const StrokePoint(position: Offset(100, 100), timestampMicros: 3000, pressure: 0.4),
        ],
        color: Colors.white,
        lineWeight: LineWeightType.crease,
      );

      final dashedStroke = Stroke(
        points: [
          const StrokePoint(position: Offset(10, 100), timestampMicros: 1000),
          const StrokePoint(position: Offset(100, 100), timestampMicros: 2000),
        ],
        color: Colors.white,
        lineWeight: LineWeightType.hidden,
      );

      final heatmappedStroke = Stroke(
        points: [
          const StrokePoint(position: Offset(10, 200), timestampMicros: 1000),
          const StrokePoint(position: Offset(50, 200), timestampMicros: 2000),
          const StrokePoint(position: Offset(100, 200), timestampMicros: 3000),
        ],
        color: Colors.white,
        segmentColors: [Colors.green, Colors.amber, Colors.red],
      );

      final shortStroke = Stroke(
        points: [
          const StrokePoint(position: Offset.zero, timestampMicros: 1000),
          const StrokePoint(position: Offset(10, 10), timestampMicros: 2000),
        ],
        color: Colors.white,
      );

      final painter = InkLayerPainter(
        completedStrokes: [regularStroke, dashedStroke, heatmappedStroke, shortStroke],
        activeStroke: regularStroke,
        theme: theme,
        showHeatmap: true,
      );

      painter.paint(canvas, size);
      expect(painter.shouldRepaint(painter), isTrue);
    });

    test('CanvasGridPainter adapts spacing and hairlines across zoom scales',
        () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(4000, 4000);
      const viewportSize = Size(1133, 744);

      final scales = [0.01, 0.5, 1.0, 10.0, 100.0, 1000.0];
      for (final s in scales) {
        final transform = Matrix4.identity()..scale(s, s);
        final painter = CanvasGridPainter(
          gridStyle: GridStyle.solid,
          gridType: GridType.squareMetric,
          theme: theme,
          transform: transform,
          viewportSize: viewportSize,
        );
        painter.paint(canvas, size);

        final nextPainter = CanvasGridPainter(
          gridStyle: GridStyle.solid,
          gridType: GridType.squareMetric,
          theme: theme,
          transform: Matrix4.identity()..scale(s * 2, s * 2),
          viewportSize: viewportSize,
        );
        expect(painter.shouldRepaint(nextPainter), isTrue);
      }
    });

    test(
        'InkLayerPainter renders authoring-compensated strokes with dampening',
        () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(4000, 4000);

      final strokeAtDeepZoom = Stroke(
        points: [
          const StrokePoint(position: Offset(10, 10), timestampMicros: 1000),
          const StrokePoint(position: Offset(20, 20), timestampMicros: 2000),
        ],
        color: Colors.white,
        lineWeight: LineWeightType.crease,
        authoringScale: 50.0,
      );

      final macroStroke = Stroke(
        points: [
          const StrokePoint(position: Offset.zero, timestampMicros: 1000),
          const StrokePoint(position: Offset(100, 100), timestampMicros: 2000),
        ],
        color: Colors.white,
        lineWeight: LineWeightType.silhouette,
        authoringScale: 1.0,
      );

      final painter = InkLayerPainter(
        completedStrokes: [strokeAtDeepZoom, macroStroke],
        theme: theme,
        currentScale: 50.0,
      );

      expect(() => painter.paint(canvas, size), returnsNormally);
    });
  });

  group('InteractiveCanvas Widget Tests', () {
    final theme = AppThemeTokens.dark();

    testWidgets('captures stylus / touch drawing and emits completed stroke', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Stroke? completed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCanvas(
              theme: theme,
              strokes: const [],
              onStrokeCompleted: (s) => completed = s,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(400, 300), kind: PointerDeviceKind.mouse);
      await gesture.moveBy(const Offset(50, 50));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();
      await tester.pump();

      expect(completed, isNotNull);
      expect(completed!.points.length, greaterThanOrEqualTo(2));
    });

    testWidgets('rejects touch when allowFingerDrawing is false', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Stroke? completed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCanvas(
              theme: theme,
              allowFingerDrawing: false,
              strokes: const [],
              onStrokeCompleted: (s) => completed = s,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(400, 300), kind: PointerDeviceKind.touch);
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();
      await tester.pump();

      expect(completed, isNull);
    });

    testWidgets('cancels stroke and performs pinch zoom on two touches', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      Stroke? completed;
      double? lastScale;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveCanvas(
              theme: theme,
              allowFingerDrawing: true,
              strokes: const [],
              onStrokeCompleted: (s) => completed = s,
              onScaleChanged: (scale) => lastScale = scale,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start touch 1
      final g1 = await tester.startGesture(
        const Offset(400, 300),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();

      // Start touch 2 (pinch)
      final g2 = await tester.startGesture(
        const Offset(600, 300),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();

      // Spread fingers apart (zoom in)
      await g1.moveBy(const Offset(-100, 0));
      await g2.moveBy(const Offset(100, 0));
      await tester.pump();

      await g1.up();
      await g2.up();
      await tester.pump();

      // Multi-touch pinch must NOT record any completed stroke!
      expect(completed, isNull);
      // Scale should have increased from 1.0
      expect(lastScale, isNotNull);
      expect(lastScale, greaterThan(1.0));
    });
  });

  group('Drills Interactive Widget Tests', () {
    final theme = AppThemeTokens.dark();

    testWidgets('GhostingDrill completes stroke and renders kinematic result HUD', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profile = SkillProfile();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GhostingDrill(
              theme: theme,
              gridStyle: GridStyle.solid,
              gridType: GridType.squareMetric,
              skillProfile: profile,
              onProfileUpdated: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ghosting Practice'), findsOneWidget);

      // Drag across screen to complete a line
      final gesture = await tester.startGesture(const Offset(400, 370), kind: PointerDeviceKind.mouse);
      for (int i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(40, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('PRECISION'), findsOneWidget);
      expect(find.text('OVERALL'), findsOneWidget);
      expect(find.text('Next Reticle'), findsOneWidget);

      await tester.tap(find.text('Next Reticle'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('EllipseDrill completes stroke and renders perspective analysis HUD', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profile = SkillProfile();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EllipseDrill(
              theme: theme,
              gridStyle: GridStyle.solid,
              gridType: GridType.perspective,
              skillProfile: profile,
              onProfileUpdated: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perspective Ellipse Drill'), findsOneWidget);

      // Drag circular path
      final gesture = await tester.startGesture(const Offset(500, 300), kind: PointerDeviceKind.mouse);
      for (int i = 0; i < 16; i++) {
        await gesture.moveBy(const Offset(10, 5));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('TANGENCY'), findsOneWidget);
      expect(find.text('BOUNDS'), findsOneWidget);
      expect(find.text('SMOOTHNESS'), findsOneWidget);
      expect(find.text('Next Plane'), findsOneWidget);

      await tester.tap(find.text('Next Plane'), warnIfMissed: false);
      await tester.pumpAndSettle();
    });

    testWidgets('IsometricDrill toggles line weight and generates new billet', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profile = SkillProfile();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IsometricDrill(
              theme: theme,
              gridStyle: GridStyle.solid,
              gridType: GridType.isometric,
              skillProfile: profile,
              onProfileUpdated: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LINE HIERARCHY:'), findsOneWidget);
      // Tap Silhouette button
      await tester.tap(find.text('Silhouette'));
      await tester.pumpAndSettle();

      // Tap Hidden button
      await tester.tap(find.text('Hidden'));
      await tester.pumpAndSettle();

      // Tap New Billet
      await tester.tap(find.text('New Billet'), warnIfMissed: false);
      await tester.pumpAndSettle();
    });

    testWidgets('LoomisHeadDrill updates orientation and undoes stroke', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profile = SkillProfile();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoomisHeadDrill(
              theme: theme,
              gridStyle: GridStyle.dotted,
              gridType: GridType.squareMetric,
              skillProfile: profile,
              onProfileUpdated: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Next Rotation'), findsOneWidget);
      await tester.tap(find.text('Next Rotation'));
      await tester.pumpAndSettle();
    });

    testWidgets('PoseMannequinDrill generates new pose', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profile = SkillProfile();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PoseMannequinDrill(
              theme: theme,
              gridStyle: GridStyle.dashed,
              gridType: GridType.squareMetric,
              skillProfile: profile,
              onProfileUpdated: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Next Pose'), findsOneWidget);
      await tester.tap(find.text('Next Pose'));
      await tester.pumpAndSettle();
    });

    testWidgets('FreeformSandbox handles undo and clear actions', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FreeformSandbox(
              theme: theme,
              gridStyle: GridStyle.solid,
              gridType: GridType.squareMetric,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Draw stroke
      final gesture = await tester.startGesture(const Offset(400, 300), kind: PointerDeviceKind.mouse);
      await gesture.moveBy(const Offset(30, 30));
      await gesture.up();
      await tester.pumpAndSettle();

      // Tap Undo
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();

      // Tap Clear
      await tester.tap(find.byTooltip('Clear Canvas'));
      await tester.pumpAndSettle();
    });

    testWidgets('SpatialDraftApp cycles drills and themes', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const SpatialDraftApp(autoShowOnboarding: false, showSplash: false),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Theme toggle menu
      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Light Studio'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Grid toggle menu
      await tester.tap(find.byIcon(Icons.grid_4x4_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Dotted Grid'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap drill chips
      await tester.tap(find.text('Ellipses'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Isometric'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Loomis Head'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ConceptGuideSheet renders guide items and closes', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ConceptGuideSheet.show(
                  context: ctx,
                  drillTitle: 'Ghosting Practice Guide',
                  categorySubtitle: 'Biomechanics & Accuracy',
                  theme: theme,
                  sections: const [
                    GuideSectionItem(
                      title: 'Shoulder Lock',
                      content: 'Lock the wrist for stability.',
                      icon: Icons.lock,
                    ),
                  ],
                ),
                child: const Text('Open Guide'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Guide'));
      await tester.pumpAndSettle();

      expect(find.text('Ghosting Practice Guide'), findsOneWidget);
      expect(find.text('Shoulder Lock'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Ghosting Practice Guide'), findsNothing);
    });

    testWidgets('SkillProfileDialog renders radar chart and angle stats', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profile = SkillProfile();
      profile.recordGhostingAnalysis(
        angleRadians: 0.5,
        accuracy: 0.95,
        jitter: 0.1,
        velocityConsistency: 0.9,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SkillProfileDialog.show(
                  context: ctx,
                  profile: profile,
                  theme: theme,
                ),
                child: const Text('Open Profile'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Profile'));
      await tester.pumpAndSettle();

      expect(find.text('NEUROMOTOR PROFILE'), findsOneWidget);
      expect(find.text('Radial Angle Proficiency'), findsOneWidget);
      expect(find.text('OVERALL ACCURACY'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('OnboardingModal advances through slides and finishes', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => OnboardingModal.show(
                  context: ctx,
                  theme: theme,
                  onComplete: () => completed = true,
                ),
                child: const Text('Start Onboarding'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Onboarding'));
      await tester.pumpAndSettle();

      expect(find.text('Shoulder Over Wrist'), findsOneWidget);

      // Tap Next Slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Practice Before Contact'), findsOneWidget);

      // Tap Skip / Enter Studio
      await tester.tap(find.text('Skip Primer'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('CoachmarkTooltip dismisses and opens guide', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool dismissed = false;
      bool guideOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachmarkTooltip(
              title: 'Test Coachmark',
              message: 'Follow the on-screen instructions.',
              theme: theme,
              onDismiss: () => dismissed = true,
              onOpenGuide: () => guideOpened = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Coachmark'), findsOneWidget);

      await tester.tap(find.text('Guide'));
      await tester.pumpAndSettle();
      expect(guideOpened, isTrue);

      await tester.tap(find.byTooltip('Dismiss hint'));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });

    testWidgets('SplashScreen animates and can be skipped', (tester) async {
      tester.view.physicalSize = ipadLandscape;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SplashScreen(
              onFinish: () => finished = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SPATIAL DRAFT'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(seconds: 1));

      expect(finished, isTrue);
    });
  });
}
