import 'package:flutter/material.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({
    super.key,
    required this.onFinish,
  });
  final VoidCallback onFinish;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.90, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) widget.onFinish();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navyBg = Color(0xFF07152B);
    const cyanAccent = Color(0xFF38BDF8);

    return Scaffold(
      backgroundColor: navyBg,
      body: GestureDetector(
        onTap: widget.onFinish, // Allow instant skip
        child: Stack(
          children: [
            // 1. Procedural Blueprint Coordinate Grid
            Positioned.fill(
              child: CustomPaint(
                painter: _BlueprintSplashGridPainter(),
              ),
            ),

            // 2. Center Content with animated breathing and scaling
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Glowing Icon Container
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: cyanAccent.withValues(alpha: 0.35),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // App Title
                          Text(
                            'SPATIAL DRAFT',
                            style: AppThemeTokens.createHeadingStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4.0,
                              color: const Color(0xFFF0F9FF),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'ADAPTIVE KINEMATIC DRAFTING',
                            style: AppThemeTokens.createMonoStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.8,
                              color: const Color(0xFF7DD3FC),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Animated Drafting Laser Line
                          SizedBox(
                            width: 240,
                            height: 4,
                            child: Stack(
                              children: [
                                Container(
                                  width: 240,
                                  height: 2,
                                  color: const Color(0xFF1E3A8A),
                                ),
                                Container(
                                  width: 240 * _laserAnimation.value,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Colors.white],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cyanAccent.withValues(alpha: 0.8),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'CALIBRATING NEUROMOTOR ENGINE...',
                            style: AppThemeTokens.createMonoStyle(
                              fontSize: 9,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Skip Pill (top right)
            Positioned(
              top: 24,
              right: 24,
              child: SafeArea(
                child: TextButton(
                  onPressed: widget.onFinish,
                  child: Text(
                    'Skip ➔',
                    style: AppThemeTokens.createMonoStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
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

class _BlueprintSplashGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 36.0;
    final gridPaint = Paint()
      ..color = const Color(0xFF0E2A5C).withValues(alpha: 0.7)
      ..strokeWidth = 0.8;

    final majorGridPaint = Paint()
      ..color = const Color(0xFF1E3A8A).withValues(alpha: 0.85)
      ..strokeWidth = 1.2;

    int col = 0;
    for (double x = 0; x <= size.width; x += spacing) {
      final paint = (col % 4 == 0) ? majorGridPaint : gridPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      col++;
    }

    int row = 0;
    for (double y = 0; y <= size.height; y += spacing) {
      final paint = (row % 4 == 0) ? majorGridPaint : gridPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      row++;
    }

    // Corner drafting ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    const tickLen = 20.0;
    // Top-left
    canvas.drawLine(const Offset(20, 20), const Offset(20 + tickLen, 20), tickPaint);
    canvas.drawLine(const Offset(20, 20), const Offset(20, 20 + tickLen), tickPaint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - 20, size.height - 20), Offset(size.width - 20 - tickLen, size.height - 20), tickPaint);
    canvas.drawLine(Offset(size.width - 20, size.height - 20), Offset(size.width - 20, size.height - 20 - tickLen), tickPaint);
  }

  @override
  bool shouldRepaint(covariant _BlueprintSplashGridPainter oldDelegate) => false;
}
