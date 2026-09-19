import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/canvas/procedural_forms/procedural_form_painter.dart';
import 'package:spatial_draft/canvas/procedural_forms/procedural_form_registry.dart';
import 'package:spatial_draft/core/models/procedural_form.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProceduralFormRegistry Tests', () {
    test('contains definitions for all ProceduralFormId values', () {
      final all = ProceduralFormRegistry.getAllDefinitions();
      expect(all.length, ProceduralFormId.values.length);

      for (final id in ProceduralFormId.values) {
        final def = ProceduralFormRegistry.getById(id);
        expect(def.id, id);
        expect(def.title.isNotEmpty, isTrue);
        expect(def.subtitle.isNotEmpty, isTrue);
        expect(def.draftingTip.isNotEmpty, isTrue);
        expect(def.anatomicalLandmarks.isNotEmpty, isTrue);
      }
    });

    test('filters definitions accurately by FormCategory', () {
      for (final cat in FormCategory.values) {
        final filtered = ProceduralFormRegistry.getDefinitionsByCategory(cat);
        expect(filtered.isNotEmpty, isTrue);
        for (final def in filtered) {
          expect(def.category, cat);
        }
      }
    });

    test('searches definitions by keyword query', () {
      // Search for "eye"
      final eyeMatches = ProceduralFormRegistry.search('eye');
      expect(eyeMatches.isNotEmpty, isTrue);
      expect(
        eyeMatches.any((d) => d.id == ProceduralFormId.eyeOrbit),
        isTrue,
      );

      // Search for "hand"
      final handMatches = ProceduralFormRegistry.search('hand');
      expect(handMatches.isNotEmpty, isTrue);
      expect(
        handMatches.any((d) => d.id == ProceduralFormId.handSpade),
        isTrue,
      );

      // Search for "cylinder"
      final cylinderMatches = ProceduralFormRegistry.search('cylinder');
      expect(cylinderMatches.isNotEmpty, isTrue);
      expect(
        cylinderMatches.any((d) => d.id == ProceduralFormId.cylinderAxle),
        isTrue,
      );

      // Empty query returns all
      expect(
        ProceduralFormRegistry.search('').length,
        ProceduralFormId.values.length,
      );
    });

    test('ProceduralFormConfig copyWith updates fields correctly', () {
      const config = ProceduralFormConfig();
      final updated = config.copyWith(
        yaw: 0.85,
        pitch: 0.45,
        scale: 1.5,
        showWireframe: false,
        showAxes: false,
      );

      expect(updated.yaw, 0.85);
      expect(updated.pitch, 0.45);
      expect(updated.scale, 1.5);
      expect(updated.showWireframe, isFalse);
      expect(updated.showAxes, isFalse);
      expect(updated.showBoundingBox, isTrue); // unchanged
    });
  });

  group('ProceduralFormPainter Tests', () {
    testWidgets('paints all 23 forms without throwing exceptions',
        (tester) async {
      final theme = AppThemeTokens.dark();

      for (final id in ProceduralFormId.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: CustomPaint(
                  painter: ProceduralFormPainter(
                    theme: theme,
                    formId: id,
                    config: const ProceduralFormConfig(
                      yaw: 0.4,
                      pitch: 0.3,
                      scale: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }
    });

    testWidgets('paints forms with wireframe and axes disabled',
        (tester) async {
      final theme = AppThemeTokens.blueprint();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: CustomPaint(
                painter: ProceduralFormPainter(
                  theme: theme,
                  formId: ProceduralFormId.eyeOrbit,
                  config: const ProceduralFormConfig(
                    showWireframe: false,
                    showAxes: false,
                    showBoundingBox: false,
                    showHiddenLines: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    });
  });
}
