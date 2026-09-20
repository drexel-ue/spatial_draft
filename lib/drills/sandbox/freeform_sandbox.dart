import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/canvas/infinite_zoom/infinite_zoom_hud.dart';
import 'package:spatial_draft/canvas/interactive_canvas.dart';
import 'package:spatial_draft/canvas/mental_canvas/mental_canvas_turntable_dock.dart';
import 'package:spatial_draft/canvas/mental_canvas/mental_canvas_viewport.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/core/widgets/rename_project_dialog.dart';
import 'package:spatial_draft/drills/common/coachmark_tooltip.dart';
import 'package:spatial_draft/drills/common/concept_guide_sheet.dart';
import 'package:spatial_draft/services/project_service.dart';
import 'package:spatial_draft/views/gallery/project_export_dialog.dart';

class FreeformSandbox extends StatefulWidget {
  const FreeformSandbox({
    super.key,
    required this.theme,
    required this.gridStyle,
    required this.gridType,
    this.initialProject,
    this.onProjectUpdated,
  });

  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final SpatialProject? initialProject;
  final ValueChanged<SpatialProject>? onProjectUpdated;

  @override
  State<FreeformSandbox> createState() => _FreeformSandboxState();
}

class _FreeformSandboxState extends State<FreeformSandbox> {
  late SpatialProject _project;
  final List<Stroke> _strokes = [];
  LineWeightType _currentWeight = LineWeightType.crease;
  bool _showTooltip = true;

