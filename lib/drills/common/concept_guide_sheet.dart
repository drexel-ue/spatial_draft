import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GuideSectionItem {
  final String title;
  final String content;
  final IconData icon;

  const GuideSectionItem({
    required this.title,
    required this.content,
    required this.icon,
  });
}

class ConceptGuideSheet extends StatelessWidget {
  final String drillTitle;
  final String categorySubtitle;
  final List<GuideSectionItem> sections;
  final AppThemeTokens theme;

  const ConceptGuideSheet({
    super.key,
    required this.drillTitle,
    required this.categorySubtitle,
    required this.sections,
    required this.theme,
  });

  static void show({
    required BuildContext context,
    required String drillTitle,
    required String categorySubtitle,
    required List<GuideSectionItem> sections,
    required AppThemeTokens theme,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConceptGuideSheet(
        drillTitle: drillTitle,
        categorySubtitle: categorySubtitle,
        sections: sections,
        theme: theme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 680,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: theme.surfaceBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderSubtle, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.secondaryInk.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.accentCyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.menu_book_outlined, color: theme.accentCyan, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categorySubtitle.toUpperCase(),
                        style: theme.monoStyle.copyWith(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          color: theme.accentCyan,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        drillTitle,
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
          ),

          const Divider(height: 1),

          // Content List
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              itemCount: sections.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 20),
              itemBuilder: (ctx, index) {
                final section = sections[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.canvasBackground.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.surfaceBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.borderSubtle),
                        ),
                        child: Icon(section.icon, size: 18, color: theme.borderHighlight),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: theme.headingStyle.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              section.content,
                              style: theme.bodyStyle.copyWith(
                                height: 1.45,
                                fontSize: 13,
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

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.borderHighlight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Got It, Return to Practice',
                  style: theme.headingStyle.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
