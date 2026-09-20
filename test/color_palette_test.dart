import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/canvas/common/color_palette_dock.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

void main() {
  group('LineBrushStyle & Cel-Shading Model Tests', () {
    test('LineBrushStyle multipliers are correctly defined', () {
      expect(LineBrushStyle.ink.opacityMultiplier, equals(1.0));
      expect(LineBrushStyle.ink.widthMultiplier, equals(1.0));
      expect(LineBrushStyle.ink.label, equals('Ink Outline'));

      expect(LineBrushStyle.wash.opacityMultiplier, equals(0.35));
      expect(LineBrushStyle.wash.widthMultiplier, equals(3.2));
      expect(LineBrushStyle.wash.label, equals('Cel Wash'));
    });

    test('Stroke serializes and recovers brushStyle faithfully', () {
      final stroke = Stroke(
        points: [
          const StrokePoint(
            position: Offset(10, 20),
            pressure: 0.8,
            timestampMicros: 0,
          ),
        ],
        color: const Color(0xFFEF4444),
        lineWeight: LineWeightType.crease,
        brushStyle: LineBrushStyle.wash,
        planeId: 'plane_naruto',
      );

      final json = stroke.toJson();
      expect(json['brushStyle'], equals('wash'));
      expect(json['planeId'], equals('plane_naruto'));

      final recovered = Stroke.fromJson(json);
      expect(recovered.brushStyle, equals(LineBrushStyle.wash));
      expect(recovered.planeId, equals('plane_naruto'));
      expect(recovered.color.value, equals(0xFFEF4444));
    });
  });

  group('ColorPaletteDock Widget Tests', () {
    testWidgets('Renders swatches, handles color and brush style selection',
        (tester) async {
      Color selectedColor = const Color(0xFF0F172A);
      LineBrushStyle selectedBrush = LineBrushStyle.ink;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: ColorPaletteDock(
                    theme: AppThemeTokens.blueprint(),
                    selectedColor: selectedColor,
                    onColorSelected: (c) => setState(() => selectedColor = c),
                    selectedBrushStyle: selectedBrush,
                    onBrushStyleChanged: (b) =>
                        setState(() => selectedBrush = b),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify ink and wash toggle buttons
      expect(find.text('Ink'), findsOneWidget);
      expect(find.text('Wash'), findsOneWidget);

      // Tap 'Wash' button
      await tester.tap(find.text('Wash'));
      await tester.pumpAndSettle();
      expect(selectedBrush, equals(LineBrushStyle.wash));

      // Tap 'Ink' button
      await tester.tap(find.text('Ink'));
      await tester.pumpAndSettle();
      expect(selectedBrush, equals(LineBrushStyle.ink));

      // Verify swatch count (8 curated colors + 2 style buttons = 10)
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsNWidgets(10));

      // Tap the third swatch (Electric Cyan 0xFF00E5FF, index 2+2=4)
      await tester.tap(inkWells.at(4));
      await tester.pumpAndSettle();
      expect(selectedColor, equals(const Color(0xFF00E5FF)));
    });
  });
}
