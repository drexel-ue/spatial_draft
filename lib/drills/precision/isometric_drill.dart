import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../canvas/interactive_canvas.dart';
import '../../core/models/skill_profile.dart';
import '../../core/models/stroke.dart';
import '../../core/theme/app_theme.dart';
import '../common/coachmark_tooltip.dart';
import '../common/concept_guide_sheet.dart';

class IsometricDrill extends StatefulWidget {
  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final SkillProfile skillProfile;
  final VoidCallback onProfileUpdated;

  const IsometricDrill({
    super.key,
    required this.theme,
    required this.gridStyle,
    required this.gridType,
    required this.skillProfile,
    required this.onProfileUpdated,
  });

  @override
  State<IsometricDrill> createState() => _IsometricDrillState();
}

class _IsometricDrillState extends State<IsometricDrill> {
  final List<Stroke> _strokes = [];
  LineWeightType _activeLineWeight = LineWeightType.silhouette;
  bool _showTooltip = true;
  late int _seed;

  @override
  void initState() {
    super.initState();
    _seed = math.Random().nextInt(1000);
  }

  void _generateNewObject() {
    setState(() {
      _seed = math.Random().nextInt(1000);
      _strokes.clear();
    });
  }

  void _handleStrokeCompleted(Stroke stroke) {
    widget.skillProfile.recordIsometricAnalysis(
      accuracy: 0.88,
      lineWeightFidelity: stroke.lineWeight == LineWeightType.silhouette ? 0.95 : 0.85,
    );
    widget.onProfileUpdated();

    setState(() {
      _strokes.add(stroke);
      _showTooltip = false;
    });
  }

