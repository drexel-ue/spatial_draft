import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spatial_draft/canvas/mental_canvas/plane_transform_sheet.dart';
import 'package:spatial_draft/core/models/app_drill_mode.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/models/draft_capture.dart';
import 'package:spatial_draft/core/models/procedural_form.dart';
import 'package:spatial_draft/core/models/skill_profile.dart';
import 'package:spatial_draft/core/models/spatial_bookmark.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/core/widgets/skill_profile_dialog.dart';
import 'package:spatial_draft/drills/common/concept_guide_sheet.dart';
import 'package:spatial_draft/drills/form/loomis_head_drill.dart';
import 'package:spatial_draft/drills/form/pose_mannequin_drill.dart';
import 'package:spatial_draft/drills/form/procedural_form_drill.dart';
import 'package:spatial_draft/drills/precision/ellipse_drill.dart';
import 'package:spatial_draft/drills/precision/ghosting_drill.dart';
import 'package:spatial_draft/drills/precision/isometric_drill.dart';
import 'package:spatial_draft/drills/sandbox/freeform_sandbox.dart';
import 'package:spatial_draft/onboarding/onboarding_modal.dart';
import 'package:spatial_draft/onboarding/splash_screen.dart';
import 'package:spatial_draft/services/gallery_service.dart';
import 'package:spatial_draft/services/project_service.dart';
import 'package:spatial_draft/views/form_library/form_library_sheet.dart';
import 'package:spatial_draft/views/gallery/gallery_screen.dart';

