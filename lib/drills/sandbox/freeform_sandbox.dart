import 'package:flutter/material.dart';
import 'package:spatial_draft/canvas/interactive_canvas.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/drills/common/coachmark_tooltip.dart';
import 'package:spatial_draft/drills/common/concept_guide_sheet.dart';

class FreeformSandbox extends StatefulWidget {

  const FreeformSandbox({
    super.key,
    required this.theme,
    required this.gridStyle,
    required this.gridType,
  });
  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;

  @override
  State<FreeformSandbox> createState() => _FreeformSandboxState();
}

class _FreeformSandboxState extends State<FreeformSandbox> {
  final List<Stroke> _strokes = [];
  LineWeightType _currentWeight = LineWeightType.crease;
  bool _showTooltip = true;

  void _handleStrokeCompleted(Stroke stroke) {
    setState(() {
      _strokes.add(stroke);
      _showTooltip = false;
    });
  }

  void _undo() {
    setState(_strokes.removeLast);
  }

  void _clear() {
    setState(_strokes.clear);
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
              'Use two fingers to pan infinitely or pinch to zoom. Your Apple Pencil draws with zero interference from accidental palm touches.',
          icon: Icons.zoom_out_map_rounded,
        ),
        GuideSectionItem(
          title: 'Switching Grids & Themes',
          content:
              'Seamlessly switch between Square Metric, Isometric, and Perspective grids in Solid, Dotted, or Dashed styles from the top toolbar.',
          icon: Icons.grid_4x4_rounded,
        ),
        GuideSectionItem(
          title: 'Line Weight Discipline',
          content:
              'Switch between Silhouette (thick), Crease (medium), and Hidden (dashed) to craft professional mechanical blueprints and exploded assemblies.',
          icon: Icons.architecture_rounded,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Stack(
      children: [
        InteractiveCanvas(
          theme: theme,
          gridStyle: widget.gridStyle,
          gridType: widget.gridType,
          currentLineWeight: _currentWeight,
          strokes: _strokes,
          onStrokeCompleted: _handleStrokeCompleted,
        ),

        if (_showTooltip)
          Positioned(
            top: 24,
            left: 24,
            child: CoachmarkTooltip(
              title: 'Drafting Sandbox',
              message: 'Free infinite ideation. Two fingers to pan/zoom, Apple Pencil to sketch.',
              theme: theme,
              onDismiss: () => setState(() => _showTooltip = false),
              onOpenGuide: _openGuide,
            ),
          ),

        // Bottom Line Weight Bar & Canvas Tools
        Positioned(
          bottom: 28,
          left: 24,
          right: 24,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 760),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.borderHighlight : theme.canvasBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? theme.borderHighlight : theme.borderSubtle,
                            ),
                          ),
                          child: Text(
                            weight.label.split(' ').first,
                            style: theme.headingStyle.copyWith(
                              fontSize: 12,
                              color: isSelected ? Colors.white : theme.defaultInk,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  const Spacer(),

                  IconButton(
                    icon: Icon(Icons.undo_rounded, color: theme.secondaryInk, size: 20),
                    onPressed: _strokes.isNotEmpty ? _undo : null,
                    tooltip: 'Undo',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: theme.secondaryInk, size: 20),
                    onPressed: _strokes.isNotEmpty ? _clear : null,
                    tooltip: 'Clear Canvas',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
