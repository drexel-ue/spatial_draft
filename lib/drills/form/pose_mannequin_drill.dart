import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../canvas/interactive_canvas.dart';
import '../../core/models/skill_profile.dart';
import '../../core/models/stroke.dart';
import '../../core/theme/app_theme.dart';
import '../common/coachmark_tooltip.dart';
import '../common/concept_guide_sheet.dart';

class PoseMannequinDrill extends StatefulWidget {
  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final SkillProfile skillProfile;
  final VoidCallback onProfileUpdated;

  const PoseMannequinDrill({
    super.key,
    required this.theme,
    required this.gridStyle,
    required this.gridType,
    required this.skillProfile,
    required this.onProfileUpdated,
  });

  @override
  State<PoseMannequinDrill> createState() => _PoseMannequinDrillState();
}

class _PoseMannequinDrillState extends State<PoseMannequinDrill> {
  final List<Stroke> _strokes = [];
  int _poseSeed = 1;
  bool _showTooltip = true;

  @override
  void initState() {
    super.initState();
    _poseSeed = math.Random().nextInt(1000);
  }

  void _undo() {
    setState(_strokes.removeLast);
  }

  void _generateNewPose() {
    setState(() {
      _poseSeed = math.Random().nextInt(1000);
      _strokes.clear();
    });
  }

  void _handleStrokeCompleted(Stroke stroke) {
    widget.skillProfile.recordFormAnalysis(accuracy: 0.88);
    widget.onProfileUpdated();
    setState(() {
      _strokes.add(stroke);
      _showTooltip = false;
    });
  }

  void _openGuide() {
    ConceptGuideSheet.show(
      context: context,
      drillTitle: 'Kinematic Gesture & Volumes',
      categorySubtitle: 'Dynamic Form & Bridgman Mannequin',
      theme: widget.theme,
      sections: const [
        GuideSectionItem(
          title: 'The Line of Action (Rhythm)',
          content:
              'Capture the primary force vector in one single sweeping stroke through the spine down into the weight-bearing leg. Do not worry about contours yet—capture the kinetic thrust.',
          icon: Icons.flash_on_rounded,
        ),
        GuideSectionItem(
          title: 'Opposing Tilts (Contrapposto)',
          content:
              'Notice how when the shoulder line tilts downward to the left, the pelvis line tilts upward to the left to maintain balance. The two core masses pinch on one side and stretch on the other.',
          icon: Icons.compare_arrows_rounded,
        ),
        GuideSectionItem(
          title: 'Cross-Contour Cylinders',
          content:
              'Limbs are cylinders in perspective. Draw wrapping contour bands (ellipses) across the biceps, forearms, and thighs to indicate 3D spatial direction toward or away from the viewer.',
          icon: Icons.blur_circular_rounded,
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
            painter: _MannequinPosePainter(
              seed: _poseSeed,
              theme: theme,
            ),
          ),
        ),

        if (_showTooltip)
          Positioned(
            top: 24,
            left: 24,
            child: CoachmarkTooltip(
              title: 'Dynamic Pose Practice',
              message: 'Trace the glowing Line of Action, then block in the ribcage and pelvis volumes.',
              theme: theme,
              onDismiss: () => setState(() => _showTooltip = false),
              onOpenGuide: _openGuide,
            ),
          ),

        Positioned(
          bottom: 28,
          left: 24,
          right: 24,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 720),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.accentCyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.directions_run_rounded, color: theme.accentCyan, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'DYNAMIC KINEMATIC POSE',
                          style: theme.monoStyle.copyWith(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: theme.secondaryInk,
                          ),
                        ),
                        Text(
                          'Contrapposto & Action Spline',
                          style: theme.headingStyle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: Icon(Icons.undo, color: theme.secondaryInk, size: 20),
                      onPressed: _strokes.isNotEmpty ? _undo : null,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.borderHighlight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _generateNewPose,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        'Next Pose',
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
        ),
      ],
    );
  }
}

class _MannequinPosePainter extends CustomPainter {
  final int seed;
  final AppThemeTokens theme;

  _MannequinPosePainter({
    required this.seed,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(2000, 2000);
    final rand = math.Random(seed);

    final actionLinePaint = Paint()
      ..color = theme.accentAmber.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final volumePaint = Paint()
      ..color = theme.reticleColor.withOpacity(0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final fillVolumePaint = Paint()
      ..color = theme.accentCyan.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Procedural Contrapposto / Action Angles
    final shoulderTiltDeg = (rand.nextDouble() - 0.5) * 35.0;
    final pelvisTiltDeg = -shoulderTiltDeg * (0.8 + rand.nextDouble() * 0.4); // Opposing tilt
    final spineCurveFactor = (rand.nextDouble() - 0.5) * 80.0;

    // Head
    final headCenter = Offset(center.dx, center.dy - 220);
    canvas.drawOval(Rect.fromCenter(center: headCenter, width: 60, height: 80), volumePaint);

    // Spine Line of Action
    final midRib = Offset(center.dx + spineCurveFactor * 0.4, center.dy - 110);
    final pelvisCenter = Offset(center.dx + spineCurveFactor, center.dy);

    final spinePath = Path()
      ..moveTo(headCenter.dx, headCenter.dy + 40)
      ..cubicTo(
        midRib.dx,
        midRib.dy,
        pelvisCenter.dx,
        pelvisCenter.dy - 50,
        pelvisCenter.dx,
        pelvisCenter.dy,
      );
    canvas.drawPath(spinePath, actionLinePaint);

    // Ribcage Egg Volume
    canvas.save();
    canvas.translate(midRib.dx, midRib.dy);
    canvas.rotate(shoulderTiltDeg * math.pi / 180.0);
    final ribRect = Rect.fromCenter(center: Offset.zero, width: 110, height: 140);
    canvas.drawOval(ribRect, fillVolumePaint);
    canvas.drawOval(ribRect, volumePaint);
    // Shoulder axis
    canvas.drawLine(const Offset(-75, -50), const Offset(75, -50), actionLinePaint);
    canvas.restore();

    // Pelvis Bowl Volume
    canvas.save();
    canvas.translate(pelvisCenter.dx, pelvisCenter.dy);
    canvas.rotate(pelvisTiltDeg * math.pi / 180.0);
    final pelRect = Rect.fromCenter(center: Offset.zero, width: 115, height: 90);
    canvas.drawRRect(RRect.fromRectAndRadius(pelRect, const Radius.circular(20)), fillVolumePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(pelRect, const Radius.circular(20)), volumePaint);
    // Pelvis axis
    canvas.drawLine(const Offset(-65, 0), const Offset(65, 0), actionLinePaint);
    canvas.restore();

    // Limbs (Dynamic gestures)
    final weightLegPath = Path()
      ..moveTo(pelvisCenter.dx - 40, pelvisCenter.dy + 30)
      ..lineTo(pelvisCenter.dx - 30, pelvisCenter.dy + 160) // Knee
      ..lineTo(pelvisCenter.dx - 20, pelvisCenter.dy + 280); // Ankle
    canvas.drawPath(weightLegPath, volumePaint);

    final freeLegPath = Path()
      ..moveTo(pelvisCenter.dx + 40, pelvisCenter.dy + 30)
      ..lineTo(pelvisCenter.dx + 80, pelvisCenter.dy + 150) // Bent knee
      ..lineTo(pelvisCenter.dx + 50, pelvisCenter.dy + 260); // Foot
    canvas.drawPath(freeLegPath, volumePaint);
  }

  @override
  bool shouldRepaint(covariant _MannequinPosePainter oldDelegate) => oldDelegate.seed != seed;
}
