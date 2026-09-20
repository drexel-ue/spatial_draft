import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/canvas/infinite_zoom/infinite_zoom_hud.dart';
import 'package:spatial_draft/core/models/spatial_bookmark.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

void main() {
  group('SpatialBookmark Model & Fly-Through Tests', () {
    test(
      'SpatialBookmark creates, serializes, and deserializes accurately',
      () {
      final now = DateTime.now();
      final bookmark = SpatialBookmark(
        id: 'bm_test_1',
        name: 'Microscopic Circuit Core',
        zoomScale: 250.0,
        panOffsetX: -400.0,
        panOffsetY: 350.0,
        createdAt: now,
      );

      final json = bookmark.toJson();
      expect(json['id'], equals('bm_test_1'));
      expect(json['name'], equals('Microscopic Circuit Core'));
      expect(json['zoomScale'], equals(250.0));
      expect(json['panOffsetX'], equals(-400.0));
      expect(json['panOffsetY'], equals(350.0));
      expect(json['createdAt'], equals(now.toIso8601String()));

      final recovered = SpatialBookmark.fromJson(json);
      expect(recovered.id, equals(bookmark.id));
      expect(recovered.name, equals(bookmark.name));
      expect(recovered.zoomScale, equals(bookmark.zoomScale));
      expect(recovered.panOffsetX, equals(bookmark.panOffsetX));
      expect(recovered.panOffsetY, equals(bookmark.panOffsetY));
    });

    test('SpatialBookmark copyWith updates fields selectively', () {
      final bookmark = SpatialBookmark(
        id: 'bm_1',
        name: 'Overview',
        zoomScale: 1.0,
        createdAt: DateTime.now(),
      );

      final updated = bookmark.copyWith(
        name: 'Detailed Schematic',
        zoomScale: 50.0,
      );

      expect(updated.id, equals('bm_1'));
      expect(updated.name, equals('Detailed Schematic'));
      expect(updated.zoomScale, equals(50.0));
      expect(updated.panOffsetX, equals(0.0));
    });

    test('SpatialProject persists and deserializes bookmark lists', () {
      final bm1 = SpatialBookmark(
        id: 'bm_overview',
        name: 'Overview Stage',
        zoomScale: 1.0,
        createdAt: DateTime.now(),
      );
      final bm2 = SpatialBookmark(
        id: 'bm_detail',
        name: 'Fine Detailing',
        zoomScale: 500.0,
        createdAt: DateTime.now(),
      );

      final project = SpatialProject(
        id: 'proj_bm_test',
        title: 'Bookmark Suite',
        bookmarks: [bm1, bm2],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = project.toJson();
      final restored = SpatialProject.fromJson(json);

      expect(restored.bookmarks.length, equals(2));
      expect(restored.bookmarks[0].name, equals('Overview Stage'));
      expect(restored.bookmarks[1].zoomScale, equals(500.0));
    });

    test('Logarithmic zoom interpolation produces uniform perceptual velocity',
        () {
      const s0 = 1.0;
      const s1 = 1000.0;

      // At t = 0.5, linear would yield 500.5 (rush at the end)
      // Logarithmic yields exp((0 + ln(1000))/2) = sqrt(1000) ~ 31.62
      final midScale = math.exp(
        math.log(s0) + 0.5 * (math.log(s1) - math.log(s0)),
      );
      expect(midScale, closeTo(31.622, 0.01));
    });

    testWidgets('InfiniteZoomHud renders bookmark chips and handles tap',
        (tester) async {
      SpatialBookmark? selectedBookmark;
      bool addTapped = false;

      final testBookmarks = [
        SpatialBookmark(
          id: 'b1',
          name: 'Engine Bay',
          zoomScale: 10.0,
          createdAt: DateTime.now(),
        ),
        SpatialBookmark(
          id: 'b2',
          name: 'Piston Pin',
          zoomScale: 1000.0,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteZoomHud(
              theme: AppThemeTokens.blueprint(),
              zoomScale: 1.0,
              bookmarks: testBookmarks,
              onZoomPresetSelected: (_) {},
              onZoomStep: (_) {},
              onResetZoom: () {},
              onSelectBookmark: (b) => selectedBookmark = b,
              onAddBookmark: () => addTapped = true,
            ),
          ),
        ),
      );

      // Verify bookmark count indicator [ 🔖 2 ▾ ] and Add button exist
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_added_rounded), findsOneWidget);

      // Open bookmarks menu
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // Verify menu items appear
      expect(find.text('Engine Bay'), findsOneWidget);
      expect(find.text('Piston Pin'), findsOneWidget);

      // Tap first bookmark
      await tester.tap(find.text('Engine Bay'));
      await tester.pumpAndSettle();

      expect(selectedBookmark, isNotNull);
      expect(selectedBookmark!.id, equals('b1'));

      // Tap + Bookmark button
      final addBtn = find.byTooltip('Bookmark Current Scale (Waypoint)');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      expect(addTapped, isTrue);
    });
  });
}
