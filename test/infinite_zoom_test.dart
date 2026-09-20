import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/canvas/infinite_zoom/infinite_zoom_hud.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

void main() {
  group('Infinite Zoom Engine Tests', () {
    test('formatMetricScale accurately converts scale to real units', () {
      // 0.0001 scale -> 10000m -> 10 km
      expect(InfiniteZoomHud.formatMetricScale(0.0001), equals('10 km'));

      // 0.001 scale -> 1000m -> 1 km
      expect(InfiniteZoomHud.formatMetricScale(0.001), equals('1.0 km'));

      // 1.0 scale -> 1 m
      expect(InfiniteZoomHud.formatMetricScale(1.0), equals('1.0 m'));

      // 10.0 scale -> 0.1m -> 10 cm
      expect(InfiniteZoomHud.formatMetricScale(10.0), equals('10 cm'));

      // 1000.0 scale -> 1 mm
      expect(InfiniteZoomHud.formatMetricScale(1000.0), equals('1.0 mm'));

      // 10000.0 scale -> 100 μm
      expect(InfiniteZoomHud.formatMetricScale(10000.0), equals('100 μm'));
    });

    test('formatMagnification formats readable multipliers', () {
      expect(InfiniteZoomHud.formatMagnification(0.5), equals('0.50×'));
      expect(InfiniteZoomHud.formatMagnification(1.0), equals('1.0×'));
      expect(InfiniteZoomHud.formatMagnification(15.4), equals('15×'));
      expect(InfiniteZoomHud.formatMagnification(1000.0), equals('1.0k×'));
      expect(InfiniteZoomHud.formatMagnification(12500.0), equals('13k×'));
    });

    testWidgets('InfiniteZoomHud renders scale readout and triggers callbacks',
        (tester) async {
      double selectedPreset = 0.0;
      double stepDelta = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteZoomHud(
              theme: AppThemeTokens.blueprint(),
              zoomScale: 1.0,
              onZoomPresetSelected: (val) => selectedPreset = val,
              onZoomStep: (factor) => stepDelta = factor,
              onResetZoom: () {},
            ),
          ),
        ),
      );

      // Verify scale bar and labels render
      expect(find.text('1.0 m'), findsOneWidget);
      expect(find.text('1.0×'), findsWidgets);
      expect(find.text('10×'), findsOneWidget);
      expect(find.text('100×'), findsOneWidget);
      expect(find.text('1000×'), findsOneWidget);

      // Tap preset 100×
      await tester.tap(find.text('100×'));
      await tester.pumpAndSettle();
      expect(selectedPreset, equals(100.0));

      // Tap Zoom In (+ button)
      final zoomInBtn = find.byTooltip('Zoom In (2.0×)');
      expect(zoomInBtn, findsOneWidget);
      await tester.tap(zoomInBtn);
      await tester.pumpAndSettle();
      expect(stepDelta, equals(2.0));

      // Tap Zoom Out (- button)
      final zoomOutBtn = find.byTooltip('Zoom Out (0.5×)');
      expect(zoomOutBtn, findsOneWidget);
      await tester.tap(zoomOutBtn);
      await tester.pumpAndSettle();
      expect(stepDelta, equals(0.5));
    });
  });
}
