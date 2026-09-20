import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';

void main() {
  group('CanvasPlane3D Model Tests', () {
    test('Default templates instantiate with expected spatial properties', () {
      final front = CanvasPlane3D.primaryFront();
      expect(front.id, equals('plane_primary'));
      expect(front.yaw, equals(0.0));
      expect(front.pitch, equals(0.0));
      expect(front.originZ, equals(0.0));

      final ground = CanvasPlane3D.groundFloor();
      expect(ground.id, equals('plane_ground'));
      expect(ground.pitch, closeTo(math.pi / 2.0, 1e-4));
      expect(ground.originY, equals(450.0));

      final left = CanvasPlane3D.leftWall();
      expect(left.id, equals('plane_wall_left'));
      expect(left.yaw, closeTo(math.pi / 2.0, 1e-4));
      expect(left.originX, equals(-450.0));

      final right = CanvasPlane3D.rightWall();
      expect(right.id, equals('plane_wall_right'));
      expect(right.yaw, closeTo(-math.pi / 2.0, 1e-4));
      expect(right.originX, equals(450.0));

      final back = CanvasPlane3D.backdrop();
      expect(back.id, equals('plane_backdrop'));
      expect(back.originZ, equals(-600.0));
    });

    test('2D to 3D and 3D to 2D projection roundtrip preserves coordinates',
        () {
      final front = CanvasPlane3D.primaryFront();
      const p2D = Offset(150.0, -220.0);
      final p3D = front.project2Dto3D(p2D);
      expect(p3D[0], closeTo(150.0, 1e-3));
      expect(p3D[1], closeTo(-220.0, 1e-3));
      expect(p3D[2], closeTo(0.0, 1e-3));

      final restored = front.project3Dto2D(p3D[0], p3D[1], p3D[2]);
      expect(restored.dx, closeTo(p2D.dx, 1e-3));
      expect(restored.dy, closeTo(p2D.dy, 1e-3));

      // Test angled plane
      final ground = CanvasPlane3D.groundFloor();
      const groundUV = Offset(80.0, 120.0);
      final ground3D = ground.project2Dto3D(groundUV);
      final restoredGround = ground.project3Dto2D(
        ground3D[0],
        ground3D[1],
        ground3D[2],
      );
      expect(restoredGround.dx, closeTo(groundUV.dx, 1e-3));
      expect(restoredGround.dy, closeTo(groundUV.dy, 1e-3));
    });

    test('intersectRay computes exact plane intersection point', () {
      final front = CanvasPlane3D.primaryFront();
      const screenSize = Size(800, 600);

      // Center ray at (400, 300) should hit plane origin (0, 0)
      final centerHit = front.intersectRay(
        screenPos: const Offset(400, 300),
        screenSize: screenSize,
        cameraYaw: 0.0,
        cameraPitch: 0.0,
        cameraDistance: 900.0,
      );
      expect(centerHit, isNotNull);
      expect(centerHit!.dx, closeTo(0.0, 1e-2));
      expect(centerHit.dy, closeTo(0.0, 1e-2));

      // Off-center ray at (500, 350)
      final offsetHit = front.intersectRay(
        screenPos: const Offset(500, 350),
        screenSize: screenSize,
        cameraYaw: 0.0,
        cameraPitch: 0.0,
        cameraDistance: 900.0,
      );
      expect(offsetHit, isNotNull);
      expect(offsetHit!.dx, closeTo(100.0, 1e-2));
      expect(offsetHit.dy, closeTo(50.0, 1e-2));

      // Ray parallel to plane should return null
      const parallelPlane = CanvasPlane3D(
        id: 'plane_horiz',
        name: 'Horizontal Test Plane',
        originY: 0.0,
        pitch: math.pi / 2.0, // facing down, ray travels along Z
      );
      final parallelHit = parallelPlane.intersectRay(
        screenPos: const Offset(400, 300),
        screenSize: screenSize,
        cameraYaw: 0.0,
        cameraPitch: 0.0,
        cameraDistance: 900.0,
      );
      expect(parallelHit, isNull);
    });

    test('toJson and fromJson preserves all plane metadata', () {
      const plane = CanvasPlane3D(
        id: 'plane_custom_test',
        name: 'Custom CAD Slice',
        originX: 120.0,
        originY: -45.0,
        originZ: 330.0,
        yaw: 0.785,
        pitch: 0.35,
        roll: 0.1,
        width: 3200.0,
        height: 2400.0,
        colorValue: 0xFF38BDF8,
        opacity: 0.9,
        isLocked: true,
      );

      final json = plane.toJson();
      final restored = CanvasPlane3D.fromJson(json);

      expect(restored.id, equals('plane_custom_test'));
      expect(restored.name, equals('Custom CAD Slice'));
      expect(restored.originX, equals(120.0));
      expect(restored.originY, equals(-45.0));
      expect(restored.originZ, equals(330.0));
      expect(restored.yaw, equals(0.785));
      expect(restored.pitch, equals(0.35));
      expect(restored.roll, equals(0.1));
      expect(restored.width, equals(3200.0));
      expect(restored.height, equals(2400.0));
      expect(restored.colorValue, equals(0xFF38BDF8));
      expect(restored.opacity, equals(0.9));
      expect(restored.isLocked, isTrue);
    });

    test('copyWith properly overrides designated attributes', () {
      final base = CanvasPlane3D.primaryFront();
      final updated = base.copyWith(
        name: 'Renamed Elevation Plane',
        isLocked: true,
        originZ: -150.0,
      );

      expect(updated.id, equals(base.id));
      expect(updated.name, equals('Renamed Elevation Plane'));
      expect(updated.isLocked, isTrue);
      expect(updated.originZ, equals(-150.0));
      expect(updated.originX, equals(base.originX));
    });
  });
}
