import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/core/models/skill_profile.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/core/widgets/skill_profile_dialog.dart';
import 'package:spatial_draft/drills/common/concept_guide_sheet.dart';
import 'package:spatial_draft/drills/form/loomis_head_drill.dart';
import 'package:spatial_draft/drills/form/pose_mannequin_drill.dart';
import 'package:spatial_draft/drills/precision/ellipse_drill.dart';
import 'package:spatial_draft/drills/precision/ghosting_drill.dart';
import 'package:spatial_draft/drills/precision/isometric_drill.dart';
import 'package:spatial_draft/drills/sandbox/freeform_sandbox.dart';
import 'package:spatial_draft/onboarding/onboarding_modal.dart';
import 'package:spatial_draft/onboarding/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> captureWidget(
    WidgetTester tester,
    Widget widget,
    String filename, {
    Size size = const Size(1194, 834),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;

    final key = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: widget,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = File('screenshots/$filename');
      file.parent.createSync(recursive: true);
      await file.writeAsBytes(bytes);
    });
  }

  testWidgets(
    'Capture all SpatialDraft screenshots for README',
    (tester) async {
    addTearDown(tester.view.resetPhysicalSize);

    // Mock rich skill profile
    final profile = SkillProfile();
    for (int sector = 0; sector < 16; sector++) {
      final accuracy = 0.65 + (sector % 5) * 0.07;
      profile.angleSectors[sector].sampleCount = 12;
      profile.angleSectors[sector].totalAccuracy = accuracy * 12;
      profile.angleSectors[sector].totalJitter = 0.12 * 12;
    }
    profile.totalStrokesCompleted = 148;
    profile.totalDrillsCompleted = 62;
    profile.overallAccuracy = 0.91;
    profile.overallVelocityConsistency = 0.89;

    // 00 Animated Splash Screen
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(onFinish: () {}),
      ),
      '00_splash_screen.png',
    );

    // 01 Ghosting Line Quality Drill (with HUD)
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: GhostingDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.squareMetric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      ),
      '01_ghosting_drill.png',
    );

    // 02 Perspective Ellipse Drill
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: EllipseDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.perspective,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      ),
      '02_perspective_ellipse_drill.png',
    );

    // 03 Isometric Carve-Out Drill
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: IsometricDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.isometric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      ),
      '03_isometric_carveout_drill.png',
    );

    // 04 3D Loomis Head Drill
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: LoomisHeadDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.dotted,
            gridType: GridType.squareMetric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      ),
      '04_loomis_head_drill.png',
    );

    // 05 Kinematic Mannequin & Pose Gesture Drill
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PoseMannequinDrill(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.dashed,
            gridType: GridType.squareMetric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      ),
      '05_pose_mannequin_drill.png',
    );

    // 06 Freeform Infinite Drafting Sandbox
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: FreeformSandbox(
            theme: AppThemeTokens.dark(),
            gridStyle: GridStyle.solid,
            gridType: GridType.squareMetric,
          ),
        ),
      ),
      '06_freeform_sandbox.png',
    );

    // 07 Drafting Blueprint Theme
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: GhostingDrill(
            theme: AppThemeTokens.blueprint(),
            gridStyle: GridStyle.solid,
            gridType: GridType.isometric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      ),
      '07_blueprint_drafting_mode.png',
    );

    // 08 Light Studio Paper Theme
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        home: Scaffold(
          body: IsometricDrill(
            theme: AppThemeTokens.light(),
            gridStyle: GridStyle.solid,
            gridType: GridType.isometric,
            skillProfile: profile,
            onProfileUpdated: () {},
          ),
        ),
      ),
      '08_light_studio_mode.png',
    );

    // 09 Neuromotor Skill Matrix & Radar Dialog
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          body: Center(
            child: SkillProfileDialog(
              profile: profile,
              theme: AppThemeTokens.dark(),
            ),
          ),
        ),
      ),
      '09_neuromotor_skill_matrix.png',
    );

    // 10 Onboarding Orientation Primer Modal
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          body: Center(
            child: OnboardingModal(
              theme: AppThemeTokens.dark(),
              onComplete: () {},
            ),
          ),
        ),
      ),
      '10_onboarding_orientation_primer.png',
    );

    // 11 Concept Guide Sheet
    await captureWidget(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          body: Center(
            child: ConceptGuideSheet(
              drillTitle: 'The Ghosting Method',
              categorySubtitle: 'Motor Control & Kinematics',
              theme: AppThemeTokens.dark(),
              sections: const [
                GuideSectionItem(
                  title: 'Shoulder Biomechanics',
                  content:
                      'Lock your wrist and elbow. Drive the stylus from '
                      'your shoulder ball-and-socket joint to avoid curved '
                      'arcs.',
                  icon: Icons.fitness_center_rounded,
                ),
                GuideSectionItem(
                  title: 'The Ghosting Protocol',
                  content:
                      'Hover 2 to 3 times along the vector. Strike through '
                      'with unbroken, confident speed.',
                  icon: Icons.air_rounded,
                ),
                GuideSectionItem(
                  title: 'Scoring Acceleration (d²s/dt²)',
                  content:
                      'Hesitation wobbles and mid-stroke slowing down are '
                      'penalized more than minor aim offset.',
                  icon: Icons.speed_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
      '11_concept_guide_sheet.png',
    );
  });
}