Future<void> _loadFont(String family, String assetPath) async {
  final File file = File(assetPath);
  if (!file.existsSync()) {
    return;
  }
  final Uint8List bytes = file.readAsBytesSync();
  final FontLoader loader = FontLoader(family);
  loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> _loadAllFontVariants() async {
  final Map<String, String> fonts = <String, String>{
    'SpaceGrotesk': 'assets/fonts/SpaceGrotesk-Variable.ttf',
    'Outfit': 'assets/fonts/Outfit-Regular.ttf',
    'Outfit-Bold': 'assets/fonts/Outfit-Bold.ttf',
    'Outfit-SemiBold': 'assets/fonts/Outfit-SemiBold.ttf',
    'Inter': 'assets/fonts/Inter-Regular.ttf',
    'Inter-Bold': 'assets/fonts/Inter-Bold.ttf',
    'Inter-SemiBold': 'assets/fonts/Inter-SemiBold.ttf',
    'Inter-Medium': 'assets/fonts/Inter-Medium.ttf',
    'Inter-Italic': 'assets/fonts/Inter-Italic.ttf',
    'JetBrainsMono': 'assets/fonts/JetBrainsMono-Regular.ttf',
    'JetBrainsMono-Bold': 'assets/fonts/JetBrainsMono-Bold.ttf',
    'FiraCode': 'assets/fonts/FiraCode-Regular.ttf',
    'FiraCode-Bold': 'assets/fonts/FiraCode-Bold.ttf',
    'FiraCode-SemiBold': 'assets/fonts/FiraCode-SemiBold.ttf',
    'MaterialIcons': 'assets/fonts/MaterialIcons-Regular.otf',
    'MaterialIcons-Regular': 'assets/fonts/MaterialIcons-Regular.otf',
    'packages/flutter_test/MaterialIcons': 'assets/fonts/MaterialIcons-Regular.otf',
    'Roboto': 'assets/fonts/Inter-Regular.ttf',
    'Roboto-Bold': 'assets/fonts/Inter-Bold.ttf',
    'Roboto-Medium': 'assets/fonts/Inter-Medium.ttf',
    'Roboto-SemiBold': 'assets/fonts/Inter-SemiBold.ttf',
    'sans-serif': 'assets/fonts/Inter-Regular.ttf',
    '.AppleSystemUIFont': 'assets/fonts/Inter-Regular.ttf',
  };

  for (final MapEntry<String, String> entry in fonts.entries) {
    await _loadFont(entry.key, entry.value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadAllFontVariants();
  });

  late SkillProfile profile;
  GlobalKey boundaryKey = GlobalKey();

  setUp(() {
    profile = SkillProfile();
    for (int sector = 0; sector < 16; sector++) {
      final accuracy = 0.70 + (sector % 5) * 0.05;
      profile.angleSectors[sector].sampleCount = 15;
      profile.angleSectors[sector].totalAccuracy = accuracy * 15;
      profile.angleSectors[sector].totalJitter = 0.12 * 15;
    }
    profile.totalStrokesCompleted = 184;
    profile.totalDrillsCompleted = 76;
    profile.overallAccuracy = 0.92;
    profile.overallVelocityConsistency = 0.88;
    profile.averageJitter = 0.14;
    profile.ellipseAccuracy = 0.89;
    profile.isometricAccuracy = 0.94;
    profile.formGestureAccuracy = 0.86;
  });

  Widget buildTestScreen(Widget child, {ThemeData? theme}) {
    boundaryKey = GlobalKey();
    final baseTheme = theme ?? ThemeData.dark();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: baseTheme.textTheme.apply(
          fontFamily: 'Inter',
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        body: RepaintBoundary(key: boundaryKey, child: child),
      ),
    );
  }

  Future<void> captureScreen(WidgetTester tester, String filename) async {
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() async {
      final RenderRepaintBoundary? boundary =
          boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File('screenshots/$filename.png');
          file.parent.createSync(recursive: true);
          await file.writeAsBytes(byteData.buffer.asUint8List());
          // ignore: avoid_print
          print('📸 Generated screenshot: screenshots/$filename.png (${byteData.lengthInBytes} bytes)');
        }
      }
    });
  }

  group('SpatialDraft iPad Mini Landscape Screenshot Capture Suite', () {
    // iPad Mini landscape dimensions (2266 x 1488 points / scaled to logical points)
    const ipadMiniSize = Size(1133, 744);

    testWidgets('00 Animated Splash Screen', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          SplashScreen(onFinish: () {}),
        ),
      );
      await captureScreen(tester, '00_splash_screen');
    });

    testWidgets('01 Ghosting Line Quality Drill', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          GhostingDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.squareMetric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      );
      await captureScreen(tester, '01_ghosting_drill');
    });

    testWidgets('02 Perspective Ellipse Drill', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          EllipseDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.perspective,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      );
      await captureScreen(tester, '02_perspective_ellipse_drill');
    });

    testWidgets('03 Isometric Carve-Out Drill', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          IsometricDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.isometric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      );
      await captureScreen(tester, '03_isometric_carveout_drill');
    });

    testWidgets('04 3D Loomis Head Drill', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          LoomisHeadDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.dotted,
            gridType: GridType.squareMetric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      );
      await captureScreen(tester, '04_loomis_head_drill');
    });

    testWidgets('05 Kinematic Mannequin & Pose Gesture Drill', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          PoseMannequinDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.dashed,
            gridType: GridType.squareMetric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      );
      await captureScreen(tester, '05_pose_mannequin_drill');
    });

    testWidgets('06 Freeform Infinite Drafting Sandbox', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          FreeformSandbox(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.squareMetric,
          ),
        ),
      );
      await captureScreen(tester, '06_freeform_sandbox');
    });

    testWidgets('07 Drafting Blueprint Theme', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          GhostingDrill(
            theme: AppThemeTokens.blueprint(),
            gridStyle: GridStyle.solid,
            gridType: GridType.isometric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      );
      await captureScreen(tester, '07_blueprint_drafting_mode');
    });

    testWidgets('08 Light Studio Paper Theme', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          IsometricDrill(
            theme: AppThemeTokens.light(),
            gridStyle: GridStyle.solid,
            gridType: GridType.isometric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
          theme: ThemeData.light(),
        ),
      );
      await captureScreen(tester, '08_light_studio_mode');
    });

    testWidgets('09 Neuromotor Skill Matrix & Radar Dialog', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          Center(
            child: SkillProfileDialog(
              profile: profile,
              theme: AppThemeTokens.dark(),
            ),
          ),
        ),
      );
      await captureScreen(tester, '09_neuromotor_skill_matrix');
    });

    testWidgets('10 Onboarding Orientation Primer Modal', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          Center(
            child: OnboardingModal(
              theme: AppThemeTokens.dark(),
              onComplete: () {},
            ),
          ),
        ),
      );
      await captureScreen(tester, '10_onboarding_orientation_primer');
    });

    testWidgets('11 Concept Guide Sheet', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          Center(
            child: ConceptGuideSheet(
              drillTitle: 'The Ghosting Method',
              categorySubtitle: 'Motor Control & Kinematics',
              theme: AppThemeTokens.dark(),
              sections: const [
                GuideSectionItem(
                  title: 'Shoulder Biomechanics',
                  content:
                      'Lock your wrist and elbow. Drive the stylus from your shoulder ball-and-socket joint to avoid curved arcs.',
                  icon: Icons.fitness_center_rounded,
                ),
                GuideSectionItem(
                  title: 'The Ghosting Protocol',
                  content:
                      'Hover 2 to 3 times along the vector. Strike through with unbroken, confident speed.',
                  icon: Icons.air_rounded,
                ),
                GuideSectionItem(
                  title: 'Scoring Acceleration (d²s/dt²)',
                  content:
                      'Hesitation wobbles and mid-stroke slowing down are penalized more than minor aim offset.',
                  icon: Icons.speed_rounded,
                ),
              ],
            ),
          ),
        ),
      );
      await captureScreen(tester, '11_concept_guide_sheet');
    });

    testWidgets('12 Draft Gallery View', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      await GalleryService.instance.init();
      await GalleryService.instance.clearAll();

      Uint8List ghostingBytes = Uint8List(0);
      final f1 = File('screenshots/01_ghosting_drill.png');
      if (f1.existsSync()) ghostingBytes = f1.readAsBytesSync();

      Uint8List isoBytes = Uint8List(0);
      final f2 = File('screenshots/03_isometric_carveout_drill.png');
      if (f2.existsSync()) isoBytes = f2.readAsBytesSync();

      Uint8List loomisBytes = Uint8List(0);
      final f3 = File('screenshots/04_loomis_head_drill.png');
      if (f3.existsSync()) loomisBytes = f3.readAsBytesSync();

      Uint8List blueprintBytes = Uint8List(0);
      final f4 = File('screenshots/07_blueprint_drafting_mode.png');
      if (f4.existsSync()) blueprintBytes = f4.readAsBytesSync();

      await GalleryService.instance.saveCapture(
        DraftCapture(
          id: '4',
          title: 'Kinematic Shoulder Stroke Ghosting',
          drillMode: AppDrillMode.ghosting,
          themeMode: AppThemeMode.dark,
          gridStyle: GridStyle.solid,
          gridType: GridType.squareMetric,
          timestamp: DateTime(2026, 9, 19, 11, 5),
          pngBytes: ghostingBytes,
          width: 2266,
          height: 1488,
        ),
      );

      await GalleryService.instance.saveCapture(
        DraftCapture(
          id: '3',
          title: 'Loomis Cranial Matrix #4',
          drillMode: AppDrillMode.loomisHead,
          themeMode: AppThemeMode.dark,
          gridStyle: GridStyle.dotted,
          gridType: GridType.squareMetric,
          timestamp: DateTime(2026, 9, 19, 13, 20),
          pngBytes: loomisBytes,
          width: 2266,
          height: 1488,
        ),
      );

      await GalleryService.instance.saveCapture(
        DraftCapture(
          id: '1',
          title: '3D Isometric Voxel Study',
          drillMode: AppDrillMode.isometric,
          themeMode: AppThemeMode.dark,
          gridStyle: GridStyle.solid,
          gridType: GridType.isometric,
          timestamp: DateTime(2026, 9, 19, 14, 12),
          pngBytes: isoBytes,
          width: 2266,
          height: 1488,
        ),
      );

      await GalleryService.instance.saveCapture(
        DraftCapture(
          id: '2',
          title: 'Cyanotype Blueprint Carve-Out',
          drillMode: AppDrillMode.isometric,
          themeMode: AppThemeMode.blueprint,
          gridStyle: GridStyle.solid,
          gridType: GridType.isometric,
          timestamp: DateTime(2026, 9, 19, 15, 45),
          pngBytes: blueprintBytes,
          width: 2266,
          height: 1488,
        ),
      );

      await tester.pumpWidget(
        buildTestScreen(
          GalleryScreen(theme: AppThemeTokens.dark()),
        ),
      );
      await tester.runAsync(() async {
        for (final capture in GalleryService.instance.captures) {
          if (capture.pngBytes.isNotEmpty) {
            await precacheImage(
              MemoryImage(capture.pngBytes),
              tester.element(find.byType(GalleryScreen)),
            );
          }
        }
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreen(tester, '12_draft_gallery_view');
    });

    testWidgets('13 Procedural Form Practice Drill', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          ProceduralFormDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.perspective,
            skillProfile: profile,
            onProfileUpdated: () {},
            initialFormId: ProceduralFormId.eyeOrbit,
          ),
        ),
      );
      await captureScreen(tester, '13_procedural_form_drill');
    });

    testWidgets('14 Procedural Form & Anatomy Library', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestScreen(
          FormLibrarySheet(
            theme: AppThemeTokens.dark(),
            onSelectForm: (_) {},
            initialSelectedId: ProceduralFormId.eyeOrbit,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureScreen(tester, '14_procedural_form_library');
    });

    testWidgets('15 Draft Projects Vault & File Manager', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      await ProjectService.instance.init();
      await ProjectService.instance.clearAll();

      await ProjectService.instance.createProject(
        title: 'Turbine Engine Housing',
        mode: SandboxMode.mentalCanvas3D,
      );
      await ProjectService.instance.createProject(
        title: 'Avionics Multi-Scale Schematic',
        mode: SandboxMode.infiniteZoom,
      );
      await ProjectService.instance.createProject(
        title: 'Mechanical Bracket Rev C',
        mode: SandboxMode.vellum2D,
      );

      await tester.pumpWidget(
        buildTestScreen(
          GalleryScreen(
            theme: AppThemeTokens.dark(),
            initialTab: 0,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await captureScreen(tester, '15_draft_projects_vault');
    });

    testWidgets('16 Infinite Zoom Vector Engine & Metric HUD', (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      final zoomProject = SpatialProject(
        id: 'proj_zoom_demo',
        title: 'Avionics Multi-Scale Ideation',
        mode: SandboxMode.infiniteZoom,
        zoomScale: 10.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestScreen(
          FreeformSandbox(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.squareMetric,
            initialProject: zoomProject,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureScreen(tester, '16_infinite_zoom_engine');
    });

    testWidgets('17 Mental Canvas 3D Multi-Plane Parallax Stage',
        (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ground = CanvasPlane3D.groundFloor();
      final leftWall = CanvasPlane3D.leftWall();

      final frontStroke = Stroke(
        points: const [
          StrokePoint(
            position: Offset(1800, 1800),
            pressure: 0.7,
            timestampMicros: 10,
          ),
          StrokePoint(
            position: Offset(2200, 1800),
            pressure: 0.8,
            timestampMicros: 20,
          ),
          StrokePoint(
            position: Offset(2200, 2200),
            pressure: 0.8,
            timestampMicros: 30,
          ),
          StrokePoint(
            position: Offset(1800, 2200),
            pressure: 0.7,
            timestampMicros: 40,
          ),
          StrokePoint(
            position: Offset(1800, 1800),
            pressure: 0.7,
            timestampMicros: 50,
          ),
        ],
        color: const Color(0xFF00FFCC),
        lineWeight: LineWeightType.crease,
        planeId: 'plane_primary',
      );

      final groundStroke = Stroke(
        points: const [
          StrokePoint(
            position: Offset(1700, 2000),
            pressure: 0.7,
            timestampMicros: 10,
          ),
          StrokePoint(
            position: Offset(2300, 2000),
            pressure: 0.7,
            timestampMicros: 20,
          ),
        ],
        color: const Color(0xFF38BDF8),
        lineWeight: LineWeightType.silhouette,
        planeId: ground.id,
      );

      final mentalProject = SpatialProject(
        id: 'proj_mental_demo',
        title: 'Architectural Isometric Stage',
        mode: SandboxMode.mentalCanvas3D,
        planes: [CanvasPlane3D.primaryFront(), ground, leftWall],
        activePlaneId: ground.id,
        cameraYaw: 0.52,
        cameraPitch: 0.28,
        cameraDistance: 950.0,
        strokes: [frontStroke, groundStroke],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestScreen(
          FreeformSandbox(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.squareMetric,
            initialProject: mentalProject,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureScreen(tester, '17_mental_canvas_3d_stage');
    });

    testWidgets('18 3D Plane Transform Gizmo & Sheet', (tester) async {
      final ground = CanvasPlane3D.groundFloor();
      final leftWall = CanvasPlane3D.leftWall();
      final mentalProject = SpatialProject(
        id: 'proj_mental_gizmo',
        title: 'Architectural Isometric Stage',
        mode: SandboxMode.mentalCanvas3D,
        planes: [CanvasPlane3D.primaryFront(), ground, leftWall],
        activePlaneId: ground.id,
        cameraYaw: 0.52,
        cameraPitch: 0.28,
        cameraDistance: 950.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestScreen(
          Stack(
            children: [
              FreeformSandbox(
                theme: AppThemeTokens.dark(),
                gridStyle: GridStyle.solid,
                gridType: GridType.squareMetric,
                initialProject: mentalProject,
              ),
              Positioned(
                bottom: 0,
                left: 160,
                right: 160,
                child: PlaneTransformSheet(
                  theme: AppThemeTokens.dark(),
                  plane: ground,
                  onPlaneUpdated: (_) {},
                  onDuplicatePlane: () {},
                  onDeletePlane: () {},
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureScreen(tester, '18_plane_transform_gizmo');
    });

    testWidgets('19 Infinite Zoom Bookmarks & Scale Dock', (tester) async {
      final bookmarks = [
        SpatialBookmark(
          id: 'bm_1',
          name: '1:1 Blueprint Overview',
          zoomScale: 1.0,
          createdAt: DateTime.now(),
        ),
        SpatialBookmark(
          id: 'bm_2',
          name: 'Micro-Piston Assembly (150×)',
          zoomScale: 150.0,
          createdAt: DateTime.now(),
        ),
        SpatialBookmark(
          id: 'bm_3',
          name: 'Nanotube Sub-Grid (2500×)',
          zoomScale: 2500.0,
          createdAt: DateTime.now(),
        ),
      ];

      final zoomProject = SpatialProject(
        id: 'proj_zoom_bm',
        title: 'Deep Multiscale Avionics',
        mode: SandboxMode.infiniteZoom,
        zoomScale: 150.0,
        bookmarks: bookmarks,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestScreen(
          FreeformSandbox(
            theme: AppThemeTokens.blueprint(),
            gridStyle: GridStyle.solid,
            gridType: GridType.squareMetric,
            initialProject: zoomProject,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureScreen(tester, '19_infinite_zoom_bookmarks');
    });

    testWidgets('20 3D Cinematic Storyboard Tour & Cel-Shading Palette Dock',
        (tester) async {
      tester.view.physicalSize = ipadMiniSize;
      tester.view.devicePixelRatio = 1.5;
      addTearDown(() => tester.view.resetPhysicalSize());

      final waypoints = [
        SpatialBookmark.waypoint3D(
          id: 'kf1',
          name: '1. Wide Inception Shot',
          cameraYaw: 0.42,
          cameraPitch: 0.18,
          cameraDistance: 1050.0,
        ),
        SpatialBookmark.waypoint3D(
          id: 'kf2',
          name: '2. Dynamic Character Parallax',
          cameraYaw: 0.88,
          cameraPitch: 0.26,
          cameraDistance: 780.0,
        ),
        SpatialBookmark.waypoint3D(
          id: 'kf3',
          name: '3. Apex Monument Flyby',
          cameraYaw: -0.52,
          cameraPitch: -0.15,
          cameraDistance: 1250.0,
        ),
      ];

      final tourProject = SpatialProject(
        id: 'proj_3d_tour',
        title: 'Ninja Inception Parallax',
        mode: SandboxMode.mentalCanvas3D,
        cameraYaw: 0.42,
        cameraPitch: 0.18,
        cameraDistance: 1050.0,
        planes: [
          CanvasPlane3D.primaryFront(),
          CanvasPlane3D.groundFloor(),
          CanvasPlane3D.backdrop(),
        ],
        strokes: [
          // Crisp ink contour
          Stroke(
            points: [
              const StrokePoint(
                position: Offset(1800, 1900),
                pressure: 0.7,
                timestampMicros: 0,
              ),
              const StrokePoint(
                position: Offset(2200, 1900),
                pressure: 0.9,
                timestampMicros: 0,
              ),
            ],
            color: const Color(0xFF38BDF8),
            brushStyle: LineBrushStyle.ink,
            planeId: 'plane_primary',
          ),
          // Cel-shading wash aura
          Stroke(
            points: [
              const StrokePoint(
                position: Offset(1850, 1950),
                pressure: 0.6,
                timestampMicros: 0,
              ),
              const StrokePoint(
                position: Offset(2150, 1950),
                pressure: 0.8,
                timestampMicros: 0,
              ),
            ],
            color: const Color(0xFFEF4444),
            brushStyle: LineBrushStyle.wash,
            planeId: 'plane_primary',
          ),
        ],
        bookmarks: waypoints,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestScreen(
          FreeformSandbox(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.squareMetric,
            initialProject: tourProject,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureScreen(tester, '20_cinematic_tour_dock');
    });
  });
}
