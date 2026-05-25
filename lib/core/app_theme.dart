import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF000666);
  static const Color primaryContainer = Color(0xFF1A237E);
  static const Color onPrimaryContainer = Color(0xFF8690EE);
  
  static const Color background = Color(0xFFFBF8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEFECF5);
  static const Color surfaceContainerLow = Color(0xFFF5F2FB);
  static const Color surfaceContainerHigh = Color(0xFFEAE7EF);
  static const Color surfaceContainerHighest = Color(0xFFE4E1EA);
  
  static const Color onSurface = Color(0xFF1B1B21);
  static const Color onSurfaceVariant = Color(0xFF454652);
  static const Color outline = Color(0xFF767683);
  static const Color outlineVariant = Color(0xFFC6C5D4);
  
  static const Color secondary = Color(0xFF4C616C);
  static const Color secondaryContainer = Color(0xFFCFE6F2);
  static const Color onSecondaryContainer = Color(0xFF526772);
  
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFD0F0C0);
  static const Color onSuccessContainer = Color(0xFF1B5E20);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  static const Color tertiary = Color(0xFF380B00);
  static const Color tertiaryFixed = Color(0xFFFFDBD0);
  static const Color tertiaryFixedDim = Color(0xFFFFB59D);
  static const Color onTertiaryFixed = Color(0xFF390C00);
  static const Color onTertiaryFixedVariant = Color(0xFF7B2E12);

  // Border Radii
  static const double radiusDefault = 4.0;
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 8.0;
  static const double radiusXl = 12.0;

  static BorderRadius get borderDefault => BorderRadius.circular(radiusDefault);
  static BorderRadius get borderSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderXl => BorderRadius.circular(radiusXl);

  // Flat Hard Shadows (High-Contrast Modernism)
  static List<BoxShadow> get hardShadowLight => [
        const BoxShadow(
          color: Color(0x1A000000), // 10% opacity black
          offset: Offset(2, 2),
          blurRadius: 0,
        ),
      ];

  static List<BoxShadow> get hardShadowHeavy => [
        const BoxShadow(
          color: Colors.black,
          offset: Offset(4, 4),
          blurRadius: 0,
        ),
      ];

  static List<BoxShadow> get hardShadowButton => [
        const BoxShadow(
          color: Color(0xFF1A237E),
          offset: Offset(0, 6),
          blurRadius: 0,
        ),
      ];

  // Flat low-contrast outlines
  static Border get cardBorder => Border.all(
        color: outlineVariant,
        width: 1.5,
      );

  static Border get heavyBorder => Border.all(
        color: Colors.black,
        width: 4.0,
      );

  static Border get mediumBorder => Border.all(
        color: Colors.black,
        width: 2.0,
      );

  // Typography paired Hanken Grotesk and Inter
  static TextStyle get headlineXl => GoogleFonts.hankenGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 40 / 32,
        letterSpacing: -0.64,
        color: onSurface,
      );

  static TextStyle get headlineLg => GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        letterSpacing: -0.24,
        color: onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
        color: onSurface,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        color: onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: onSurface,
      );

  static TextStyle get labelBold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        height: 20 / 14,
        color: onSurface,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: onSurfaceVariant,
      );

  static TextStyle get dataTabular => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
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
