import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/views/gallery/interactive_3d_html_exporter.dart';

void main() {
  group('Interactive 3D HTML Exporter Tests', () {
    test(
      'generateHtml creates valid self-contained 3D Web document',
      () {
      final plane1 = CanvasPlane3D.primaryFront();
      final plane2 = CanvasPlane3D.groundFloor();

      final stroke = Stroke(
        planeId: plane1.id,
        color: Colors.white,
        lineWeight: LineWeightType.silhouette,
        points: const [
          StrokePoint(
            position: Offset(2000.0, 2000.0),
            pressure: 1.0,
            timestampMicros: 1000,
          ),
          StrokePoint(
            position: Offset(2100.0, 2050.0),
            pressure: 1.0,
            timestampMicros: 2000,
          ),
        ],
      );

      final project = SpatialProject(
        id: 'proj_3d_export',
        title: 'Cyberpunk Turbine Assembly',
        mode: SandboxMode.mentalCanvas3D,
        planes: [plane1, plane2],
        strokes: [stroke],
        cameraYaw: 0.45,
        cameraPitch: -0.25,
        cameraDistance: 1100.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final html = Interactive3dHtmlExporter.generateHtml(project);

      // Verify HTML boilerplate
      expect(html.contains('<!DOCTYPE html>'), isTrue);
      expect(html.contains('<html lang="en">'), isTrue);
      expect(html.contains('Cyberpunk Turbine Assembly'), isTrue);

      // Verify Canvas element and styles
      expect(html.contains('<canvas id="canvas"></canvas>'), isTrue);
      expect(html.contains('Auto Spin'), isTrue);
      expect(html.contains('Reset Camera'), isTrue);

      // Verify embedded 3D scene data
      expect(html.contains(plane1.id), isTrue);
      expect(html.contains(plane2.id), isTrue);
      expect(html.contains('cameraYaw = 0.45;'), isTrue);
      expect(html.contains('cameraPitch = -0.25;'), isTrue);
      expect(html.contains('cameraDist = 1100.0;'), isTrue);

      // Verify embedded script does not require CDN dependencies
      expect(html.contains('https://'), isFalse);
      expect(html.contains('http://'), isFalse);
    });
  });
}
