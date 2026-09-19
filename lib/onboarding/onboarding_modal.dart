import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class OnboardingSlideData {
  final String tag;
  final String title;
  final String description;
  final IconData icon;
  final String takeaway;

  const OnboardingSlideData({
    required this.tag,
    required this.title,
    required this.description,
    required this.icon,
    required this.takeaway,
  });
}

class OnboardingModal extends StatefulWidget {
  final AppThemeTokens theme;
  final VoidCallback onComplete;

  const OnboardingModal({
    super.key,
    required this.theme,
    required this.onComplete,
  });

  static void show({
    required BuildContext context,
    required AppThemeTokens theme,
    required VoidCallback onComplete,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: OnboardingModal(theme: theme, onComplete: onComplete),
      ),
    );
  }

  @override
  State<OnboardingModal> createState() => _OnboardingModalState();
}

class _OnboardingModalState extends State<OnboardingModal> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingSlideData> _slides = const [
    OnboardingSlideData(
      tag: 'BIOMECHANICS 01',
      title: 'Shoulder Over Wrist',
      description:
          'Drawing on slick iPad glass creates natural jitter. To draw straight engineering lines and clean perspective geometry, lock your wrist completely and drive the Apple Pencil from your shoulder and elbow.',
      icon: Icons.accessibility_new_rounded,
      takeaway: 'Key rule: Wrist makes arcs; shoulder makes straight lines.',
    ),
    OnboardingSlideData(
      tag: 'THE GHOSTING METHOD 02',
      title: 'Practice Before Contact',
      description:
          'Before touching down on glass, hover your pencil tip 2–3 times between the reticles. Build the trajectory in muscle memory, then execute the line in one smooth, confident stroke.',
      icon: Icons.gesture_rounded,
      takeaway: 'Key rule: Never stop mid-stroke to course-correct.',
    ),
    OnboardingSlideData(
      tag: 'ADAPTIVE NEUROMOTOR ENGINE 03',
      title: 'Interconnected Skill Loop',
      description:
          'SpatialDraft calculates your speed consistency and wobble acceleration (d²s/dt²). Your radial angle proficiency directly shapes the procedural exercises in subsequent 3D and organic drills.',
      icon: Icons.auto_graph_rounded,
      takeaway: 'Key rule: Your weaknesses become your customized training path.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 520),
        decoration: BoxDecoration(
          color: theme.surfaceBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.borderSubtle, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.accentCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ORIENTATION',
                          style: theme.monoStyle.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: theme.accentCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onComplete();
                    },
                    child: Text(
                      'Skip Primer',
                      style: theme.monoStyle.copyWith(
                        color: theme.secondaryInk,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Slide PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (ctx, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(32, 20, 32, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.borderHighlight.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.borderHighlight.withOpacity(0.3)),
                          ),
                          child: Icon(slide.icon, color: theme.borderHighlight, size: 28),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          slide.tag,
                          style: theme.monoStyle.copyWith(
                            color: theme.accentAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          slide.title,
                          style: theme.headingStyle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
                          style: theme.bodyStyle.copyWith(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.canvasBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 16, color: theme.success),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  slide.takeaway,
                                  style: theme.bodyStyle.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.borderHighlight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentIndex == i ? 24 : 8,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentIndex == i ? theme.borderHighlight : theme.borderSubtle,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  // Actions
                  Row(
                    children: [
                      if (_currentIndex > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          child: Text(
                            'Back',
                            style: theme.headingStyle.copyWith(
                              fontSize: 13,
                              color: theme.secondaryInk,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.borderHighlight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (_currentIndex < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          } else {
                            Navigator.of(context).pop();
                            widget.onComplete();
                          }
                        },
                        child: Text(
                          _currentIndex == _slides.length - 1 ? 'Start Training ➔' : 'Next ➔',
                          style: theme.headingStyle.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
