import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/core/models/procedural_form.dart';
import 'package:spatial_draft/core/models/skill_profile.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/drills/form/procedural_form_drill.dart';
import 'package:spatial_draft/views/form_library/form_library_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const testScreenSize = Size(1133, 744);

  Widget buildTestApp(Widget child) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    );
  }

  group('FormLibrarySheet Widget Tests', () {
    testWidgets('renders all categories, search bar, and filters by search',
        (tester) async {
      tester.view.physicalSize = testScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ProceduralFormId? selectedId;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                FormLibrarySheet.show(
                  context: context,
                  theme: AppThemeTokens.dark(),
                  onSelectForm: (id) => selectedId = id,
                );
              },
              child: const Text('OPEN LIBRARY'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open library
      await tester.tap(find.text('OPEN LIBRARY'));
      await tester.pumpAndSettle();

      expect(find.text('PROCEDURAL FORM & ANATOMY LIBRARY'), findsOneWidget);
      expect(find.textContaining('All (23)'), findsOneWidget);
      expect(find.textContaining('2D Shapes'), findsOneWidget);
      expect(find.textContaining('Facial Features'), findsOneWidget);

      // Search for "eye"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'eye');
      await tester.pumpAndSettle();

      expect(find.text('3D Eyeball & Eyelid Shells'), findsOneWidget);
      expect(find.text('Perspective Cube / Voxel'), findsNothing);

      // Select eye card
      await tester.tap(find.text('3D Eyeball & Eyelid Shells'));
      await tester.pumpAndSettle();

      expect(selectedId, ProceduralFormId.eyeOrbit);
    });

    testWidgets('category filter chips isolate forms', (tester) async {
      tester.view.physicalSize = testScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(
          FormLibrarySheet(
            theme: AppThemeTokens.dark(),
            onSelectForm: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Limbs & Hands" chip
      await tester.tap(find.textContaining('Limbs & Hands'));
      await tester.pumpAndSettle();

      expect(find.text('Hand Spade & 5-Digit Rays'), findsOneWidget);
      expect(find.text('Arm Cylinders & Elbow Joint'), findsOneWidget);
      expect(find.text('Circle & Major Axes'), findsNothing);
    });
  });

  group('ProceduralFormDrill Studio Tests', () {
    testWidgets('renders controls, randomizes variant, and draws strokes',
        (tester) async {
      tester.view.physicalSize = testScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final profile = SkillProfile();

      await tester.pumpWidget(
        buildTestApp(
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
      await tester.pumpAndSettle();

      expect(find.text('3D Eyeball & Eyelid Shells'), findsWidgets);

      // Tap Randomize variant button
      final shuffleBtn = find.byTooltip('Randomize Pose / Perspective');
      expect(shuffleBtn, findsOneWidget);
      await tester.tap(shuffleBtn);
      await tester.pumpAndSettle();

      // Tap Yaw left/right buttons
      await tester.tap(find.byTooltip('Rotate Left'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Rotate Right'));
      await tester.pumpAndSettle();

      // Toggle Wireframe
      await tester.tap(find.byTooltip('Hide Cross-Contours'));
      await tester.pumpAndSettle();

      // Toggle Axes
      await tester.tap(find.byTooltip('Hide Axes'));
      await tester.pumpAndSettle();

      // Cycle guide opacity
      await tester.tap(find.textContaining('GUIDE:'));
      await tester.pumpAndSettle();

      // Draw a practice stroke on the canvas
      final gesture = await tester.startGesture(
        const Offset(500, 300),
        kind: PointerDeviceKind.mouse,
      );
      for (int i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(10, 5));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(profile.totalDrillsCompleted, 1);

      // Undo stroke
      final undoBtn = find.byTooltip('Undo Stroke');
      expect(undoBtn, findsOneWidget);
      await tester.tap(undoBtn, warnIfMissed: false);
      await tester.pumpAndSettle();
    });
  });
}
