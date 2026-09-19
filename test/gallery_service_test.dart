import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spatial_draft/core/models/app_drill_mode.dart';
import 'package:spatial_draft/core/models/draft_capture.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/services/gallery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GalleryService & DraftCapture Unit Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GalleryService.instance.init();
      await GalleryService.instance.clearAll();
    });

    test('DraftCapture JSON serialization and deserialization', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final capture = DraftCapture(
        id: 'capture_123',
        title: 'Ghosting Study #1',
        drillMode: AppDrillMode.ghosting,
        themeMode: AppThemeMode.blueprint,
        gridStyle: GridStyle.dotted,
        gridType: GridType.isometric,
        timestamp: DateTime(2026, 9, 19, 15, 30),
        pngBytes: bytes,
        width: 1200,
        height: 800,
      );

      final json = capture.toJson();
      final restored = DraftCapture.fromJson(json);

      expect(restored.id, 'capture_123');
      expect(restored.title, 'Ghosting Study #1');
      expect(restored.drillMode, AppDrillMode.ghosting);
      expect(restored.themeMode, AppThemeMode.blueprint);
      expect(restored.gridStyle, GridStyle.dotted);
      expect(restored.gridType, GridType.isometric);
      expect(restored.width, 1200);
      expect(restored.height, 800);
      expect(restored.pngBytes, equals(bytes));
      expect(restored.resolutionLabel, '1200 × 800 px');
      expect(restored.formattedDate, contains('Sep 19, 2026'));
    });

    test('saveCapture persists and updates capturesNotifier', () async {
      final capture1 = DraftCapture(
        id: '1',
        title: 'Draft 1',
        drillMode: AppDrillMode.ghosting,
        themeMode: AppThemeMode.dark,
        gridStyle: GridStyle.solid,
        gridType: GridType.squareMetric,
        timestamp: DateTime(2026, 9, 19, 10),
        pngBytes: Uint8List.fromList([10, 20]),
        width: 100,
        height: 100,
      );

      final capture2 = DraftCapture(
        id: '2',
        title: 'Draft 2',
        drillMode: AppDrillMode.ellipse,
        themeMode: AppThemeMode.light,
        gridStyle: GridStyle.dashed,
        gridType: GridType.perspective,
        timestamp: DateTime(2026, 9, 19, 11),
        pngBytes: Uint8List.fromList([30, 40]),
        width: 200,
        height: 200,
      );

      await GalleryService.instance.saveCapture(capture1);
      expect(GalleryService.instance.captures.length, 1);

      await GalleryService.instance.saveCapture(capture2);
      expect(GalleryService.instance.captures.length, 2);
      // Newest first
      expect(GalleryService.instance.captures.first.id, '2');

      // Reload service from simulated SharedPreferences
      await GalleryService.instance.init();
      expect(GalleryService.instance.captures.length, 2);
      expect(GalleryService.instance.captures.first.title, 'Draft 2');
    });

    test('deleteCapture removes specific item by ID', () async {
      final capture1 = DraftCapture(
        id: 'del_1',
        title: 'To Keep',
        drillMode: AppDrillMode.isometric,
        themeMode: AppThemeMode.dark,
        gridStyle: GridStyle.solid,
        gridType: GridType.isometric,
        timestamp: DateTime.now(),
        pngBytes: Uint8List(0),
        width: 100,
        height: 100,
      );

      final capture2 = DraftCapture(
        id: 'del_2',
        title: 'To Delete',
        drillMode: AppDrillMode.sandbox,
        themeMode: AppThemeMode.dark,
        gridStyle: GridStyle.solid,
        gridType: GridType.squareMetric,
        timestamp: DateTime.now(),
        pngBytes: Uint8List(0),
        width: 100,
        height: 100,
      );

      await GalleryService.instance.saveCapture(capture1);
      await GalleryService.instance.saveCapture(capture2);
      expect(GalleryService.instance.captures.length, 2);

      await GalleryService.instance.deleteCapture('del_2');
      expect(GalleryService.instance.captures.length, 1);
      expect(GalleryService.instance.captures.first.id, 'del_1');
    });

    test('clearAll removes all captures', () async {
      final capture = DraftCapture(
        id: 'c1',
        title: 'Draft',
        drillMode: AppDrillMode.poseGesture,
        themeMode: AppThemeMode.dark,
        gridStyle: GridStyle.solid,
        gridType: GridType.squareMetric,
        timestamp: DateTime.now(),
        pngBytes: Uint8List(0),
        width: 100,
        height: 100,
      );

      await GalleryService.instance.saveCapture(capture);
      expect(GalleryService.instance.captures.length, 1);

      await GalleryService.instance.clearAll();
      expect(GalleryService.instance.captures, isEmpty);
    });
  });
}
