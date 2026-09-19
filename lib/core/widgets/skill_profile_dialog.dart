import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/skill_profile.dart';
import '../theme/app_theme.dart';

class SkillProfileDialog extends StatelessWidget {
  final SkillProfile profile;
  final AppThemeTokens theme;

  const SkillProfileDialog({
    super.key,
    required this.profile,
    required this.theme,
  });

  static void show({
    required BuildContext context,
    required SkillProfile profile,
    required AppThemeTokens theme,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: SkillProfileDialog(profile: profile, theme: theme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.surfaceBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.borderSubtle, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.accentCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.hub_rounded, color: theme.accentCyan, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEUROMOTOR PROFILE',
                        style: theme.monoStyle.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: theme.accentCyan,
                        ),
                      ),
                      Text(
                        'Dynamic Skill Matrix',
                        style: theme.headingStyle.copyWith(
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: theme.secondaryInk),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Radial Angle Proficiency Visualizer
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Polar Radar Wheel
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _PolarSkillPainter(
                      profile: profile,
                      theme: theme,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Radial Angle Proficiency',
                        style: theme.headingStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The wheel shows your precision and velocity consistency across all 16 drawing angles. Green rays indicate mastery; shorter/amber rays reveal where hesitation occurs.',
                        style: theme.bodyStyle.copyWith(
                          fontSize: 12,
                          color: theme.secondaryInk,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.accentAmber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.accentAmber.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radar_rounded, size: 14, color: theme.accentAmber),
                            const SizedBox(width: 6),
                            Text(
                              'Current Training Target: ${profile.getAdaptiveTargetAngle().toStringAsFixed(0)}°',
                              style: theme.monoStyle.copyWith(
                                fontSize: 11,
                                color: theme.accentAmber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Performance Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'OVERALL ACCURACY',
                    value: '${(profile.overallAccuracy * 100).round()}%',
                    subtitle: '${profile.totalStrokesCompleted} strokes analyzed',
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'FLOW CONSISTENCY',
                    value: '${(profile.overallVelocityConsistency * 100).round()}%',
                    subtitle: 'Velocity stability',
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'JITTER INDEX',
                    value: profile.averageJitter < 0.20 ? 'LOW' : 'MODERATE',
                    subtitle: 'Acceleration check',
                    theme: theme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Interconnected System Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.canvasBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 16, color: theme.accentCyan),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Feedback Loop Active: Drill generation weights automatically adapt to target your weak angles and reinforce 3D spatial muscle memory.',
                      style: theme.bodyStyle.copyWith(
                        fontSize: 11,
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final AppThemeTokens theme;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.canvasBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.monoStyle.copyWith(
              fontSize: 9,
              letterSpacing: 0.8,
              color: theme.secondaryInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.headingStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.borderHighlight,
            ),
          ),
          Text(
            subtitle,
            style: theme.bodyStyle.copyWith(
              fontSize: 11,
              color: theme.secondaryInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolarSkillPainter extends CustomPainter {
  final SkillProfile profile;
  final AppThemeTokens theme;

  _PolarSkillPainter({
    required this.profile,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 8;

    final gridPaint = Paint()
      ..color = theme.borderSubtle
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Rings
    canvas.drawCircle(center, maxRadius * 0.33, gridPaint);
    canvas.drawCircle(center, maxRadius * 0.66, gridPaint);
    canvas.drawCircle(center, maxRadius, gridPaint);

    // 16 radial spoke lines with score heights
    final fillPath = Path();
    for (int i = 0; i < 16; i++) {
      final sector = profile.angleSectors[i];
      final angleRad = (sector.centerAngleDegrees) * math.pi / 180.0;
      final scoreRadius = maxRadius * (sector.averageAccuracy.clamp(0.2, 1.0));

      final pt = Offset(
        center.dx + math.cos(angleRad) * scoreRadius,
        center.dy + math.sin(angleRad) * scoreRadius,
      );

      if (i == 0) {
        fillPath.moveTo(pt.dx, pt.dy);
      } else {
        fillPath.lineTo(pt.dx, pt.dy);
      }

      // Spoke line
      final spokePaint = Paint()
        ..color = sector.averageAccuracy >= 0.8 ? theme.success.withOpacity(0.6) : theme.warning.withOpacity(0.6)
        ..strokeWidth = 1.8;
      canvas.drawLine(center, pt, spokePaint);
    }
    fillPath.close();

    final radarFill = Paint()
      ..color = theme.accentCyan.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, radarFill);

    final radarStroke = Paint()
      ..color = theme.accentCyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(fillPath, radarStroke);
  }

  @override
  bool shouldRepaint(covariant _PolarSkillPainter oldDelegate) => true;
}
