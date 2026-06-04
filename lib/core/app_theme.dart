import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF1E3A8A); // Premium Royal Navy Blue
  static const Color primaryContainer = Color(0xFFEFF6FF); // Soft Translucent Blue Tint
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);
  
  static const Color background = Color(0xFFF8FAFC); // Ultra-Light Ice Gray background
  static const Color surface = Color(0xFFFFFFFF); // Pure Alabaster White
  static const Color surfaceContainer = Color(0xFFF1F5F9); // Light Slate
  static const Color surfaceContainerLow = Color(0xFFF8FAFC);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F0);
  static const Color surfaceContainerHighest = Color(0xFFCBD5E1);
  
  static const Color onSurface = Color(0xFF0F172A); // Matte Black / Dark Slate
  static const Color onSurfaceVariant = Color(0xFF64748B); // Slate Steel Grey secondary labels
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFFE2E8F0); // Muted contrast divider
  
  static const Color secondary = Color(0xFF64748B);
  static const Color secondaryContainer = Color(0xFFF1F5F9);
  static const Color onSecondaryContainer = Color(0xFF0F172A);
  
  static const Color success = Color(0xFF059669); // Sharp Deep Mint profit/revenue text
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccessContainer = Color(0xFF065F46);
  
  static const Color error = Color(0xFFDC2626); // Clean Crimson Red expense text
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);
  
  static const Color tertiary = Color(0xFF7C2D12);
  static const Color tertiaryFixed = Color(0xFFFFEDD5);
  static const Color tertiaryFixedDim = Color(0xFFFED7AA);
  static const Color onTertiaryFixed = Color(0xFF431407);
  static const Color onTertiaryFixedVariant = Color(0xFF9A3412);

  // Border Radii (16.0 container overhaul)
  static const double radiusDefault = 8.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 16.0;

  static BorderRadius get borderDefault => BorderRadius.circular(radiusDefault);
  static BorderRadius get borderSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderXl => BorderRadius.circular(radiusXl);

  // Premium Soft Shadows
  static List<BoxShadow> get hardShadowLight => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ];

  static List<BoxShadow> get hardShadowHeavy => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          offset: const Offset(0, 8),
          blurRadius: 16,
        ),
      ];

  static List<BoxShadow> get hardShadowButton => [
        BoxShadow(
          color: primary.withValues(alpha: 0.15),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ];

  // Subtle clean card border outlines
  static Border get cardBorder => Border.all(
        color: outlineVariant,
        width: 1.0,
      );

  static Border get heavyBorder => Border.all(
        color: outlineVariant,
        width: 1.5,
      );

  static Border get mediumBorder => Border.all(
        color: outlineVariant,
        width: 1.0,
      );

  // Typography paired Hanken Grotesk and Inter
  static TextStyle get headlineXl => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: onSurface,
      );

  static TextStyle get headlineLg => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.3,
        color: onSurface,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      );

  static TextStyle get labelBold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        height: 1.4,
        color: onSurface,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: onSurfaceVariant,
      );

  static TextStyle get dataTabular => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: onSurface,
      );

  // Theme definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        headlineLarge: headlineXl,
        headlineMedium: headlineLg,
        titleMedium: headlineMd,
        bodyLarge: bodyLg,
        bodyMedium: bodyMd,
        labelLarge: labelBold,
        labelSmall: labelSm,
      ),
    );
  }
}

