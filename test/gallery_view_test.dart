import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spatial_draft/core/models/draft_capture.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/main.dart';
import 'package:spatial_draft/services/gallery_service.dart';
import 'package:spatial_draft/views/gallery/gallery_screen.dart';

final Uint8List _testPngBytes = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const testScreenSize = Size(1133, 744);

  group('GalleryScreen Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GalleryService.instance.init();
      await GalleryService.instance.clearAll();
    });

    Widget buildTestApp(Widget child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: child,
      );
    }

    testWidgets('displays empty state when gallery has no captures',
        (tester) async {
      tester.view.physicalSize = testScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestApp(GalleryScreen(theme: AppThemeTokens.dark())),
      );
      await tester.pumpAndSettle();

      expect(find.text('DRAFT GALLERY'), findsOneWidget);
      expect(find.text('No Draft Snapshots Yet'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('renders capture cards, filters by tab, and opens detail dialog',
        (tester) async {
      tester.view.physicalSize = testScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seed captures
      final ghostingCapture = DraftCapture(
        id: 'cap_ghost',
        title: 'Line Quality Draft',
        drillMode: AppDrillMode.ghosting,
        themeMode: AppThemeMode.dark,
        gridStyle: GridStyle.solid,
        gridType: GridType.squareMetric,
        timestamp: DateTime(2026, 9, 19, 12),
        pngBytes: _testPngBytes,
        width: 1700,
        height: 1116,
      );

      final isometricCapture = DraftCapture(
        id: 'cap_iso',
        title: 'Isometric Billet Draft',
        drillMode: AppDrillMode.isometric,
        themeMode: AppThemeMode.blueprint,
        gridStyle: GridStyle.solid,
        gridType: GridType.isometric,
        timestamp: DateTime(2026, 9, 19, 13),
        pngBytes: _testPngBytes,
        width: 1700,
        height: 1116,
      );

      await GalleryService.instance.saveCapture(ghostingCapture);
      await GalleryService.instance.saveCapture(isometricCapture);

      await tester.pumpWidget(
        buildTestApp(GalleryScreen(theme: AppThemeTokens.dark())),
      );
      await tester.pumpAndSettle();

      // Verify both cards are visible in "All"
      expect(find.text('Line Quality Draft'), findsOneWidget);
      expect(find.text('Isometric Billet Draft'), findsOneWidget);

      // Tap Isometric filter chip
      await tester.tap(find.textContaining('Isometric (1)'));
      await tester.pumpAndSettle();

      // Only Isometric card is visible
      expect(find.text('Isometric Billet Draft'), findsOneWidget);
      expect(find.text('Line Quality Draft'), findsNothing);

      // Tap the card to open detail dialog
      await tester.tap(find.text('Isometric Billet Draft'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Pinch / Scroll to Zoom & Pan'), findsOneWidget);
      expect(find.text('1700 × 1116 px'), findsWidgets);

      // Close dialog
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Pinch / Scroll to Zoom & Pan'), findsNothing);
    });

    testWidgets(
        'DraftingStudioScreen capture button snapshots canvas into gallery',
        (tester) async {
      tester.view.physicalSize = testScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const SpatialDraftApp(autoShowOnboarding: false),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(GalleryService.instance.captures, isEmpty);

      // Tap the capture snapshot button in the top bar
      final captureBtn = find.byTooltip('Capture Canvas Snapshot');
      expect(captureBtn, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(captureBtn);
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should have saved a capture to GalleryService
      expect(GalleryService.instance.captures.length, 1);
      expect(find.textContaining('Snapshot saved to Gallery'), findsOneWidget);

      // Tap Draft Gallery button in top bar
      final galleryBtn = find.byTooltip('Draft Gallery');
      expect(galleryBtn, findsOneWidget);
      await tester.tap(galleryBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('DRAFT GALLERY'), findsOneWidget);
      expect(find.text('Line Quality Draft'), findsOneWidget);
    });
  });
}
