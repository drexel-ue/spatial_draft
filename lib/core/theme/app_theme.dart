import 'package:flutter/material.dart';

enum AppThemeMode {
  light,
  dark,
  blueprint,
}

enum GridStyle {
  solid,
  dotted,
  dashed,
  none,
}

enum GridType {
  squareMetric,
  isometric,
  perspective,
}

class AppThemeTokens {

  const AppThemeTokens({
    required this.mode,
    required this.canvasBackground,
    required this.surfaceBackground,
    required this.surfaceGlass,
    required this.borderSubtle,
    required this.borderHighlight,
    required this.defaultInk,
    required this.secondaryInk,
    required this.accentCyan,
    required this.accentAmber,
    required this.success,
    required this.warning,
    required this.danger,
    required this.gridLineMajor,
    required this.gridLineMinor,
    required this.reticleColor,
    required this.headingStyle,
    required this.bodyStyle,
    required this.monoStyle,
  });
  final AppThemeMode mode;
  final Color canvasBackground;
  final Color surfaceBackground;
  final Color surfaceGlass;
  final Color borderSubtle;
  final Color borderHighlight;
  
  final Color defaultInk;
  final Color secondaryInk;
  final Color accentCyan;
  final Color accentAmber;
  final Color success;
  final Color warning;
  final Color danger;

  final Color gridLineMajor;
  final Color gridLineMinor;
  final Color reticleColor;

  final TextStyle headingStyle;
  final TextStyle bodyStyle;
  final TextStyle monoStyle;

  static TextStyle createHeadingStyle({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontFamilyFallback: const ['Outfit', 'sans-serif'],
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w700,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle createBodyStyle({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontFamilyFallback: const ['sans-serif'],
      color: color,
      fontSize: fontSize ?? 14,
      fontWeight: fontWeight ?? FontWeight.normal,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle createMonoStyle({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'JetBrainsMono',
      fontFamilyFallback: const ['FiraCode', 'monospace'],
      color: color,
      fontSize: fontSize ?? 12,
      fontWeight: fontWeight ?? FontWeight.normal,
      letterSpacing: letterSpacing,
    );
  }

  static AppThemeTokens light() {
    final baseHeading = createHeadingStyle(
      color: const Color(0xFF111827),
      fontWeight: FontWeight.w700,
    );
    final baseBody = createBodyStyle(
      color: const Color(0xFF374151),
      fontSize: 14,
    );
    final baseMono = createMonoStyle(
      color: const Color(0xFF1E293B),
      fontSize: 12,
    );

    return AppThemeTokens(
      mode: AppThemeMode.light,
      canvasBackground: const Color(0xFFF8F9FB), // Clean studio vellum
      surfaceBackground: const Color(0xFFFFFFFF),
      surfaceGlass: const Color(0xE6FFFFFF),
      borderSubtle: const Color(0xFFE2E8F0),
      borderHighlight: const Color(0xFF2563EB),
      defaultInk: const Color(0xFF111827), // Crisp graphite
      secondaryInk: const Color(0xFF64748B),
      accentCyan: const Color(0xFF0284C7),
      accentAmber: const Color(0xFFD97706),
      success: const Color(0xFF16A34A),
      warning: const Color(0xFFEA580C),
      danger: const Color(0xFFDC2626),
      gridLineMajor: const Color(0xFF94A3B8),
      gridLineMinor: const Color(0xFFCBD5E1),
      reticleColor: const Color(0xFF2563EB),
      headingStyle: baseHeading,
      bodyStyle: baseBody,
      monoStyle: baseMono,
    );
  }

  static AppThemeTokens dark() {
    final baseHeading = createHeadingStyle(
      color: const Color(0xFFF8FAFC),
      fontWeight: FontWeight.w700,
    );
    final baseBody = createBodyStyle(
      color: const Color(0xFFCBD5E1),
      fontSize: 14,
    );
    final baseMono = createMonoStyle(
      color: const Color(0xFFE2E8F0),
      fontSize: 12,
    );

    return AppThemeTokens(
      mode: AppThemeMode.dark,
      canvasBackground: const Color(0xFF0F1115), // Deep studio obsidian
      surfaceBackground: const Color(0xFF181A20),
      surfaceGlass: const Color(0xCC181A20),
      borderSubtle: const Color(0xFF2D3139),
      borderHighlight: const Color(0xFF38BDF8),
      defaultInk: const Color(0xFFFFFFFF), // Luminous white ink
      secondaryInk: const Color(0xFF94A3B8),
      accentCyan: const Color(0xFF38BDF8),
      accentAmber: const Color(0xFFFBBF24),
      success: const Color(0xFF22C55E),
      warning: const Color(0xFFF97316),
      danger: const Color(0xFFEF4444),
      gridLineMajor: const Color(0xFF333842),
      gridLineMinor: const Color(0xFF22262F),
      reticleColor: const Color(0xFF38BDF8),
      headingStyle: baseHeading,
      bodyStyle: baseBody,
      monoStyle: baseMono,
    );
  }

  static AppThemeTokens blueprint() {
    final baseHeading = createHeadingStyle(
      color: const Color(0xFFF0F9FF),
      fontWeight: FontWeight.w700,
    );
    final baseBody = createBodyStyle(
      color: const Color(0xFFBAE6FD),
      fontSize: 14,
    );
    final baseMono = createMonoStyle(
      color: const Color(0xFF7DD3FC),
      fontSize: 12,
    );

    return AppThemeTokens(
      mode: AppThemeMode.blueprint,
      canvasBackground: const Color(0xFF0B2046), // Classic Cyanotype blueprint navy
      surfaceBackground: const Color(0xFF0E2A5C),
      surfaceGlass: const Color(0xCC0E2A5C),
      borderSubtle: const Color(0xFF1E3A8A),
      borderHighlight: const Color(0xFF38BDF8),
      defaultInk: const Color(0xFFF0F9FF), // Drafting chalk white
      secondaryInk: const Color(0xFF7DD3FC),
      accentCyan: const Color(0xFF38BDF8),
      accentAmber: const Color(0xFFFDE047),
      success: const Color(0xFF34D399),
      warning: const Color(0xFFFB923C),
      danger: const Color(0xFFF87171),
      gridLineMajor: const Color(0x5538BDF8),
      gridLineMinor: const Color(0x2838BDF8),
      reticleColor: const Color(0xFF38BDF8),
      headingStyle: baseHeading,
      bodyStyle: baseBody,
      monoStyle: baseMono,
    );
  }

  static AppThemeTokens of(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light();
      case AppThemeMode.dark:
        return dark();
      case AppThemeMode.blueprint:
        return blueprint();
    }
  }
}