  late final TransformationController _zoomController;
  double _zoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    _zoomController = TransformationController();
    _zoomController.addListener(_onZoomTransformUpdated);
    _initProject();
  }

  @override
  void dispose() {
    _zoomController.removeListener(_onZoomTransformUpdated);
    _zoomController.dispose();
    super.dispose();
  }

  void _onZoomTransformUpdated() {
    final scale = _zoomController.value.getMaxScaleOnAxis();
    if ((scale - _zoomScale).abs() > 0.0001) {
      setState(() {
        _zoomScale = scale;
      });
    }
  }

  void _initProject() {
    if (widget.initialProject != null) {
      _project = widget.initialProject!;
    } else if (ProjectService.instance.projects.isNotEmpty) {
      _project = ProjectService.instance.projects.first;
    } else {
      _project = SpatialProject(
        id: 'proj_${DateTime.now().microsecondsSinceEpoch}',
        title: 'Spatial Draft #1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    _strokes.clear();
    _strokes.addAll(_project.strokes);
  }

  void _handleStrokeCompleted(Stroke stroke) {
    setState(() {
      _strokes.add(stroke);
      _showTooltip = false;
    });
    _persistChanges();
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(_strokes.removeLast);
      _persistChanges();
    }
  }

  void _clear() {
    if (_strokes.isNotEmpty) {
      setState(_strokes.clear);
      _persistChanges();
    }
  }

  void _persistChanges() {
    _project = _project.copyWith(
      strokes: List.from(_strokes),
      gridType: widget.gridType,
      gridStyle: widget.gridStyle,
      updatedAt: DateTime.now(),
    );
    ProjectService.instance.saveProject(_project);
    widget.onProjectUpdated?.call(_project);
  }

  Future<void> _renameProject() async {
    final newTitle = await RenameProjectDialog.show(
      context: context,
      currentTitle: _project.title,
      theme: widget.theme,
      dialogTitle: 'Rename Active Draft',
    );
    if (newTitle != null && newTitle != _project.title) {
      final updated = await ProjectService.instance.renameProject(
        _project.id,
        newTitle,
      );
      if (updated != null) {
        setState(() {
          _project = updated;
        });
        widget.onProjectUpdated?.call(_project);
      }
    }
  }

  Future<void> _createNewDraft() async {
    final nextNum = ProjectService.instance.projects.length + 1;
    final title = await RenameProjectDialog.show(
      context: context,
      currentTitle: 'Spatial Draft #$nextNum',
      theme: widget.theme,
      dialogTitle: 'New Drafting Project',
    );
    if (title != null && title.trim().isNotEmpty) {
      final newProj = await ProjectService.instance.createProject(
        title: title.trim(),
        mode: _project.mode,
        gridType: widget.gridType,
        gridStyle: widget.gridStyle,
      );
      setState(() {
        _project = newProj;
        _strokes.clear();
      });
      widget.onProjectUpdated?.call(_project);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created and opened "${newProj.title}"'),
            backgroundColor: widget.theme.borderHighlight,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _cycleMode() {
    const values = SandboxMode.values;
    final nextIndex = (values.indexOf(_project.mode) + 1) % values.length;
    setState(() {
      _project = _project.copyWith(mode: values[nextIndex]);
    });
    _persistChanges();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to ${_project.mode.label}'),
        backgroundColor: widget.theme.borderHighlight,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setZoomScale(double targetScale) {
    final currentMatrix = _zoomController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    if (currentScale <= 0) return;
    _zoomByFactor(targetScale / currentScale);
  }

  void _zoomByFactor(double factor) {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final matrix = _zoomController.value.clone();

    final currentScale = matrix.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.001, 25000.0);
    final effectiveFactor = newScale / currentScale;

    final tx = matrix.storage[12];
    final ty = matrix.storage[13];

    final newTx = center.dx - (center.dx - tx) * effectiveFactor;
    final newTy = center.dy - (center.dy - ty) * effectiveFactor;

    _zoomController.value = Matrix4.identity()
      ..translate(newTx, newTy)
      ..scale(newScale);

    setState(() {
      _zoomScale = newScale;
    });
  }

  void _resetZoom() {
    final size = MediaQuery.of(context).size;
    final tx = (size.width - 4000.0) / 2.0;
    final ty = (size.height - 4000.0) / 2.0;
    _zoomController.value = Matrix4.identity()..translate(tx, ty);
    setState(() {
      _zoomScale = 1.0;
    });
  }

  void _faceActivePlane() {
    final plane = _project.activePlane;
    setState(() {
      _project = _project.copyWith(
        cameraYaw: -plane.yaw,
        cameraPitch: (-plane.pitch).clamp(
          -math.pi / 2.5,
          math.pi / 2.5,
        ),
      );
    });
    _persistChanges();
  }

  void _openGuide() {
    ConceptGuideSheet.show(
      context: context,
      drillTitle: 'Infinite Drafting Sandbox',
      categorySubtitle: 'Freeform Engineering & Art Studio',
      theme: widget.theme,
      sections: const [
        GuideSectionItem(
          title: 'Unconstrained Infinite Canvas',
          content:
              'Use two fingers to pan or pinch to zoom. Tap the Recenter '
              '[ ⌖ ] HUD button anytime to reset zoom to 1:1.',
          icon: Icons.zoom_out_map_rounded,
        ),
        GuideSectionItem(
          title: 'Direct Draft Naming & Auto-Save',
          content:
              'Tap the top title pill to rename your draft. All strokes and '
              'settings auto-save continuously to your Project Vault.',
          icon: Icons.edit_note_rounded,
        ),
        GuideSectionItem(
          title: 'Multi-Format Vector Export',
          content:
              'Tap the share button on the dock to copy resolution-independent '
              'SVG paths for CAD/Illustrator or native .spatial project files.',
          icon: Icons.ios_share_rounded,
        ),
      ],
    );
  }

  Widget _buildCanvas(AppThemeTokens theme) {
    switch (_project.mode) {
      case SandboxMode.mentalCanvas3D:
        return MentalCanvasViewport(
          key: const ValueKey('mental_canvas_viewport'),
          theme: theme,
          planes: _project.planes,
          activePlaneId: _project.activePlaneId,
          strokes: _strokes,
          currentLineWeight: _currentWeight,
          cameraYaw: _project.cameraYaw,
          cameraPitch: _project.cameraPitch,
          cameraDistance: _project.cameraDistance,
          onStrokeCompleted: _handleStrokeCompleted,
          onCameraChanged: (yaw, pitch, distance) {
            setState(() {
              _project = _project.copyWith(
                cameraYaw: yaw,
                cameraPitch: pitch,
                cameraDistance: distance,
              );
            });
            _persistChanges();
          },
        );

      case SandboxMode.infiniteZoom:
        return InteractiveCanvas(
          key: const ValueKey('infinite_zoom_canvas'),
          theme: theme,
          gridStyle: widget.gridStyle,
          gridType: widget.gridType,
          currentLineWeight: _currentWeight,
          strokes: _strokes,
          isInfiniteZoom: true,
          transformationController: _zoomController,
          activePlaneId: _project.activePlaneId,
          onStrokeCompleted: _handleStrokeCompleted,
          onScaleChanged: (scale) {
            if ((scale - _zoomScale).abs() > 0.0001) {
              setState(() => _zoomScale = scale);
            }
          },
        );

      case SandboxMode.vellum2D:
        return InteractiveCanvas(
          key: const ValueKey('vellum_2d_canvas'),
          theme: theme,
          gridStyle: widget.gridStyle,
          gridType: widget.gridType,
          currentLineWeight: _currentWeight,
          strokes: _strokes,
          isInfiniteZoom: false,
          activePlaneId: _project.activePlaneId,
          onStrokeCompleted: _handleStrokeCompleted,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Stack(
      children: [
        _buildCanvas(theme),

        // Floating Project Title & Mode Pill (Top Left)
        Positioned(
          top: 16,
          left: 24,
          child: _buildTitlePill(theme),
        ),

        if (_showTooltip)
          Positioned(
            top: 72,
            left: 24,
            child: CoachmarkTooltip(
              title: 'Drafting Sandbox',
              message:
                  'Free infinite ideation. Tap draft name to rename, '
                  'pencil to sketch, HUD to recenter.',
              theme: theme,
              onDismiss: () => setState(() => _showTooltip = false),
              onOpenGuide: _openGuide,
            ),
          ),

        // Mode-Specific Floating HUD Dock (Directly Above Bottom Bar)
        if (_project.mode == SandboxMode.infiniteZoom)
          Positioned(
            bottom: 96,
            left: 24,
            right: 24,
            child: Center(
              child: InfiniteZoomHud(
                theme: theme,
                zoomScale: _zoomScale,
                onZoomPresetSelected: _setZoomScale,
                onZoomStep: _zoomByFactor,
                onResetZoom: _resetZoom,
              ),
            ),
          ),

        if (_project.mode == SandboxMode.mentalCanvas3D)
          Positioned(
            bottom: 96,
            left: 24,
            right: 24,
            child: Center(
              child: MentalCanvasTurntableDock(
                theme: theme,
                planes: _project.planes,
                activePlaneId: _project.activePlaneId,
                cameraYaw: _project.cameraYaw,
                cameraPitch: _project.cameraPitch,
                onCameraChanged: (yaw, pitch) {
                  setState(() {
                    _project = _project.copyWith(
                      cameraYaw: yaw,
                      cameraPitch: pitch,
                    );
                  });
                  _persistChanges();
                },
                onSelectPlane: (id) {
                  setState(() {
                    _project = _project.copyWith(activePlaneId: id);
                  });
                  _persistChanges();
                },
                onAddPlane: (plane) {
                  setState(() {
                    final updated = List<CanvasPlane3D>.from(
                      _project.planes,
                    )..add(plane);
                    _project = _project.copyWith(
                      planes: updated,
                      activePlaneId: plane.id,
                    );
                  });
                  _persistChanges();
                },
                onSnapToPlane: _faceActivePlane,
                onResetOrbit: () {
                  setState(() {
                    _project = _project.copyWith(
                      cameraYaw: 0.0,
                      cameraPitch: 0.0,
                      cameraDistance: 900.0,
                    );
                  });
                  _persistChanges();
                },
              ),
            ),
          ),

        // Bottom Line Weight Bar & Canvas Tools
        Positioned(
          bottom: 28,
          left: 24,
          right: 24,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 820),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.surfaceGlass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.borderSubtle, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'WEIGHT:',
                    style: theme.monoStyle.copyWith(
                      fontSize: 10,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                      color: theme.secondaryInk,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Line Weight Pills
                  ...LineWeightType.values.map((weight) {
                    final isSelected = _currentWeight == weight;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => _currentWeight = weight),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.borderHighlight
                                : theme.canvasBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? theme.borderHighlight
                                  : theme.borderSubtle,
                            ),
                          ),
                          child: Text(
                            weight.label.split(' ').first,
                            style: theme.headingStyle.copyWith(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : theme.defaultInk,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const Spacer(),

                  IconButton(
                    icon: Icon(
                      Icons.undo_rounded,
                      color: theme.secondaryInk,
                      size: 20,
                    ),
                    onPressed: _strokes.isNotEmpty ? _undo : null,
                    tooltip: 'Undo',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.secondaryInk,
                      size: 20,
                    ),
                    onPressed: _strokes.isNotEmpty ? _clear : null,
                    tooltip: 'Clear Canvas',
                  ),

                  Container(
                    width: 1,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: theme.borderSubtle,
                  ),

                  IconButton(
                    icon: Icon(
                      Icons.ios_share_rounded,
                      color: theme.borderHighlight,
                      size: 20,
                    ),
                    onPressed: () {
                      ProjectExportDialog.show(
                        context: context,
                        project: _project,
                        theme: theme,
                      );
                    },
                    tooltip: 'Export SVG / Project',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitlePill(AppThemeTokens theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Project Name & Edit Button
            InkWell(
              onTap: _renameProject,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _project.mode.icon,
                      color: theme.borderHighlight,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        _project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.headingStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.defaultInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_outlined,
                      color: theme.secondaryInk,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: 1,
              height: 18,
              color: theme.borderSubtle,
            ),

            // Mode Selector Badge
            InkWell(
              onTap: _cycleMode,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _project.mode.shortLabel,
                      style: theme.monoStyle.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.borderHighlight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: theme.secondaryInk,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: 1,
              height: 18,
              color: theme.borderSubtle,
            ),

            // New Draft Button [+]
            InkWell(
              onTap: _createNewDraft,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 8,
                ),
                child: Tooltip(
                  message: 'Create New Draft Project',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: theme.accentCyan,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'New',
                        style: theme.monoStyle.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
    );
  }
}
