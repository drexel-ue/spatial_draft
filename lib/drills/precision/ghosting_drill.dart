import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spatial_draft/analysis/kinematic_analyzer.dart';
import 'package:spatial_draft/canvas/interactive_canvas.dart';
import 'package:spatial_draft/core/models/skill_profile.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';
import 'package:spatial_draft/drills/common/coachmark_tooltip.dart';
import 'package:spatial_draft/drills/common/concept_guide_sheet.dart';

class GhostingDrill extends StatefulWidget {

  const GhostingDrill({
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
  State<GhostingDrill> createState() => _GhostingDrillState();
}

class _GhostingDrillState extends State<GhostingDrill> with SingleTickerProviderStateMixin {
  late Offset _p1;
  late Offset _p2;
  final List<Stroke> _strokes = [];
  GhostingAnalysisResult? _lastResult;
  bool _showTooltip = true;
  final bool _showHeatmap = true;

  late AnimationController _reticlePulseController;

  @override
  void initState() {
    super.initState();
    _reticlePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _generateNewReticles();
  }

  @override
  void dispose() {
    _reticlePulseController.dispose();
    super.dispose();
  }

  void _generateNewReticles() {
    // Obtain adaptive angle from user's skill profile
    final targetAngleDeg = widget.skillProfile.getAdaptiveTargetAngle();
    final angleRad = targetAngleDeg * (math.pi / 180.0);

    // Canvas center inside the 4000x4000 coordinate space
    const center = Offset(2000, 2000);
    final random = math.Random();
    final strokeLength = 320.0 + random.nextDouble() * 260.0; // 320 to 580 px

    final halfLength = strokeLength / 2.0;
    final dx = math.cos(angleRad) * halfLength;
    final dy = math.sin(angleRad) * halfLength;

    setState(() {
      _p1 = Offset(center.dx - dx, center.dy - dy);
      _p2 = Offset(center.dx + dx, center.dy + dy);
      _strokes.clear();
      _lastResult = null;
    });
  }

  void _handleStrokeCompleted(Stroke stroke) {
    if (stroke.points.length < 2) return;

    final analysis = KinematicAnalyzer.analyzeGhosting(
      stroke: stroke,
      p1: _p1,
      p2: _p2,
    );

    // Create a heatmapped copy of the stroke
    final heatmappedStroke = Stroke(
      points: stroke.points,
      color: stroke.color,
      lineWeight: stroke.lineWeight,
      segmentColors: analysis.heatmapColors,
    );

    widget.skillProfile.recordGhostingAnalysis(
      angleRadians: analysis.strokeAngleRadians,
      accuracy: analysis.linearAccuracy,
      jitter: analysis.jitterIndex,
      velocityConsistency: analysis.velocityConsistency,
    );
    widget.onProfileUpdated();

    setState(() {
      _strokes.clear();
      _strokes.add(heatmappedStroke);
      _lastResult = analysis;
      _showTooltip = false; // Auto dismiss after first stroke
    });
  }

  void _openGuide() {
    ConceptGuideSheet.show(
      context: context,
      drillTitle: 'The Ghosting Method',
      categorySubtitle: 'Motor Control & Kinematics',
      theme: widget.theme,
      sections: const [
        GuideSectionItem(
          title: 'The Shoulder Mechanism',
          content:
              'Lock your wrist and elbow joints. Your shoulder is a large ball-and-socket joint that produces true straight trajectories across wide digital surfaces.',
          icon: Icons.fitness_center_rounded,
        ),
        GuideSectionItem(
          title: 'The Ghosting Protocol',
          content:
              'Hover the Apple Pencil 2 to 3 times along the vector without touching the screen. Inhale on the hover, exhale and strike through in one unbroken motion.',
          icon: Icons.air_rounded,
        ),
        GuideSectionItem(
          title: 'Scoring: Velocity Over Correction',
          content:
              'Our engine differentiates acceleration (d²s/dt²). Slow, hesitant course-corrections generate high jitter penalties. A confident, fast stroke with minor angle offset is far superior to a wavy line that hits the bullseye.',
          icon: Icons.speed_rounded,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Stack(
      children: [
        // Interactive Canvas with custom drill overlay
        InteractiveCanvas(
          theme: theme,
          gridStyle: widget.gridStyle,
          gridType: widget.gridType,
          strokes: _strokes,
          showHeatmap: _showHeatmap,
          onStrokeCompleted: _handleStrokeCompleted,
          backgroundDrillOverlay: CustomPaint(
            painter: _GhostingOverlayPainter(
              p1: _p1,
              p2: _p2,
              theme: theme,
              pulseAnimation: _reticlePulseController,
            ),
          ),
        ),

        // Floating Contextual Coachmark Tooltip
        if (_showTooltip)
          Positioned(
            top: 24,
            left: 24,
            child: CoachmarkTooltip(
              title: 'Ghosting Practice',
              message: 'Hover 2–3 times over the line before committing. Draw with your shoulder.',
              theme: theme,
              onDismiss: () => setState(() => _showTooltip = false),
              onOpenGuide: _openGuide,
            ),
          ),

        // Live Scoring HUD Panel
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
                      // Score Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _scoreColor(_lastResult!.overallScorePercent, theme).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _scoreColor(_lastResult!.overallScorePercent, theme).withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_lastResult!.overallScorePercent}%',
                              style: theme.headingStyle.copyWith(
                                fontSize: 22,
                                color: _scoreColor(_lastResult!.overallScorePercent, theme),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'OVERALL',
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

                      // Metrics Breakdown
                      _MetricItem(
                        label: 'PRECISION',
                        value: '${(_lastResult!.linearAccuracy * 100).round()}%',
                        detail: '±${_lastResult!.averageDeviationPx.toStringAsFixed(1)}px',
                        theme: theme,
                      ),
                      const SizedBox(width: 20),
                      _MetricItem(
                        label: 'VELOCITY',
                        value: '${(_lastResult!.velocityConsistency * 100).round()}%',
                        detail: 'Flow consistency',
                        theme: theme,
                      ),
                      const SizedBox(width: 20),
                      _MetricItem(
                        label: 'JITTER INDEX',
                        value: _lastResult!.jitterIndex < 0.15 ? 'LOW' : (_lastResult!.jitterIndex < 0.35 ? 'MOD' : 'HIGH'),
                        detail: 'Hesitation check',
                        theme: theme,
                        valueColor: _lastResult!.jitterIndex < 0.2 ? theme.success : theme.warning,
                      ),

                      const SizedBox(width: 24),

                      // Actions: Next Reticle
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.borderHighlight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: _generateNewReticles,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          'Next Reticle',
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

  Color _scoreColor(int score, AppThemeTokens theme) {
    if (score >= 85) return theme.success;
    if (score >= 70) return theme.warning;
    return theme.danger;
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

class _GhostingOverlayPainter extends CustomPainter {

  _GhostingOverlayPainter({
    required this.p1,
    required this.p2,
    required this.theme,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);
  final Offset p1;
  final Offset p2;
  final AppThemeTokens theme;
  final Animation<double> pulseAnimation;

  @override
  void paint(Canvas canvas, Size size) {
    // Faint baseline connecting P1 and P2
    final guidePaint = Paint()
      ..color = theme.reticleColor.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p1, p2, guidePaint);

    // Reticle P1 (Origin)
    _drawReticle(canvas, p1, 'ORIGIN', isOrigin: true);

    // Reticle P2 (Target)
    _drawReticle(canvas, p2, 'TARGET', isOrigin: false);
  }

  void _drawReticle(Canvas canvas, Offset center, String label, {required bool isOrigin}) {
    final reticlePaint = Paint()
      ..color = theme.reticleColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final pulseRadius = 14.0 + (pulseAnimation.value * 4.0);

    // Outer crosshairs
    const arm = 18.0;
    canvas.drawLine(Offset(center.dx - arm, center.dy), Offset(center.dx + arm, center.dy), reticlePaint);
    canvas.drawLine(Offset(center.dx, center.dy - arm), Offset(center.dx, center.dy + arm), reticlePaint);

    // Outer circle
    canvas.drawCircle(center, 12.0, reticlePaint);

    // Faint pulsing echo
    final echoPaint = Paint()
      ..color = theme.reticleColor.withOpacity(0.25 * (1.0 - pulseAnimation.value))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, pulseRadius, echoPaint);

    // Inner bullseye dot
    final dotPaint = Paint()
      ..color = isOrigin ? theme.accentAmber : theme.accentCyan
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _GhostingOverlayPainter oldDelegate) => true;
}
