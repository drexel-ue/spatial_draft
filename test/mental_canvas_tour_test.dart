import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/canvas/mental_canvas/'
    'mental_canvas_turntable_dock.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/models/spatial_bookmark.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/views/gallery/interactive_3d_html_exporter.dart';

void main() {
  group('Mental Canvas 3D Tour & Keyframes Tests', () {
    testWidgets('MentalCanvasTurntableDock keyframe menu and tour button',
        (tester) async {
      SpatialBookmark? selectedWaypoint;
      bool addKeyframeTapped = false;
      bool playTourTapped = false;

      final testWaypoints = [
        SpatialBookmark.waypoint3D(
          id: 'kf1',
          name: 'Front Overview',
          cameraYaw: 0.0,
          cameraPitch: 0.0,
          cameraDistance: 900.0,
        ),
        SpatialBookmark.waypoint3D(
          id: 'kf2',
          name: 'Dramatic Angle',
          cameraYaw: 1.2,
          cameraPitch: 0.4,
          cameraDistance: 1100.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MentalCanvasTurntableDock(
                theme: AppThemeTokens.blueprint(),
                planes: [CanvasPlane3D.primaryFront()],
                activePlaneId: 'plane_primary',
                cameraYaw: 0.0,
                cameraPitch: 0.0,
                onCameraChanged: (yaw, pitch) {},
                onSelectPlane: (_) {},
                onAddPlane: (_) {},
                onSnapToPlane: () {},
                onResetOrbit: () {},
                bookmarks: testWaypoints,
                onSelectBookmark: (b) => selectedWaypoint = b,
                onAddBookmark: () => addKeyframeTapped = true,
                onPlayTour: () => playTourTapped = true,
                isPlayingTour: false,
              ),
            ),
          ),
        ),
      );

      // Verify keyframe count indicator [ 🎬 2 ▾ ] exists
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.movie_creation_outlined), findsOneWidget);

      // Open storyboard keyframes popup
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(find.text('Front Overview'), findsOneWidget);
      expect(find.text('Dramatic Angle'), findsOneWidget);

      // Select keyframe
      await tester.tap(find.text('Dramatic Angle'));
      await tester.pumpAndSettle();
      expect(selectedWaypoint, isNotNull);
      expect(selectedWaypoint!.name, equals('Dramatic Angle'));

      // Tap + Keyframe button
      final addBtn = find.byTooltip('Add 3D Camera Keyframe');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      expect(addKeyframeTapped, isTrue);

      // Tap Play 3D Tour button
      final tourBtn = find.byTooltip('Play 3D Cinematic Tour');
      expect(tourBtn, findsOneWidget);
      await tester.tap(tourBtn);
      expect(playTourTapped, isTrue);
    });

    test('Interactive3dHtmlExporter embeds 3D waypoints and wash brush styles',
        () {
      final project = SpatialProject(
        id: 'proj_naruto',
        title: 'Chakra Awakening 3D',
        bookmarks: [
          SpatialBookmark.waypoint3D(
            id: 'kf1',
            name: 'Scene Intro',
            cameraYaw: 0.0,
            cameraPitch: 0.0,
            cameraDistance: 900.0,
          ),
          SpatialBookmark.waypoint3D(
            id: 'kf2',
            name: 'Aura Flyby',
            cameraYaw: 1.57,
            cameraPitch: 0.3,
            cameraDistance: 1200.0,
          ),
        ],
        strokes: [
          Stroke(
            points: [
              const StrokePoint(
                position: Offset(10, 10),
                timestampMicros: 0,
              ),
              const StrokePoint(
                position: Offset(20, 20),
                timestampMicros: 0,
              ),
            ],
            color: const Color(0xFFEF4444),
            brushStyle: LineBrushStyle.wash,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final html = Interactive3dHtmlExporter.generateHtml(project);

      expect(html, contains('Chakra Awakening 3D'));
      expect(html, contains('tourBtn'));
      expect(html, contains('Scene Intro'));
      expect(html, contains('Aura Flyby'));
      expect(html, contains("brushStyle === 'wash'"));
      expect(html, contains('tourLoop'));
    });
  });
}
