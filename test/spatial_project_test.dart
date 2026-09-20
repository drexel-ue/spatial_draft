import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/models/stroke_point.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/services/project_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpatialProject Model Tests', () {
    test('JSON serialization & deserialization round-trip', () {
      final points = [
        const StrokePoint(
          position: Offset(120, 240),
          pressure: 0.65,
          timestampMicros: 1000,
        ),
        const StrokePoint(
          position: Offset(180, 320),
          pressure: 0.85,
          timestampMicros: 2000,
        ),
      ];

      final stroke = Stroke(
        points: points,
        color: const Color(0xFF00FFCC),
        lineWeight: LineWeightType.silhouette,
      );

      final project = SpatialProject(
        id: 'proj-001',
        title: 'Turbine Engine Draft',
        mode: SandboxMode.mentalCanvas3D,
        strokes: [stroke],
        zoomScale: 1.75,
        panOffsetX: 50.0,
        panOffsetY: -30.0,
        gridType: GridType.isometric,
        gridStyle: GridStyle.dashed,
        createdAt: DateTime(2026, 9, 19, 12, 0),
        updatedAt: DateTime(2026, 9, 19, 14, 30),
      );

      final json = project.toJson();
      final restored = SpatialProject.fromJson(json);

      expect(restored.id, 'proj-001');
      expect(restored.title, 'Turbine Engine Draft');
      expect(restored.mode, SandboxMode.mentalCanvas3D);
      expect(restored.strokes.length, 1);
      expect(
        restored.strokes.first.lineWeight,
        LineWeightType.silhouette,
      );
      expect(restored.strokes.first.points.length, 2);
      expect(restored.zoomScale, 1.75);
      expect(restored.panOffsetX, 50.0);
      expect(restored.panOffsetY, -30.0);
      expect(restored.gridType, GridType.isometric);
      expect(restored.gridStyle, GridStyle.dashed);
    });

    test('copyWith updates properties while retaining others', () {
      final original = SpatialProject(
        id: 'p-1',
        title: 'Original Title',
        mode: SandboxMode.vellum2D,
        createdAt: DateTime(2026, 9, 19),
        updatedAt: DateTime(2026, 9, 19),
      );

      final updated = original.copyWith(
        title: 'Renamed Title',
        mode: SandboxMode.infiniteZoom,
        zoomScale: 4.0,
      );

      expect(updated.id, 'p-1');
      expect(updated.title, 'Renamed Title');
      expect(updated.mode, SandboxMode.infiniteZoom);
      expect(updated.zoomScale, 4.0);
      expect(updated.createdAt, original.createdAt);
    });
  });

  group('ProjectService Persistence & Lifecycle Tests', () {
    late ProjectService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = ProjectService.instance;
      await service.init();
      await service.clearAll();
    });

    test('creates default starter draft when vault is empty', () async {
      await service.init();
      final projects = service.projectsNotifier.value;
      expect(projects.isNotEmpty, isTrue);
      expect(projects.first.title, contains('Welcome to Spatial Studio'));
    });

    test('create, rename, duplicate, and delete project', () async {
      // 1. Create
      final newProj = await service.createProject(
        title: 'Wing Spar Section',
        mode: SandboxMode.vellum2D,
      );
      expect(newProj.title, 'Wing Spar Section');
      expect(service.projectsNotifier.value.length, 1);

      // 2. Rename
      final renamed = await service.renameProject(
        newProj.id,
        'Wing Spar Section Rev B',
      );
      expect(renamed?.title, 'Wing Spar Section Rev B');

      final found = service.getProject(newProj.id);
      expect(found?.title, 'Wing Spar Section Rev B');

      // 3. Duplicate
      final copy = await service.duplicateProject(newProj.id);
      expect(copy, isNotNull);
      expect(copy!.title, 'Wing Spar Section Rev B (Copy)');
      expect(service.projectsNotifier.value.length, 2);

      // 4. Delete
      await service.deleteProject(newProj.id);
      expect(service.projectsNotifier.value.length, 1);
      expect(service.projectsNotifier.value.first.id, copy.id);
      expect(service.getProject(newProj.id), isNull);
    });

    test('auto-save updates existing project without duplicating', () async {
      final initial = await service.createProject(
        title: 'Auto Save Test',
        mode: SandboxMode.infiniteZoom,
      );

      final stroke = Stroke(
        points: const [
          StrokePoint(
            position: Offset(10, 10),
            pressure: 0.5,
            timestampMicros: 0,
          ),
        ],
        color: Colors.white,
      );

      final modified = initial.copyWith(
        strokes: [stroke],
        zoomScale: 2.5,
      );

      await service.saveProject(modified);

      expect(service.projectsNotifier.value.length, 1);
      final stored = service.getProject(initial.id);
      expect(stored!.strokes.length, 1);
      expect(stored.zoomScale, 2.5);
    });
  });
}
