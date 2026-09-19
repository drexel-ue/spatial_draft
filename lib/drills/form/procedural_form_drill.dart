import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/canvas/interactive_canvas.dart';
import 'package:spatial_draft/canvas/procedural_forms/procedural_form_painter.dart';
import 'package:spatial_draft/canvas/procedural_forms/procedural_form_registry.dart';
import 'package:spatial_draft/core/models/procedural_form.dart';
import 'package:spatial_draft/core/models/skill_profile.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/drills/common/coachmark_tooltip.dart';
import 'package:spatial_draft/drills/common/concept_guide_sheet.dart';
import 'package:spatial_draft/views/form_library/form_library_sheet.dart';

/// Full-featured interactive studio practice drill for procedural forms.
class ProceduralFormDrill extends StatefulWidget {
  const ProceduralFormDrill({
    super.key,
    required this.theme,
    required this.gridStyle,
    required this.gridType,
    required this.skillProfile,
    required this.onProfileUpdated,
    this.initialFormId = ProceduralFormId.eyeOrbit,
  });

  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final SkillProfile skillProfile;
  final VoidCallback onProfileUpdated;
  final ProceduralFormId initialFormId;

  @override
  State<ProceduralFormDrill> createState() => _ProceduralFormDrillState();
}

class _ProceduralFormDrillState extends State<ProceduralFormDrill> {
  final List<Stroke> _strokes = [];
  late ProceduralFormId _activeFormId;
  late ProceduralFormConfig _config;
  double _overlayOpacity = 0.65;
  bool _showTooltip = true;