  void _openGuide() {
    ConceptGuideSheet.show(
      context: context,
      drillTitle: 'Isometric Carve-Outs & Line Weight',
      categorySubtitle: 'Technical Draftsmanship (ISO Standard)',
      theme: widget.theme,
      sections: const [
        GuideSectionItem(
          title: 'The Subtractive Block-Out Method',
          content:
              'In mechanical engineering, you never draw complex features in empty air. Always visualize the maximum bounding volume (the raw billet of aluminum or 3D print boundary), then slice away negative space.',
          icon: Icons.view_in_ar_rounded,
        ),
        GuideSectionItem(
          title: 'Strict Line Weight Hierarchy',
          content:
              '• Thick Silhouette (3.5px): The outer boundary separating the object from background space.\n• Medium Crease (2.0px): Internal intersecting planes and step changes.\n• Dashed Hidden (1.2px): Occluded internal geometry and rear edges.',
          icon: Icons.line_weight_rounded,
        ),
        GuideSectionItem(
          title: 'Parallelism Rule',
          content:
              'In isometric projection, all parallel edges stay strictly parallel forever (no vanishing point). Vertical edges are 90°, horizontal edges follow 30° and 150° diagonals.',
          icon: Icons.straighten_rounded,
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
          gridType: GridType.isometric, // Force isometric grid for this drill
          currentLineWeight: _activeLineWeight,
          strokes: _strokes,
          onStrokeCompleted: _handleStrokeCompleted,
          backgroundDrillOverlay: CustomPaint(
            painter: _IsometricVoxelPainter(
              theme: theme,
              seed: _seed,
            ),
          ),
        ),

        if (_showTooltip)
          Positioned(
            top: 24,
            left: 24,
            child: CoachmarkTooltip(
              title: 'Isometric Carving Drill',
              message: 'Trace the outer silhouette with Thick lines, inner steps with Medium, and hidden with Dashed.',
              theme: theme,
              onDismiss: () => setState(() => _showTooltip = false),
              onOpenGuide: _openGuide,
            ),
          ),

        // Bottom Line-Weight Selector & HUD
        Positioned(
          bottom: 28,
          left: 24,
          right: 24,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 720),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                    'LINE HIERARCHY:',
                    style: theme.monoStyle.copyWith(
                      fontSize: 10,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                      color: theme.secondaryInk,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Segmented Line Weight Buttons
                  ...LineWeightType.values.where((w) => w != LineWeightType.dimension).map((weight) {
                    final isSelected = _activeLineWeight == weight;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _activeLineWeight = weight),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.borderHighlight : theme.canvasBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? theme.borderHighlight : theme.borderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: weight == LineWeightType.silhouette ? 4 : (weight == LineWeightType.crease ? 2.5 : 1.5),
                                color: isSelected ? Colors.white : theme.defaultInk,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                weight.label.split(' ').first,
                                style: theme.headingStyle.copyWith(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : theme.defaultInk,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const Spacer(),

                  // Actions: Clear / New Part
                  IconButton(
                    icon: Icon(Icons.undo, color: theme.secondaryInk, size: 20),
                    onPressed: _strokes.isNotEmpty
                        ? () => setState(() => _strokes.removeLast())
                        : null,
                    tooltip: 'Undo Stroke',
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.borderHighlight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: _generateNewObject,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(
                      'New Billet',
                      style: theme.headingStyle.copyWith(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _IsometricVoxelPainter extends CustomPainter {
  final AppThemeTokens theme;
  final int seed;

  _IsometricVoxelPainter({
    required this.theme,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(2000, 2000);
    const voxelSize = 65.0;

    final faintPaint = Paint()
      ..color = theme.reticleColor.withOpacity(0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = theme.accentCyan.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Draw an L-shaped stepped bracket or carved isometric volume
    final origin = Offset(center.dx, center.dy + 80);

    Offset iso(double x, double y, double z) {
      const cos30 = 0.86602540378;
      const sin30 = 0.5;
      final px = origin.dx + (x - y) * voxelSize * cos30;
      final py = origin.dy + (x + y) * voxelSize * sin30 - z * voxelSize;
      return Offset(px, py);
    }

    void drawBox(double x, double y, double z, double sx, double sy, double sz) {
      final p000 = iso(x, y, z);
      final p100 = iso(x + sx, y, z);
      final p110 = iso(x + sx, y + sy, z);
      final p010 = iso(x, y + sy, z);

      final p001 = iso(x, y, z + sz);
      final p101 = iso(x + sx, y, z + sz);
      final p111 = iso(x + sx, y + sy, z + sz);
      final p011 = iso(x, y + sy, z + sz);

      // Top face
      final top = Path()..moveTo(p001.dx, p001.dy)..lineTo(p101.dx, p101.dy)..lineTo(p111.dx, p111.dy)..lineTo(p011.dx, p011.dy)..close();
      canvas.drawPath(top, fillPaint);
      canvas.drawPath(top, faintPaint);

      // Left face
      final left = Path()..moveTo(p000.dx, p000.dy)..lineTo(p010.dx, p010.dy)..lineTo(p011.dx, p011.dy)..lineTo(p001.dx, p001.dy)..close();
      canvas.drawPath(left, fillPaint);
      canvas.drawPath(left, faintPaint);

      // Right face
      final right = Path()..moveTo(p100.dx, p100.dy)..lineTo(p110.dx, p110.dy)..lineTo(p111.dx, p111.dy)..lineTo(p101.dx, p101.dy)..close();
      canvas.drawPath(right, fillPaint);
      canvas.drawPath(right, faintPaint);

      // Remaining vertical edges
      canvas.drawLine(p000, p100, faintPaint);
      canvas.drawLine(p110, p010, faintPaint);
    }

    // Procedural carved shape: Base block (3x2x1) + Vertical riser (1x2x2)
    final rand = math.Random(seed);
    final variant = rand.nextInt(3);

    if (variant == 0) {
      // Stepped L-bracket
      drawBox(0, 0, 0, 3, 2, 1);
      drawBox(0, 0, 1, 1, 2, 2);
    } else if (variant == 1) {
      // Channel / Slot mount
      drawBox(0, 0, 0, 3, 3, 1);
      drawBox(0, 0, 1, 1, 3, 2);
      drawBox(2, 0, 1, 1, 3, 2);
    } else {
      // Notch carved cube
      drawBox(0, 0, 0, 3, 3, 2);
      drawBox(1, 0, 2, 2, 3, 1);
    }
  }

  @override
  bool shouldRepaint(covariant _IsometricVoxelPainter oldDelegate) => oldDelegate.seed != seed;
}
