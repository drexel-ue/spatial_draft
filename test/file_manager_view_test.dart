import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/core/widgets/rename_project_dialog.dart';
import 'package:spatial_draft/services/project_service.dart';
import 'package:spatial_draft/views/gallery/gallery_screen.dart';
import 'package:spatial_draft/views/gallery/project_export_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProjectService.instance.init();
    await ProjectService.instance.clearAll();
  });

  group('Draft Vault & File Manager Widget Tests', () {
    testWidgets('renders Projects tab and lists saved project cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await ProjectService.instance.createProject(
        title: 'Turbine Housing Assembly',
        mode: SandboxMode.mentalCanvas3D,
      );

      final theme = AppThemeTokens.dark();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GalleryScreen(
              theme: theme,
              initialTab: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('PROJECTS'), findsOneWidget);
      expect(find.textContaining('SNAPSHOTS'), findsOneWidget);
      expect(find.text('Turbine Housing Assembly'), findsOneWidget);
      expect(find.text('3D Spatial'), findsWidgets);
    });

    testWidgets('search query filters visible project cards', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await ProjectService.instance.createProject(
        title: 'Hydraulic Actuator',
        mode: SandboxMode.vellum2D,
      );
      await ProjectService.instance.createProject(
        title: 'Avionics Dashboard',
        mode: SandboxMode.infiniteZoom,
      );

      final theme = AppThemeTokens.dark();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GalleryScreen(
              theme: theme,
              initialTab: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hydraulic Actuator'), findsOneWidget);
      expect(find.text('Avionics Dashboard'), findsOneWidget);

      // Enter search query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'hydraulic');
      await tester.pumpAndSettle();

      expect(find.text('Hydraulic Actuator'), findsOneWidget);
      expect(find.text('Avionics Dashboard'), findsNothing);
    });

    testWidgets('RenameProjectDialog allows renaming and tag appending', (
      tester,
    ) async {
      final theme = AppThemeTokens.dark();
      String? updatedTitle;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  updatedTitle = await RenameProjectDialog.show(
                    context: context,
                    currentTitle: 'Base Model',
                    theme: theme,
                  );
                },
                child: const Text('Open Rename'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Rename Project'), findsOneWidget);
      expect(find.text('Base Model'), findsOneWidget);

      // Tap + Study quick tag chip
      await tester.tap(find.text('+ Study'));
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Save Name'));
      await tester.pumpAndSettle();

      expect(updatedTitle, 'Base Model - Study');
    });

    testWidgets('ProjectExportDialog renders SVG and Spatial options', (
      tester,
    ) async {
      final theme = AppThemeTokens.dark();
      final project = SpatialProject(
        id: 'export-test-1',
        title: 'Bracket CAD Model',
        mode: SandboxMode.vellum2D,
        createdAt: DateTime(2026, 9, 19),
        updatedAt: DateTime(2026, 9, 19),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ProjectExportDialog.show(
                    context: context,
                    project: project,
                    theme: theme,
                  );
                },
                child: const Text('Open Export'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Export'));
      await tester.pumpAndSettle();

      expect(find.text('Export Draft Document'), findsOneWidget);
      expect(find.text('Vector SVG (.svg)'), findsOneWidget);
      expect(find.text('Native Project (.spatial)'), findsOneWidget);
      expect(find.text('Copy File Code'), findsOneWidget);
    });
  });
}