  @override
  void initState() {
    super.initState();
    _activeFormId = widget.initialFormId;
    _config = const ProceduralFormConfig(scale: 1.1);
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(_strokes.removeLast);
    }
  }

  void _clear() {
    setState(_strokes.clear);
  }

  void _mutateRandomVariant() {
    final rand = math.Random();
    final newYaw = (rand.nextDouble() - 0.5) * math.pi * 0.85;
    final newPitch = (rand.nextDouble() - 0.5) * math.pi * 0.50;
    final newSeed = rand.nextInt(10000);

    setState(() {
      _config = _config.copyWith(
        yaw: newYaw,
        pitch: newPitch,
        seed: newSeed,
      );
      _strokes.clear();
    });
  }

  void _openLibrarySheet() {
    FormLibrarySheet.show(
      context: context,
      theme: widget.theme,
      initialSelectedId: _activeFormId,
      onSelectForm: (newId) {
        setState(() {
          _activeFormId = newId;
          _strokes.clear();
        });
      },
    );
  }

  void _handleStrokeCompleted(Stroke stroke) {
    widget.skillProfile.recordFormAnalysis(accuracy: 0.85);
    widget.onProfileUpdated();
    setState(() {
      _strokes.add(stroke);
      _showTooltip = false;
    });
  }

  void _openGuide() {
    final def = ProceduralFormRegistry.getById(_activeFormId);
    ConceptGuideSheet.show(
      context: context,
      drillTitle: def.title,
      categorySubtitle: '${def.category.label} (${def.difficulty})',
      theme: widget.theme,
      sections: [
        GuideSectionItem(
          title: 'Drafting Protocol',
          content: def.draftingTip,
          icon: Icons.architecture_rounded,
        ),
        GuideSectionItem(
          title: 'Key Structural Landmarks',
          content: def.anatomicalLandmarks.join(' • '),
          icon: Icons.place_rounded,
        ),
        const GuideSectionItem(
          title: 'Spatial Rotation & Memory',
          content:
              'Use the turntable scrubbers to rotate the volume in 3D. '
              'Lower the guide overlay opacity to test your mental rotation.',
          icon: Icons.threed_rotation_rounded,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final def = ProceduralFormRegistry.getById(_activeFormId);

    return Stack(
      children: [
        InteractiveCanvas(
          theme: theme,
          gridStyle: widget.gridStyle,
          gridType: widget.gridType,
          strokes: _strokes,
          onStrokeCompleted: _handleStrokeCompleted,
          backgroundDrillOverlay: CustomPaint(
            painter: ProceduralFormPainter(
              theme: theme,
              formId: _activeFormId,
              config: _config,
              opacityMultiplier: _overlayOpacity,
            ),
          ),
        ),

        // Top-left Coachmark / Concept summary
        if (_showTooltip)
          Positioned(
            top: 24,
            left: 24,
            child: CoachmarkTooltip(
              title: def.title,
              message: def.draftingTip,
              theme: theme,
              onDismiss: () => setState(() => _showTooltip = false),
              onOpenGuide: _openGuide,
            ),
          ),

        // Bottom Form Control & Rotation Bar
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 880),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: theme.surfaceGlass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.borderSubtle, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Active Form Pill & Browse Button
                    InkWell(
                      onTap: _openLibrarySheet,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.borderHighlight.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.borderHighlight.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              def.category.icon,
                              size: 16,
                              color: theme.borderHighlight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              def.title,
                              style: theme.headingStyle.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.borderHighlight,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.expand_more_rounded,
                              size: 16,
                              color: theme.borderHighlight,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Mutate / Random Variant
                    IconButton(
                      tooltip: 'Randomize Pose / Perspective',
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: theme.accentAmber,
                        size: 18,
                      ),
                      onPressed: _mutateRandomVariant,
                    ),

                    const SizedBox(width: 8),

                    // 3D Yaw Rotation Controls
                    Text(
                      'YAW:',
                      style: theme.monoStyle.copyWith(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: theme.secondaryInk,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Rotate Left',
                      icon: Icon(
                        Icons.rotate_left_rounded,
                        color: theme.secondaryInk,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _config = _config.copyWith(
                            yaw: _config.yaw - 0.20,
                          );
                        });
                      },
                    ),
                    IconButton(
                      tooltip: 'Rotate Right',
                      icon: Icon(
                        Icons.rotate_right_rounded,
                        color: theme.secondaryInk,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _config = _config.copyWith(
                            yaw: _config.yaw + 0.20,
                          );
                        });
                      },
                    ),

                    const SizedBox(width: 8),

                    // Wireframe Toggle
                    IconButton(
                      tooltip: _config.showWireframe
                          ? 'Hide Cross-Contours'
                          : 'Show Cross-Contours',
                      icon: Icon(
                        _config.showWireframe
                            ? Icons.blur_circular_rounded
                            : Icons.circle_outlined,
                        color: _config.showWireframe
                            ? theme.accentCyan
                            : theme.secondaryInk,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _config = _config.copyWith(
                            showWireframe: !_config.showWireframe,
                          );
                        });
                      },
                    ),

                    // Axes Toggle
                    IconButton(
                      tooltip: _config.showAxes ? 'Hide Axes' : 'Show Axes',
                      icon: Icon(
                        Icons.alt_route_rounded,
                        color: _config.showAxes
                            ? theme.accentAmber
                            : theme.secondaryInk,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _config = _config.copyWith(
                            showAxes: !_config.showAxes,
                          );
                        });
                      },
                    ),

                    // Opacity Cycle (100% -> 60% -> 30% -> 0%)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_overlayOpacity >= 0.9) {
                            _overlayOpacity = 0.60;
                          } else if (_overlayOpacity >= 0.5) {
                            _overlayOpacity = 0.25;
                          } else if (_overlayOpacity >= 0.2) {
                            _overlayOpacity = 0.0;
                          } else {
                            _overlayOpacity = 1.0;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.surfaceGlass,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.borderSubtle),
                        ),
                        child: Text(
                          'GUIDE: ${(_overlayOpacity * 100).round()}%',
                          style: theme.monoStyle.copyWith(
                            fontSize: 10,
                            color: theme.secondaryInk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Undo & Clear
                    IconButton(
                      tooltip: 'Undo Stroke',
                      icon: Icon(
                        Icons.undo_rounded,
                        color: theme.secondaryInk,
                        size: 18,
                      ),
                      onPressed: _strokes.isEmpty ? null : _undo,
                    ),
                    IconButton(
                      tooltip: 'Clear Canvas',
                      icon: Icon(
                        Icons.delete_sweep_rounded,
                        color: theme.secondaryInk,
                        size: 18,
                      ),
                      onPressed: _strokes.isEmpty ? null : _clear,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
