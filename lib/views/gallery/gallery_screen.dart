import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spatial_draft/core/models/app_drill_mode.dart';
import 'package:spatial_draft/core/models/draft_capture.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/core/widgets/rename_project_dialog.dart';
import 'package:spatial_draft/services/gallery_service.dart';
import 'package:spatial_draft/services/project_service.dart';
import 'package:spatial_draft/views/gallery/project_export_dialog.dart';

/// Screen displaying user drafting projects and snapshot archive.
class GalleryScreen extends StatefulWidget {
  /// Creates a [GalleryScreen].
  const GalleryScreen({
    super.key,
    required this.theme,
    this.initialTab = 1,
    this.onSelectProject,
  });

  /// Theme design tokens.
  final AppThemeTokens theme;

  /// Initial active tab (0 for Projects, 1 for Snapshots).
  final int initialTab;

  /// Callback when a project is selected to open in studio.
  final ValueChanged<SpatialProject>? onSelectProject;

  /// Convenience route navigator.
  static void open({
    required BuildContext context,
    required AppThemeTokens theme,
    int initialTab = 1,
    ValueChanged<SpatialProject>? onSelectProject,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GalleryScreen(
          theme: theme,
          initialTab: initialTab,
          onSelectProject: onSelectProject,
        ),
      ),
    );
  }

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  AppDrillMode? _filterMode;
  SandboxMode? _projectModeFilter;
  final TextEditingController _projectSearchController =
      TextEditingController();
  String _projectQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(() => setState(() {}));
    _projectSearchController.addListener(() {
      setState(() {
        _projectQuery = _projectSearchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _projectSearchController.dispose();
    super.dispose();
  }

  Future<void> _createNewProject() async {
    final theme = widget.theme;
    final nextNum = ProjectService.instance.projects.length + 1;
    final title = await RenameProjectDialog.show(
      context: context,
      currentTitle: 'Spatial Draft #$nextNum',
      theme: theme,
      dialogTitle: 'New Drafting Project',
    );

    if (title != null && title.trim().isNotEmpty) {
      final proj = await ProjectService.instance.createProject(
        title: title.trim(),
        mode: _projectModeFilter ?? SandboxMode.vellum2D,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Created project "${proj.title}"'),
          backgroundColor: theme.borderHighlight,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (widget.onSelectProject != null) {
        Navigator.of(context).pop();
        widget.onSelectProject!(proj);
      }
    }
  }

  void _openProject(SpatialProject project) {
    if (widget.onSelectProject != null) {
      Navigator.of(context).pop();
      widget.onSelectProject!(project);
    } else {
      Navigator.of(context).pop(project);
    }
  }

  Future<void> _renameProject(SpatialProject project) async {
    final theme = widget.theme;
    final newTitle = await RenameProjectDialog.show(
      context: context,
      currentTitle: project.title,
      theme: theme,
      dialogTitle: 'Rename Draft',
    );

    if (newTitle != null && newTitle != project.title) {
      final updated = await ProjectService.instance.renameProject(
        project.id,
        newTitle,
      );
      if (updated != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Renamed draft to "$newTitle"'),
            backgroundColor: theme.borderHighlight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _duplicateProject(SpatialProject project) async {
    final theme = widget.theme;
    final cloned =
        await ProjectService.instance.duplicateProject(project.id);
    if (cloned != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Duplicated "${project.title}"'),
          backgroundColor: theme.borderHighlight,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _exportProject(SpatialProject project) {
    ProjectExportDialog.show(
      context: context,
      project: project,
      theme: widget.theme,
    );
  }

  Future<void> _deleteProject(SpatialProject project) async {
    final theme = widget.theme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderSubtle),
        ),
        title: Text(
          'Delete Project?',
          style: theme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${project.title}"?',
          style: theme.bodyStyle.copyWith(color: theme.secondaryInk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: theme.bodyStyle.copyWith(color: theme.secondaryInk),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: theme.headingStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ProjectService.instance.deleteProject(project.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Deleted project "${project.title}"'),
            backgroundColor: theme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openDetail(DraftCapture capture) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _DraftDetailDialog(
        capture: capture,
        theme: widget.theme,
        onDelete: () async {
          Navigator.of(ctx).pop();
          await _deleteCaptureWithNotice(capture);
        },
      ),
    );
  }

  Future<void> _deleteCaptureWithNotice(DraftCapture capture) async {
    final theme = widget.theme;
    await GalleryService.instance.deleteCapture(capture.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Deleted snapshot "${capture.title}"'),
        backgroundColor: theme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final theme = widget.theme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.borderSubtle),
        ),
        title: Text(
          'Clear All Captures?',
          style: theme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'This will permanently remove all archived snapshots from your '
          'device.',
          style: theme.bodyStyle.copyWith(color: theme.secondaryInk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: theme.bodyStyle.copyWith(color: theme.secondaryInk),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete All',
              style: theme.headingStyle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GalleryService.instance.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Cleared all gallery snapshots'),
            backgroundColor: widget.theme.accentCyan,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.canvasBackground,
      appBar: AppBar(
        backgroundColor: theme.surfaceBackground,
        foregroundColor: theme.defaultInk,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DRAFT GALLERY',
                  style: theme.headingStyle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.borderHighlight.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.borderHighlight.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    'VAULT',
                    style: theme.monoStyle.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: theme.borderHighlight,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Project File Manager & Kinematic Snapshots',
              style: theme.monoStyle.copyWith(
                fontSize: 10,
                color: theme.secondaryInk,
              ),
            ),
          ],
        ),
        actions: [
          if (_tabController.index == 0) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.borderHighlight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'New Draft',
                style: theme.headingStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onPressed: _createNewProject,
            ),
            const SizedBox(width: 12),
          ] else ...[
            ValueListenableBuilder<List<DraftCapture>>(
              valueListenable: GalleryService.instance.capturesNotifier,
              builder: (ctx, captures, _) {
                if (captures.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Clear All Captures',
                  icon: Icon(
                    Icons.delete_sweep_outlined,
                    color: theme.danger,
                    size: 22,
                  ),
                  onPressed: _confirmClearAll,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.borderHighlight,
          indicatorWeight: 3,
          labelColor: theme.defaultInk,
          unselectedLabelColor: theme.secondaryInk,
          labelStyle: theme.headingStyle.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            ValueListenableBuilder<List<SpatialProject>>(
              valueListenable: ProjectService.instance.projectsNotifier,
              builder: (ctx, projects, _) => Tab(
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                text: 'PROJECTS (${projects.length})',
              ),
            ),
            ValueListenableBuilder<List<DraftCapture>>(
              valueListenable: GalleryService.instance.capturesNotifier,
              builder: (ctx, captures, _) => Tab(
                icon: const Icon(Icons.collections_rounded, size: 18),
                text: 'SNAPSHOTS (${captures.length})',
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildProjectsTab(theme),
            _buildSnapshotsTab(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsTab(AppThemeTokens theme) {
    return Column(
      children: [
        // Project Search & Filter Bar
        Container(
          color: theme.surfaceBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _projectSearchController,
                    style: theme.bodyStyle.copyWith(
                      fontSize: 13,
                      color: theme.defaultInk,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search projects by name...',
                      hintStyle: TextStyle(
                        color: theme.secondaryInk.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: theme.secondaryInk,
                        size: 18,
                      ),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: theme.canvasBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: theme.borderHighlight,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildProjectModeFilterChip(
                label: 'All',
                isSelected: _projectModeFilter == null,
                theme: theme,
                onTap: () => setState(() => _projectModeFilter = null),
              ),
              for (final mode in SandboxMode.values)
                _buildProjectModeFilterChip(
                  label: mode.shortLabel,
                  isSelected: _projectModeFilter == mode,
                  theme: theme,
                  icon: mode.icon,
                  onTap: () => setState(() => _projectModeFilter = mode),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.borderSubtle),

        // Projects Grid
        Expanded(
          child: ValueListenableBuilder<List<SpatialProject>>(
            valueListenable: ProjectService.instance.projectsNotifier,
            builder: (ctx, projects, _) {
              final filtered = projects.where((p) {
                final matchesMode = _projectModeFilter == null ||
                    p.mode == _projectModeFilter;
                final matchesQuery = _projectQuery.isEmpty ||
                    p.title.toLowerCase().contains(_projectQuery);
                return matchesMode && matchesQuery;
              }).toList();

              if (filtered.isEmpty) {
                return _buildProjectsEmptyState(theme, projects.isNotEmpty);
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.15,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, index) {
                  final project = filtered[index];
                  return _ProjectCard(
                    project: project,
                    theme: theme,
                    onOpen: () => _openProject(project),
                    onRename: () => _renameProject(project),
                    onDuplicate: () => _duplicateProject(project),
                    onExport: () => _exportProject(project),
                    onDelete: () => _deleteProject(project),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProjectModeFilterChip({
    required String label,
    required bool isSelected,
    required AppThemeTokens theme,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.borderHighlight.withOpacity(0.18)
                : theme.canvasBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.borderHighlight
                  : theme.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? theme.borderHighlight
                      : theme.secondaryInk,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.monoStyle.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.borderHighlight
                      : theme.secondaryInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsEmptyState(
    AppThemeTokens theme,
    bool hasOtherProjects,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.borderHighlight.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: theme.borderSubtle),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: theme.borderHighlight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasOtherProjects
                  ? 'No Projects Match Search'
                  : 'No Saved Projects Yet',
              style: theme.headingStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasOtherProjects
                  ? 'Try clearing the search query or changing the mode filter.'
                  : 'Start a new draft to save and name your spatial drawings.',
              style: theme.bodyStyle.copyWith(
                color: theme.secondaryInk,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.borderHighlight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Create New Project',
                style: theme.headingStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onPressed: _createNewProject,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotsTab(AppThemeTokens theme) {
    return Column(
      children: [
        _buildFilterBar(theme),
        Divider(height: 1, color: theme.borderSubtle),
        Expanded(
          child: ValueListenableBuilder<List<DraftCapture>>(
            valueListenable: GalleryService.instance.capturesNotifier,
            builder: (ctx, captures, _) {
              final filtered = _filterMode == null
                  ? captures
                  : captures
                      .where((c) => c.drillMode == _filterMode)
                      .toList();

              if (filtered.isEmpty) {
                return _buildEmptyState(theme, captures.isNotEmpty);
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 360,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.25,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, index) {
                  final capture = filtered[index];
                  return _CaptureCard(
                    capture: capture,
                    theme: theme,
                    onTap: () => _openDetail(capture),
                    onDelete: () => _deleteCaptureWithNotice(capture),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(AppThemeTokens theme) {
    return ValueListenableBuilder<List<DraftCapture>>(
      valueListenable: GalleryService.instance.capturesNotifier,
      builder: (ctx, captures, _) {
        return Container(
          color: theme.surfaceBackground,
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _buildFilterChip(
                label: 'All (${captures.length})',
                isSelected: _filterMode == null,
                theme: theme,
                onTap: () => setState(() => _filterMode = null),
              ),
              for (final mode in AppDrillMode.values)
                _buildFilterChip(
                  label: '${mode.shortLabel} ('
                      '${captures.where((c) => c.drillMode == mode).length})',
                  isSelected: _filterMode == mode,
                  theme: theme,
                  icon: mode.icon,
                  onTap: () => setState(() => _filterMode = mode),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required AppThemeTokens theme,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.accentCyan.withOpacity(0.18)
                : theme.surfaceBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.accentCyan : theme.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? theme.accentCyan : theme.secondaryInk,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.monoStyle.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? theme.accentCyan : theme.secondaryInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeTokens theme, bool hasOtherCaptures) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.accentCyan.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: theme.borderSubtle),
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: theme.accentCyan,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasOtherCaptures
                  ? 'No Snapshots in Selected Filter'
                  : 'No Draft Snapshots Yet',
              style: theme.headingStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                hasOtherCaptures
                    ? 'Switch back to "All" or select another practice drill '
                        'tab to view other archived snapshots.'
                    : 'Use the Camera icon in the top studio bar to capture '
                        'instant high-resolution snapshots of your drawing '
                        'studies and kinematics.',
                textAlign: TextAlign.center,
                style: theme.bodyStyle.copyWith(
                  color: theme.secondaryInk,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.theme,
    required this.onOpen,
    required this.onRename,
    required this.onDuplicate,
    required this.onExport,
    required this.onDelete,
  });

  final SpatialProject project;
  final AppThemeTokens theme;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.surfaceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thumbnail Preview Tile
          Expanded(
            child: InkWell(
              onTap: onOpen,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: theme.canvasBackground,
                    child: CustomPaint(
                      painter: _MiniProjectPainter(
                        strokes: project.strokes,
                        theme: theme,
                      ),
                    ),
                  ),

                  // Mode badge overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surfaceBackground.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            project.mode.icon,
                            size: 12,
                            color: theme.borderHighlight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            project.mode.shortLabel,
                            style: theme.monoStyle.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: theme.borderHighlight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stroke count pill
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        project.strokeCountLabel,
                        style: theme.monoStyle.copyWith(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Metadata and Action Row
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            color: theme.surfaceBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.headingStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: theme.secondaryInk,
                      ),
                      tooltip: 'Rename Draft',
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onRename,
                    ),
                  ],
                ),
                Text(
                  project.formattedDate,
                  style: theme.monoStyle.copyWith(
                    fontSize: 10,
                    color: theme.secondaryInk,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              theme.borderHighlight.withOpacity(0.15),
                          foregroundColor: theme.borderHighlight,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: theme.borderHighlight.withOpacity(0.4),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.draw_rounded, size: 14),
                        label: Text(
                          'Open',
                          style: theme.monoStyle.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.borderHighlight,
                          ),
                        ),
                        onPressed: onOpen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: theme.secondaryInk,
                      ),
                      tooltip: 'Duplicate Draft',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onDuplicate,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.ios_share_rounded,
                        size: 16,
                        color: theme.borderHighlight,
                      ),
                      tooltip: 'Export Vector / Project',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onExport,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: theme.danger,
                      ),
                      tooltip: 'Delete Draft',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProjectPainter extends CustomPainter {
  const _MiniProjectPainter({
    required this.strokes,
    required this.theme,
  });

  final List<Stroke> strokes;
  final AppThemeTokens theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final s in strokes) {
      for (final p in s.points) {
        final pos = p.position;
        if (pos.dx < minX) minX = pos.dx;
        if (pos.dx > maxX) maxX = pos.dx;
        if (pos.dy < minY) minY = pos.dy;
        if (pos.dy > maxY) maxY = pos.dy;
      }
    }

    if (minX.isInfinite || maxX.isInfinite) return;

    final contentW = maxX - minX;
    final contentH = maxY - minY;
    if (contentW <= 0 || contentH <= 0) return;

    final scaleX = (size.width - 20) / contentW;
    final scaleY = (size.height - 20) / contentH;
    final scale = math.min(scaleX, scaleY).clamp(0.01, 8.0);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-(minX + maxX) / 2, -(minY + maxY) / 2);

    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.lineWeight.baseWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(s.toSmoothedPath(), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniProjectPainter oldDelegate) => true;
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.capture,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  final DraftCapture capture;
  final AppThemeTokens theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppThemeTokens.of(
                      capture.themeMode,
                    ).canvasBackground,
                    child: capture.pngBytes.isNotEmpty
                        ? Image.memory(
                            capture.pngBytes,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.broken_image_outlined,
                            color: theme.secondaryInk,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surfaceBackground.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            capture.drillMode.icon,
                            size: 12,
                            color: theme.accentCyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            capture.drillMode.shortLabel,
                            style: theme.monoStyle.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.accentCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: theme.secondaryInk,
                      ),
                      tooltip: 'Delete Snapshot',
                      onPressed: onDelete,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: theme.surfaceBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          capture.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.headingStyle.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          capture.formattedDate,
                          style: theme.monoStyle.copyWith(
                            fontSize: 9,
                            color: theme.secondaryInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.canvasBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      capture.resolutionLabel,
                      style: theme.monoStyle.copyWith(
                        fontSize: 9,
                        color: theme.secondaryInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftDetailDialog extends StatelessWidget {
  const _DraftDetailDialog({
    required this.capture,
    required this.theme,
    required this.onDelete,
  });

  final DraftCapture capture;
  final AppThemeTokens theme;
  final VoidCallback onDelete;

  void _copyDetails(BuildContext context) {
    final text = 'Draft Snapshot: ${capture.title}\n'
        'Discipline: ${capture.drillMode.fullLabel}\n'
        'Timestamp: ${capture.formattedDate}\n'
        'Resolution: ${capture.resolutionLabel}\n'
        'Projection: ${capture.gridType.name}\n'
        'Theme: ${capture.themeMode.name}';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Snapshot details copied to clipboard'),
        backgroundColor: theme.accentCyan,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: theme.canvasBackground,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: capture.pngBytes.isNotEmpty
                        ? Image.memory(
                            capture.pngBytes,
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: theme.secondaryInk,
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surfaceBackground.withOpacity(0.9),
                    border: Border(
                      bottom: BorderSide(color: theme.borderSubtle),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        capture.drillMode.icon,
                        color: theme.accentCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capture.title,
                              style: theme.headingStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${capture.drillMode.fullLabel} • '
                              '${capture.formattedDate}',
                              style: theme.monoStyle.copyWith(
                                fontSize: 10,
                                color: theme.secondaryInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy Technical Details',
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        color: theme.defaultInk,
                        onPressed: () => _copyDetails(context),
                      ),
                      IconButton(
                        tooltip: 'Delete Snapshot',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: theme.danger,
                        ),
                        onPressed: onDelete,
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: theme.defaultInk,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.surfaceBackground.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pinch / Scroll to Zoom & Pan',
                          style: theme.monoStyle.copyWith(
                            fontSize: 11,
                            color: theme.secondaryInk,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.secondaryInk,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          capture.resolutionLabel,
                          style: theme.monoStyle.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.accentCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
