import 'package:flutter/material.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

class CoachmarkTooltip extends StatelessWidget {

  const CoachmarkTooltip({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lightbulb_outline,
    required this.theme,
    required this.onDismiss,
    this.onOpenGuide,
  });
  final String title;
  final String message;
  final IconData icon;
  final AppThemeTokens theme;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenGuide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.surfaceGlass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderSubtle, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.accentCyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: theme.accentCyan),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.headingStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: theme.bodyStyle.copyWith(
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (onOpenGuide != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onOpenGuide,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(Icons.info_outline_rounded, size: 14, color: theme.accentCyan),
                label: Text(
                  'Guide',
                  style: theme.monoStyle.copyWith(
                    color: theme.accentCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: theme.secondaryInk),
              splashRadius: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: onDismiss,
              tooltip: 'Dismiss hint',
            ),
          ],
        ),
      ),
    );
  }
}
