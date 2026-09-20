import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/canvas/common/color_palette_dock.dart';
import 'package:spatial_draft/canvas/infinite_zoom/infinite_zoom_hud.dart';
import 'package:spatial_draft/canvas/interactive_canvas.dart';
import 'package:spatial_draft/canvas/mental_canvas/mental_canvas_viewport.dart';
import 'package:spatial_draft/canvas/mental_canvas/plane_transform_sheet.dart';
import 'package:spatial_draft/core/models/canvas_plane_3d.dart';
import 'package:spatial_draft/core/models/spatial_bookmark.dart';
import 'package:spatial_draft/core/models/spatial_project.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/core/widgets/rename_project_dialog.dart';
import 'package:spatial_draft/drills/common/coachmark_tooltip.dart';
import 'package:spatial_draft/drills/common/concept_guide_sheet.dart';
import 'package:spatial_draft/services/project_service.dart';
import 'package:spatial_draft/views/gallery/project_export_dialog.dart';
import '../../canvas/mental_canvas/mental_canvas_turntable_dock.dart';

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

class _FreeformSandboxState extends State<FreeformSandbox>
    with TickerProviderStateMixin {
  late SpatialProject _project;
  final List<Stroke> _strokes = [];
  LineWeightType _currentWeight = LineWeightType.crease;
  Color? _activeColor;
  LineBrushStyle _activeBrushStyle = LineBrushStyle.ink;
  bool _showTooltip = true;

  late final TransformationController _zoomController;
  AnimationController? _flyThroughController;
  AnimationController? _tour3DController;
  bool _isPlaying3DTour = false;
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
    _flyThroughController?.dispose();
    _tour3DController?.dispose();
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
    if (_project.zoomScale > 0 &&
        (_project.panOffsetX != 0.0 ||
            _project.panOffsetY != 0.0 ||
            _project.zoomScale != 1.0)) {
      _zoomScale = _project.zoomScale;
      _zoomController.value = Matrix4.identity()
        ..translate(_project.panOffsetX, _project.panOffsetY)
        ..scale(_project.zoomScale);
    }
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
    final matrix = _zoomController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final tx = matrix.storage[12];
    final ty = matrix.storage[13];

    _project = _project.copyWith(
      strokes: List.from(_strokes),
      gridType: widget.gridType,
      gridStyle: widget.gridStyle,
      zoomScale: scale,
      panOffsetX: tx,
      panOffsetY: ty,
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

  void _animateToBookmark(SpatialBookmark bookmark) {
    _flyThroughController?.stop();
    _flyThroughController?.dispose();

    final startMatrix = _zoomController.value.clone();
    final startScale = startMatrix.getMaxScaleOnAxis().clamp(0.001, 25000.0);
    final startTx = startMatrix.storage[12];
    final startTy = startMatrix.storage[13];

    final targetScale = bookmark.zoomScale.clamp(0.001, 25000.0);
    final targetTx = bookmark.panOffsetX;
    final targetTy = bookmark.panOffsetY;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _flyThroughController = controller;

    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    curved.addListener(() {
      final t = curved.value;
      final logStart = math.log(startScale);
      final logTarget = math.log(targetScale);
      final currentScale = math.exp(
        logStart + t * (logTarget - logStart),
      );
      final currentTx = startTx + (targetTx - startTx) * t;
      final currentTy = startTy + (targetTy - startTy) * t;

      _zoomController.value = Matrix4.identity()
        ..translate(currentTx, currentTy)
        ..scale(currentScale);

      setState(() {
        _zoomScale = currentScale;
      });
    });

    controller.forward();
  }

  Future<void> _createBookmark() async {
    final nextNum = _project.bookmarks.length + 1;
    final name = await RenameProjectDialog.show(
      context: context,
      currentTitle: 'Scale Waypoint #$nextNum',
      theme: widget.theme,
      dialogTitle: 'Save Scale Bookmark',
    );
    if (name != null && name.trim().isNotEmpty) {
      final matrix = _zoomController.value;
      final scale = matrix.getMaxScaleOnAxis();
      final tx = matrix.storage[12];
      final ty = matrix.storage[13];

      final bookmark = SpatialBookmark(
        id: 'bm_${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        zoomScale: scale,
        panOffsetX: tx,
        panOffsetY: ty,
        createdAt: DateTime.now(),
      );

      setState(() {
        final updated = List<SpatialBookmark>.from(_project.bookmarks)
          ..add(bookmark);
        _project = _project.copyWith(bookmarks: updated);
      });
      _persistChanges();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved bookmark "${bookmark.name}"'),
            backgroundColor: widget.theme.borderHighlight,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _create3DBookmark() async {
    final waypoints3D = _project.bookmarks.where((b) => b.is3D).toList();
    final nextNum = waypoints3D.length + 1;
    final name = await RenameProjectDialog.show(
      context: context,
      currentTitle: 'Keyframe #$nextNum',
      theme: widget.theme,
      dialogTitle: 'Save 3D Camera Keyframe',
    );
    if (name != null && name.trim().isNotEmpty) {
      final bookmark = SpatialBookmark.waypoint3D(
        id: 'bm_3d_${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        cameraYaw: _project.cameraYaw,
        cameraPitch: _project.cameraPitch,
        cameraDistance: _project.cameraDistance,
        targetPlaneId: _project.activePlaneId,
        createdAt: DateTime.now(),
      );

      setState(() {
        final updated = List<SpatialBookmark>.from(_project.bookmarks)
          ..add(bookmark);
        _project = _project.copyWith(bookmarks: updated);
      });
      _persistChanges();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved 3D keyframe "${bookmark.name}"'),
            backgroundColor: widget.theme.accentAmber,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _animateTo3DBookmark(SpatialBookmark bookmark) {
    _flyThroughController?.stop();
    _flyThroughController?.dispose();
    _tour3DController?.stop();
    _tour3DController?.dispose();

    final startYaw = _project.cameraYaw;
    final startPitch = _project.cameraPitch;
    final startDist = _project.cameraDistance;

    final targetYaw = bookmark.cameraYaw ?? 0.0;
    final targetPitch = bookmark.cameraPitch ?? 0.0;
    final targetDist = bookmark.cameraDistance ?? 900.0;

    final diffYaw =
        ((targetYaw - startYaw + math.pi) % (2 * math.pi)) - math.pi;
    final diffPitch = targetPitch - startPitch;
    final diffDist = targetDist - startDist;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _tour3DController = controller;

    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    curved.addListener(() {
      final t = curved.value;
      if (mounted) {
        setState(() {
          _project = _project.copyWith(
            cameraYaw: startYaw + diffYaw * t,
            cameraPitch: (startPitch + diffPitch * t).clamp(
              -math.pi / 2.5,
              math.pi / 2.5,
            ),
            cameraDistance: startDist + diffDist * t,
            activePlaneId: bookmark.targetPlaneId ?? _project.activePlaneId,
          );
        });
      }
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _persistChanges();
      }
    });

    controller.forward();
  }

  Future<void> _playCinematicTour() async {
    if (_isPlaying3DTour) {
      _stopCinematicTour();
      return;
    }

    final waypoints = _project.bookmarks.where((b) => b.is3D).toList();
    if (waypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Need at least 2 camera keyframes to play cinematic tour',
          ),
          backgroundColor: widget.theme.accentAmber,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isPlaying3DTour = true;
    });

    for (int i = 0; i < waypoints.length; i++) {
      if (!_isPlaying3DTour || !mounted) break;
      await _animateTo3DBookmarkFuture(waypoints[i]);
      if (!_isPlaying3DTour || !mounted) break;
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    if (mounted) {
      setState(() {
        _isPlaying3DTour = false;
      });
    }
  }

  Future<void> _animateTo3DBookmarkFuture(SpatialBookmark bookmark) {
    final completer = Completer<void>();
    _tour3DController?.stop();
    _tour3DController?.dispose();

    final startYaw = _project.cameraYaw;
    final startPitch = _project.cameraPitch;
    final startDist = _project.cameraDistance;

    final targetYaw = bookmark.cameraYaw ?? 0.0;
    final targetPitch = bookmark.cameraPitch ?? 0.0;
    final targetDist = bookmark.cameraDistance ?? 900.0;

    final diffYaw =
        ((targetYaw - startYaw + math.pi) % (2 * math.pi)) - math.pi;
    final diffPitch = targetPitch - startPitch;
    final diffDist = targetDist - startDist;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _tour3DController = controller;

    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    curved.addListener(() {
      final t = curved.value;
      if (mounted) {
        setState(() {
          _project = _project.copyWith(
            cameraYaw: startYaw + diffYaw * t,
            cameraPitch: (startPitch + diffPitch * t).clamp(
              -math.pi / 2.5,
              math.pi / 2.5,
            ),
            cameraDistance: startDist + diffDist * t,
            activePlaneId: bookmark.targetPlaneId ?? _project.activePlaneId,
          );
        });
      }
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    controller.forward();
    return completer.future;
  }

  void _stopCinematicTour() {
    _tour3DController?.stop();
    _tour3DController?.dispose();
    _tour3DController = null;
    if (mounted) {
      setState(() {
        _isPlaying3DTour = false;
      });
    }
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

  void _openPlaneTransformSheet() {
    final active = _project.activePlane;
    PlaneTransformSheet.show(
      context: context,
      theme: widget.theme,
      plane: active,
      onPlaneUpdated: (updatedPlane) {
        setState(() {
          final updatedPlanes = _project.planes.map((p) {
            return p.id == updatedPlane.id ? updatedPlane : p;
          }).toList();
          _project = _project.copyWith(planes: updatedPlanes);
        });
        _persistChanges();
      },
      onDuplicatePlane: () {
        final duplicated = active.copyWith(
          id: 'plane_${DateTime.now().microsecondsSinceEpoch}',
          name: '${active.name} (Copy)',
          originZ: active.originZ + 40.0,
        );
        setState(() {
          final updatedPlanes = List<CanvasPlane3D>.from(_project.planes)
            ..add(duplicated);
          _project = _project.copyWith(
            planes: updatedPlanes,
            activePlaneId: duplicated.id,
          );
        });
        _persistChanges();
      },
      onDeletePlane: () {
        if (_project.planes.length <= 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Cannot delete the last remaining plane',
              ),
              backgroundColor: widget.theme.accentAmber,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        setState(() {
          final updatedPlanes = _project.planes
              .where((p) => p.id != active.id)
              .toList();
          _project = _project.copyWith(
            planes: updatedPlanes,
            activePlaneId: updatedPlanes.first.id,
          );
        });
        _persistChanges();
      },
    );
  }

  String get _coachmarkTitle {
    switch (_project.mode) {
      case SandboxMode.mentalCanvas3D:
        return '3D Mental Canvas Stage';
      case SandboxMode.infiniteZoom:
        return 'Infinite Vector Zoom Engine';
      case SandboxMode.vellum2D:
        return 'Drafting Sandbox';
    }
  }

  String get _coachmarkMessage {
    switch (_project.mode) {
      case SandboxMode.mentalCanvas3D:
        return 'Multi-plane spatial sketching. Use 1 finger to draw, '
            '2 fingers to orbit camera. Record keyframes and play 3D tours!';
      case SandboxMode.infiniteZoom:
        return 'Deep multi-scale canvas (0.001×–25,000×). Pinch or use HUD '
            'presets. Save scale bookmarks to fly across scales.';
      case SandboxMode.vellum2D:
        return 'Free infinite ideation. Tap draft name to rename, '
            'toggle ink vs cel-shading wash, and export SVG/3D.';
    }
  }

  void _openGuide() {
    ConceptGuideSheet.show(
      context: context,
      drillTitle: 'Spatial Drafting Studio',
      categorySubtitle: 'Infinite Zoom & 3D Mental Canvas',
      theme: widget.theme,
      sections: const [
        GuideSectionItem(
          title: '3D Mental Canvas & Camera Tours',
          content:
              'Project sketches onto oriented 3D planes. Orbit with two '
              'fingers or turntable controls. Save camera keyframes in the '
              'dock to produce cinematic spherical fly-through tours.',
          icon: Icons.view_in_ar_rounded,
        ),
        GuideSectionItem(
          title: 'Infinite Vector Zoom (25,000×)',
          content:
              'Zoom continuously across 7 orders of magnitude without '
              'pixelation. Author nested sub-assemblies and bookmark scale '
              'waypoints for logarithmic camera navigation.',
          icon: Icons.zoom_in_map_rounded,
        ),
        GuideSectionItem(
          title: 'Cel-Shading Wash & Color Palette',
          content:
              'Toggle between crisp Ink outlines and translucent Cel Wash '
              '(35% opacity, 3.2× width) with 8 curated swatches for anime '
              'and engineering drafting.',
          icon: Icons.palette_outlined,
        ),
        GuideSectionItem(
          title: 'Direct Draft Naming & Auto-Save',
          content:
              'Tap the top title pill to rename your draft. All strokes and '
              'settings auto-save continuously to your Project Vault.',
          icon: Icons.edit_note_rounded,
        ),
        GuideSectionItem(
          title: 'Interactive 3D Web & SVG Export',
          content:
              'Export standalone self-contained 3D HTML files with interactive '
              'orbit and storyboard tour playback, or resolution-independent '
              'vector SVG files.',
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
          currentBrushStyle: _activeBrushStyle,
          overrideInkColor: _activeColor,
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
          currentBrushStyle: _activeBrushStyle,
          overrideInkColor: _activeColor,
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
          currentBrushStyle: _activeBrushStyle,
          overrideInkColor: _activeColor,
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
              title: _coachmarkTitle,
              message: _coachmarkMessage,
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
                bookmarks: _project.bookmarks,
                onZoomPresetSelected: _setZoomScale,
                onZoomStep: _zoomByFactor,
                onResetZoom: _resetZoom,
                onSelectBookmark: _animateToBookmark,
                onAddBookmark: _createBookmark,
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
                onEditPlane: _openPlaneTransformSheet,
                bookmarks: _project.bookmarks,
                onSelectBookmark: _animateTo3DBookmark,
                onAddBookmark: _create3DBookmark,
                onPlayTour: _playCinematicTour,
                isPlayingTour: _isPlaying3DTour,
              ),
            ),
          ),

        // Color Swatches & Brush Style Dock
        Positioned(
          bottom: _project.mode == SandboxMode.mentalCanvas3D ||
                  _project.mode == SandboxMode.infiniteZoom
              ? 154
              : 96,
          left: 24,
          right: 24,
          child: Center(
            child: ColorPaletteDock(
              theme: theme,
              selectedColor: _activeColor ?? theme.defaultInk,
              onColorSelected: (c) => setState(() => _activeColor = c),
              selectedBrushStyle: _activeBrushStyle,
              onBrushStyleChanged: (b) =>
                  setState(() => _activeBrushStyle = b),
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
