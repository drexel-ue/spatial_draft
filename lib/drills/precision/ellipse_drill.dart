import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/analysis/kinematic_analyzer.dart';
import 'package:spatial_draft/canvas/interactive_canvas.dart';
import 'package:spatial_draft/core/models/skill_profile.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/drills/common/coachmark_tooltip.dart';
import 'package:spatial_draft/drills/common/concept_guide_sheet.dart';

class EllipseDrill extends StatefulWidget {

  const EllipseDrill({
    super.key,
    required this.theme,
    required this.gridStyle,
    required this.gridType,
    required this.skillProfile,
    required this.onProfileUpdated,
  });
  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final SkillProfile skillProfile;
  final VoidCallback onProfileUpdated;

  @override
  State<EllipseDrill> createState() => _EllipseDrillState();
}

class _EllipseDrillState extends State<EllipseDrill> {
  late List<Offset> _quadCorners; // 4 corners in clockwise order
  late double _expectedMinorAxisDeg;
  final List<Stroke> _strokes = [];
  EllipseAnalysisResult? _lastResult;
  bool _showTooltip = true;

  @override
  void initState() {
    super.initState();
    _generatePerspectivePlane();
  }

  void _generatePerspectivePlane() {
    const center = Offset(2000, 2000);
    final random = math.Random();

    // Randomize width, height, and perspective tilt
    final baseWidth = 240.0 + random.nextDouble() * 140.0;
    final baseHeight = 160.0 + random.nextDouble() * 120.0;
    final tiltAngle = (random.nextDouble() - 0.5) * 45.0; // -22.5 to +22.5 deg
    final tiltRad = tiltAngle * math.pi / 180.0;

    // Perspective foreshortening: top edge narrower than bottom edge
    final taper = 0.65 + random.nextDouble() * 0.25;

    final topHalfW = (baseWidth * taper) / 2.0;
    final botHalfW = baseWidth / 2.0;
    final halfH = baseHeight / 2.0;

    // Generate quadrilateral corners relative to center
    final unrotated = [
      Offset(-topHalfW, -halfH), // Top-left
      Offset(topHalfW, -halfH),  // Top-right
      Offset(botHalfW, halfH),   // Bottom-right
      Offset(-botHalfW, halfH),  // Bottom-left
    ];

    // Rotate and translate to canvas center
    _quadCorners = unrotated.map((pt) {
      final rx = pt.dx * math.cos(tiltRad) - pt.dy * math.sin(tiltRad);
      final ry = pt.dx * math.sin(tiltRad) + pt.dy * math.cos(tiltRad);
      return Offset(center.dx + rx, center.dy + ry);
    }).toList();

    // Expected minor axis angle is perpendicular to the major axis
    _expectedMinorAxisDeg = (tiltAngle + 90.0) % 180.0;

    setState(() {
      _strokes.clear();
      _lastResult = null;
    });
  }

  void _handleStrokeCompleted(Stroke stroke) {
    if (stroke.points.length < 8) return;

    final result = KinematicAnalyzer.analyzePerspectiveEllipse(
      stroke: stroke,
      quadCorners: _quadCorners,
      expectedMinorAxisAngleDeg: _expectedMinorAxisDeg,
    );

    widget.skillProfile.recordEllipseAnalysis(
      accuracy: result.overallAccuracy,
      minorAxisErrorDeg: result.minorAxisErrorDeg,
      eccentricity: 0.5,
    );
    widget.onProfileUpdated();

    setState(() {
      _strokes.clear();
      _strokes.add(stroke);
      _lastResult = result;
      _showTooltip = false;
    });
  }

