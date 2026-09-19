import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../canvas/interactive_canvas.dart';
import '../../core/models/skill_profile.dart';
import '../../core/models/stroke.dart';
import '../../core/theme/app_theme.dart';
import '../common/coachmark_tooltip.dart';
import '../common/concept_guide_sheet.dart';

class LoomisHeadDrill extends StatefulWidget {
  final AppThemeTokens theme;
  final GridStyle gridStyle;
  final GridType gridType;
  final SkillProfile skillProfile;
  final VoidCallback onProfileUpdated;

  const LoomisHeadDrill({
    super.key,
    required this.theme,
    required this.gridStyle,
    required this.gridType,
    required this.skillProfile,
    required this.onProfileUpdated,
  });

  @override
  State<LoomisHeadDrill> createState() => _LoomisHeadDrillState();
}

class _LoomisHeadDrillState extends State<LoomisHeadDrill> {
  final List<Stroke> _strokes = [];
  double _pitchDeg = 15.0; // Up/down tilt
  double _yawDeg = 35.0;   // Left/right rotation
  bool _showTooltip = true;

  @override
  void initState() {
    super.initState();
    _generateAdaptivePose();
  }

  void _generateAdaptivePose() {
    final rand = math.Random();
    // Interconnected feedback loop: higher ellipse accuracy unlocks wider yaw and pitch angles
    final difficulty = widget.skillProfile.ellipseAccuracy;
    final maxPitch = 15.0 + (difficulty * 30.0); // up to 45 deg
    final maxYaw = 20.0 + (difficulty * 50.0);   // up to 70 deg

    setState(() {
      _pitchDeg = (rand.nextDouble() - 0.5) * 2 * maxPitch;
      _yawDeg = (rand.nextDouble() - 0.5) * 2 * maxYaw;
      _strokes.clear();
    });
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
    ConceptGuideSheet.show(
      context: context,
      drillTitle: 'The Loomis Cranial Construction',
      categorySubtitle: 'Volumetric Form & Anatomy',
      theme: widget.theme,
      sections: const [
        GuideSectionItem(
          title: 'The Cranial Ball & Temporal Cut',
          content:
              'The cranium is a ball sheared flat on both sides. In perspective, these flat temporal planes appear as perspective ellipses. Notice how your perspective ellipse training applies directly here!',
          icon: Icons.sports_volleyball_rounded,
        ),
        GuideSectionItem(
          title: 'The Brow Line & Center Axis',
          content:
              'The brow line and facial center line are great circles on the sphere that intersect at 90°. The brow line establishes eye sockets and ear placement.',
          icon: Icons.face_rounded,
        ),
        GuideSectionItem(
          title: 'The Jaw Wedge',
          content:
              'From the temporal plane and brow line, drop the jaw lines down to meet at the chin wedge. Keep chin planes aligned with head pitch.',
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
          strokes: _strokes,
          onStrokeCompleted: _handleStrokeCompleted,
          backgroundDrillOverlay: CustomPaint(
            painter: _LoomisHeadPainter(
              pitchDeg: _pitchDeg,
              yawDeg: _yawDeg,
              theme: theme,
            ),
          ),
        ),

        if (_showTooltip)
          Positioned(
            top: 24,
            left: 24,
            child: CoachmarkTooltip(
              title: 'Loomis Head Construction',
              message: 'Trace the cranial sphere, temporal cut ellipse, and jaw wedge in perspective.',
              theme: theme,
              onDismiss: () => setState(() => _showTooltip = false),
              onOpenGuide: _openGuide,
            ),
          ),

        // Bottom Angle HUD & Next Pose
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.accentCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.face_retouching_natural_rounded, color: theme.accentCyan, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '3D HEAD ORIENTATION',
                        style: theme.monoStyle.copyWith(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          color: theme.secondaryInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Pitch: ${_pitchDeg.toStringAsFixed(0)}°  •  Yaw: ${_yawDeg.toStringAsFixed(0)}°',
                        style: theme.headingStyle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.undo, color: theme.secondaryInk, size: 20),
                    onPressed: _strokes.isNotEmpty
                        ? () => setState(() => _strokes.removeLast())
                        : null,
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
                    onPressed: _generateAdaptivePose,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(
                      'Next Rotation',
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

class _LoomisHeadPainter extends CustomPainter {
  final double pitchDeg;
  final double yawDeg;
  final AppThemeTokens theme;

  _LoomisHeadPainter({
    required this.pitchDeg,
    required this.yawDeg,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(2000, 2000);
    const radius = 130.0;

    final faintLine = Paint()
      ..color = theme.reticleColor.withOpacity(0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final accentLine = Paint()
      ..color = theme.accentAmber.withOpacity(0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = theme.accentCyan.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    // 1. Cranial Ball (Main Sphere)
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, faintLine);

    final pitchRad = pitchDeg * math.pi / 180.0;
    final yawRad = yawDeg * math.pi / 180.0;

    // 2. Temporal Flat Cut (Perspective Ellipse)
    final temporalCenterX = center.dx + math.sin(yawRad) * radius * 0.7;
    final temporalCenterY = center.dy - math.sin(pitchRad) * radius * 0.3;
    final temporalCenter = Offset(temporalCenterX, temporalCenterY);

    final temporalWidth = radius * 0.45 * math.cos(yawRad).abs().clamp(0.2, 1.0);
    final temporalHeight = radius * 0.65;

    canvas.save();
    canvas.translate(temporalCenter.dx, temporalCenter.dy);
    canvas.rotate(-pitchRad * 0.4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: temporalWidth * 2, height: temporalHeight * 2),
      faintLine,
    );
    // Crosshairs on temporal plane
    canvas.drawLine(Offset(-temporalWidth, 0), Offset(temporalWidth, 0), faintLine);
    canvas.drawLine(Offset(0, -temporalHeight), Offset(0, temporalHeight), faintLine);
    canvas.restore();

    // 3. Brow Line (Great circle wrapped around sphere)
    final browY = center.dy - math.sin(pitchRad) * radius * 0.6;
    final browPath = Path();
    browPath.moveTo(center.dx - radius, center.dy);
    browPath.quadraticBezierTo(
      center.dx + math.sin(yawRad) * radius * 0.5,
      browY,
      center.dx + radius,
      center.dy,
    );
    canvas.drawPath(browPath, accentLine);

    // 4. Facial Centerline
    final faceCenterX = center.dx + math.sin(yawRad) * radius * 0.8;
    final centerLine = Path();
    centerLine.moveTo(center.dx, center.dy - radius);
    centerLine.quadraticBezierTo(
      faceCenterX,
      center.dy,
      center.dx + math.sin(yawRad) * radius * 0.6,
      center.dy + radius * 1.5, // Chin tip
    );
    canvas.drawPath(centerLine, faintLine);

    // 5. Jawline & Chin Wedge
    final chinTip = Offset(center.dx + math.sin(yawRad) * radius * 0.5, center.dy + radius * 1.55);
    final jawLeft = Offset(center.dx - radius * 0.85, center.dy + radius * 0.3);
    final jawRight = Offset(center.dx + radius * 0.85, center.dy + radius * 0.3);

    final jawPath = Path()
      ..moveTo(jawLeft.dx, jawLeft.dy)
      ..lineTo(chinTip.dx - 20, chinTip.dy)
      ..lineTo(chinTip.dx + 20, chinTip.dy)
      ..lineTo(jawRight.dx, jawRight.dy);
    canvas.drawPath(jawPath, faintLine);
  }

  @override
  bool shouldRepaint(covariant _LoomisHeadPainter oldDelegate) =>
      oldDelegate.pitchDeg != pitchDeg || oldDelegate.yawDeg != yawDeg;
}
