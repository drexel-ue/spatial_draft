import 'package:flutter/material.dart';
import 'package:spatial_draft/core/models/stroke.dart';
import 'package:spatial_draft/core/theme/app_theme.dart';

/// Floating swatch bar and brush style selector for coloring & cel-shading.
class ColorPaletteDock extends StatelessWidget {
  /// Creates a [ColorPaletteDock].
  const ColorPaletteDock({
    super.key,
    required this.theme,
    required this.selectedColor,
    required this.onColorSelected,
    required this.selectedBrushStyle,
    required this.onBrushStyleChanged,
  });

  /// Curated palette for engineering drafting and anime cel-shading.
  static const List<Color> curatedSwatches = [
    Color(0xFF0F172A), // Deep Slate Ink
    Color(0xFFFFFFFF), // Titanium White / Highlight
    Color(0xFF00E5FF), // Electric Cyan / Blueprint
    Color(0xFFF59E0B), // Sunset Amber
    Color(0xFFEF4444), // Chakra Crimson
    Color(0xFF10B981), // Sage Leaf Green
    Color(0xFF3B82F6), // Royal Cobalt
    Color(0xFF8B5CF6), // Shadow Violet
  ];

  /// Active design tokens.
  final AppThemeTokens theme;

  /// Currently active drawing color.
  final Color selectedColor;

  /// Callback when a new color is selected.
  final ValueChanged<Color> onColorSelected;

  /// Currently active brush style (ink outline vs. cel wash).
  final LineBrushStyle selectedBrushStyle;

  /// Callback when brush style changes.
  final ValueChanged<LineBrushStyle> onBrushStyleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brush Style Toggle (Ink vs Wash)
          ...LineBrushStyle.values.map((style) {
            final isSelected = selectedBrushStyle == style;
            final isWash = style == LineBrushStyle.wash;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => onBrushStyleChanged(style),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.borderHighlight.withOpacity(0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? theme.borderHighlight
                          : theme.borderSubtle.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isWash
                            ? Icons.brush_rounded
                            : Icons.edit_outlined,
                        size: 14,
                        color: isSelected
                            ? theme.borderHighlight
                            : theme.secondaryInk,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isWash ? 'Wash' : 'Ink',
                        style: theme.monoStyle.copyWith(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? theme.defaultInk
                              : theme.secondaryInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: theme.borderSubtle,
          ),

          // Swatch circles
          ...curatedSwatches.map((swatch) {
            final isSelected = selectedColor.value == swatch.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () => onColorSelected(swatch),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.accentCyan
                          : Colors.white.withOpacity(0.25),
                      width: isSelected ? 2.2 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: swatch.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: swatch.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