  void _openGuide() {
    ConceptGuideSheet.show(
      context: context,
      drillTitle: 'Perspective Ellipses',
      categorySubtitle: 'Spatial Volume & Form',
      theme: widget.theme,
      sections: const [
        GuideSectionItem(
          title: 'The Minor Axis Rule',
          content:
              'The minor axis (the shortest diameter across the ellipse) must ALWAYS align with the rotational axis (axle) of the cylinder in 3D space. If your ellipse is rotated off this axis, the cylinder looks warped or broken.',
          icon: Icons.rotate_right_rounded,
        ),
        GuideSectionItem(
          title: 'Perspective Contact Tangents',
          content:
              'In perspective, the widest part of an ellipse is NOT on the geometric center line of the bounding box—it is pushed slightly toward the viewer due to foreshortening. Touch all 4 walls with smooth curved contacts.',
          icon: Icons.border_clear_rounded,
        ),
        GuideSectionItem(
          title: 'Execution: Draw Through The Shape',
          content:
              'Do not draw slowly around the rim. Lock your wrist and loop around the ellipse two full rotations with continuous shoulder motion. Let the second pass tighten into place.',
          icon: Icons.loop_rounded,
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
          strokes: _strokes,
          onStrokeCompleted: _handleStrokeCompleted,
          backgroundDrillOverlay: CustomPaint(
            painter: _PerspectivePlanePainter(
              quadCorners: _quadCorners,
              theme: theme,
            ),
          ),
        ),

        if (_showTooltip)
          Positioned(
            top: 24,
            left: 24,
            child: CoachmarkTooltip(
              title: 'Perspective Ellipse Drill',
              message: 'Draw a smooth ellipse touching all 4 edges. Align with the perspective diagonals.',
              theme: theme,
              onDismiss: () => setState(() => _showTooltip = false),
              onOpenGuide: _openGuide,
            ),
          ),

        if (_lastResult != null)
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 720),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: (_lastResult!.passed ? theme.success : theme.warning).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_lastResult!.passed ? theme.success : theme.warning).withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_lastResult!.overallScorePercent}%',
                              style: theme.headingStyle.copyWith(
                                fontSize: 22,
                                color: _lastResult!.passed ? theme.success : theme.warning,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'ACCURACY',
                              style: theme.monoStyle.copyWith(
                                fontSize: 9,
                                letterSpacing: 0.8,
                                color: theme.secondaryInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      _MetricItem(
                        label: 'TANGENCY',
                        value: '${(_lastResult!.tangencyScore * 100).round()}%',
                        detail: 'Wall contact',
                        theme: theme,
                      ),
                      const SizedBox(width: 20),
                      _MetricItem(
                        label: 'AXIS DELTA',
                        value: '${_lastResult!.minorAxisErrorDeg.toStringAsFixed(1)}°',
                        detail: 'Minor axis deviation',
                        theme: theme,
                        valueColor: _lastResult!.minorAxisErrorDeg < 8 ? theme.success : theme.warning,
                      ),

                      const SizedBox(width: 24),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.borderHighlight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: _generatePerspectivePlane,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          'Next Plane',
                          style: theme.headingStyle.copyWith(
                            fontSize: 13,
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
          ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {

  const _MetricItem({
    required this.label,
    required this.value,
    required this.detail,
    required this.theme,
    this.valueColor,
  });
  final String label;
  final String value;
  final String detail;
  final AppThemeTokens theme;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.monoStyle.copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
            color: theme.secondaryInk,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.headingStyle.copyWith(
            fontSize: 16,
            color: valueColor ?? theme.headingStyle.color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          detail,
          style: theme.bodyStyle.copyWith(
            fontSize: 11,
            color: theme.secondaryInk,
          ),
        ),
      ],
    );
  }
}

class _PerspectivePlanePainter extends CustomPainter {

  _PerspectivePlanePainter({
    required this.quadCorners,
    required this.theme,
  });
  final List<Offset> quadCorners;
  final AppThemeTokens theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (quadCorners.length < 4) return;

    final quadPath = Path()
      ..moveTo(quadCorners[0].dx, quadCorners[0].dy)
      ..lineTo(quadCorners[1].dx, quadCorners[1].dy)
      ..lineTo(quadCorners[2].dx, quadCorners[2].dy)
      ..lineTo(quadCorners[3].dx, quadCorners[3].dy)
      ..close();

    // Faint plane fill
    final fillPaint = Paint()
      ..color = theme.accentCyan.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    canvas.drawPath(quadPath, fillPaint);

    // Quad bounding border
    final borderPaint = Paint()
      ..color = theme.reticleColor.withOpacity(0.6)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(quadPath, borderPaint);

    // Diagonal perspective crosshairs (Finding the true perspective center)
    final crossPaint = Paint()
      ..color = theme.secondaryInk.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(quadCorners[0], quadCorners[2], crossPaint);
    canvas.drawLine(quadCorners[1], quadCorners[3], crossPaint);

    // Midpoint cross lines (Perspective axes)
    final midTop = Offset((quadCorners[0].dx + quadCorners[1].dx) / 2, (quadCorners[0].dy + quadCorners[1].dy) / 2);
    final midBot = Offset((quadCorners[3].dx + quadCorners[2].dx) / 2, (quadCorners[3].dy + quadCorners[2].dy) / 2);
    final midLeft = Offset((quadCorners[0].dx + quadCorners[3].dx) / 2, (quadCorners[0].dy + quadCorners[3].dy) / 2);
    final midRight = Offset((quadCorners[1].dx + quadCorners[2].dx) / 2, (quadCorners[1].dy + quadCorners[2].dy) / 2);

    final axisPaint = Paint()
      ..color = theme.accentAmber.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(midTop, midBot, axisPaint);
    canvas.drawLine(midLeft, midRight, axisPaint);
  }

  @override
  bool shouldRepaint(covariant _PerspectivePlanePainter oldDelegate) => true;
}
