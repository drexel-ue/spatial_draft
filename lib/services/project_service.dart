import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/services/app_log_service.dart';

/// Persistent service managing saved editable drafting projects.
class ProjectService {
  ProjectService._();

  /// Shared singleton instance of [ProjectService].
  static final ProjectService instance = ProjectService._();

  static const String _storageKey = 'spatial_draft_projects_v1';
  static const int _maxProjects = 60;

  SharedPreferences? _prefs;

  /// ValueNotifier emitting the latest list of [SpatialProject]s, newest first.
  final ValueNotifier<List<SpatialProject>> projectsNotifier =
      ValueNotifier<List<SpatialProject>>(<SpatialProject>[]);

  /// Returns current list of projects.
  List<SpatialProject> get projects => projectsNotifier.value;

  /// Initializes the service and loads persisted projects from storage.
  Future<void> init({SharedPreferences? prefs}) async {
    try {
      _prefs = prefs ?? await SharedPreferences.getInstance();
      final jsonString = _prefs?.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final dynamic decoded = jsonDecode(jsonString);
        if (decoded is List) {
          final loaded = decoded
              .whereType<Map<String, dynamic>>()
              .map(SpatialProject.fromJson)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          projectsNotifier.value = loaded;
        }
      }

      // If storage is completely empty, create an initial starter project
      if (projectsNotifier.value.isEmpty) {
        await _seedDefaultProject();
      }

      AppLogService.instance.info(
        'PROJECTS',
        'ProjectService initialized with ${projects.length} projects',
      );
    } catch (e, stack) {
      AppLogService.instance.error(
        'PROJECTS',
        'Failed to initialize ProjectService: $e',
        stackTrace: stack,
      );
    }
  }

  Future<void> _seedDefaultProject() async {
    final now = DateTime.now();
    final defaultProject = SpatialProject(
      id: 'proj_starter_default',
      title: 'Welcome to Spatial Studio',
      mode: SandboxMode.vellum2D,
      createdAt: now,
      updatedAt: now,
      gridType: GridType.squareMetric,
      gridStyle: GridStyle.solid,
    );
    projectsNotifier.value = [defaultProject];
    await _persist([defaultProject]);
  }

  /// Creates a new [SpatialProject] and persists it.
  Future<SpatialProject> createProject({
    String? title,
    SandboxMode mode = SandboxMode.vellum2D,
    GridType gridType = GridType.squareMetric,
    GridStyle gridStyle = GridStyle.solid,
  }) async {
    final now = DateTime.now();
    final cleanTitle = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : 'Spatial Draft #${projects.length + 1}';

    final project = SpatialProject(
      id: 'proj_${now.microsecondsSinceEpoch}',
      title: cleanTitle,
      mode: mode,
      createdAt: now,
      updatedAt: now,
      gridType: gridType,
      gridStyle: gridStyle,
    );

    final current = List<SpatialProject>.from(projectsNotifier.value)
      ..insert(0, project);

    if (current.length > _maxProjects) {
      current.removeRange(_maxProjects, current.length);
    }

    projectsNotifier.value = current;
    await _persist(current);

    AppLogService.instance.info(
      'PROJECTS',
      'Created project "${project.title}" (${project.id})',
    );
    return project;
  }

  /// Saves updates to an existing [SpatialProject].
  Future<void> saveProject(SpatialProject project) async {
    try {
      final now = DateTime.now();
      final updatedProject = project.copyWith(updatedAt: now);

      final current = List<SpatialProject>.from(projectsNotifier.value);
      final index = current.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        current[index] = updatedProject;
      } else {
        current.insert(0, updatedProject);
      }

      // Keep sorted by updatedAt descending
      current.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (current.length > _maxProjects) {
        current.removeRange(_maxProjects, current.length);
      }

      projectsNotifier.value = current;
      await _persist(current);

      AppLogService.instance.debug(
        'PROJECTS',
        'Saved project "${project.title}" (${project.strokes.length} strokes)',
      );
    } catch (e, stack) {
      AppLogService.instance.error(
        'PROJECTS',
        'Failed to save project ${project.id}: $e',
        stackTrace: stack,
      );
    }
  }

  /// Renames a project by its [id] with sanitized title.
  Future<SpatialProject?> renameProject(String id, String newTitle) async {
    final cleanTitle = newTitle.trim();
    if (cleanTitle.isEmpty) return null;

    final current = List<SpatialProject>.from(projectsNotifier.value);
    final index = current.indexWhere((p) => p.id == id);
    if (index == -1) return null;

    final updated = current[index].copyWith(
      title: cleanTitle,
      updatedAt: DateTime.now(),
    );

    current[index] = updated;
    projectsNotifier.value = current;
    await _persist(current);

    AppLogService.instance.info(
      'PROJECTS',
      'Renamed project "$id" to "$cleanTitle"',
    );
    return updated;
  }

  /// Clones an existing project by [id] with a `" (Copy)"` suffix.
  Future<SpatialProject?> duplicateProject(String id) async {
    final original = getProject(id);
    if (original == null) return null;

    final now = DateTime.now();
    final cloned = original.copyWith(
      id: 'proj_${now.microsecondsSinceEpoch}',
      title: '${original.title} (Copy)',
      createdAt: now,
      updatedAt: now,
    );

    final current = List<SpatialProject>.from(projectsNotifier.value)
      ..insert(0, cloned);

    if (current.length > _maxProjects) {
      current.removeRange(_maxProjects, current.length);
    }

    projectsNotifier.value = current;
    await _persist(current);

    AppLogService.instance.info(
      'PROJECTS',
      'Duplicated project "${original.title}" -> "${cloned.title}"',
    );
    return cloned;
  }

  /// Deletes a project by its unique [id].
  Future<void> deleteProject(String id) async {
    try {
      final current = List<SpatialProject>.from(projectsNotifier.value)
        ..removeWhere((p) => p.id == id);
      projectsNotifier.value = current;
      await _persist(current);

      AppLogService.instance.info('PROJECTS', 'Deleted project with ID: $id');
    } catch (e, stack) {
      AppLogService.instance.error(
        'PROJECTS',
        'Failed to delete project $id: $e',
        stackTrace: stack,
      );
    }
  }

  /// Retrieves a project by [id].
  SpatialProject? getProject(String id) {
    try {
      return projectsNotifier.value.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clears all projects (primarily for test resets).
  Future<void> clearAll() async {
    projectsNotifier.value = <SpatialProject>[];
    await _prefs?.remove(_storageKey);
  }

  Future<void> _persist(List<SpatialProject> items) async {
    final jsonList = items.map((p) => p.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs?.setString(_storageKey, jsonString);
  }
}
