import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';

/// Hệ thống bảng màu chuẩn (Design Tokens - Colors)
class AppColors {
  // Brand & Accent Colors
  static const Color primary = Color(0xFFE50914); // Energetic Red
  static const Color primaryDark = Color(0xFFB80710);
  static const Color primaryGlow = Color(0x33E50914);

  // Background & Surface
  static const Color background = Color(0xFF000000); // Pure OLED Black
  static const Color surface = Color(0xFF121214);
  static const Color card = Color(0xFF1C1C1E); // Elevated Dark Surface
  static const Color cardSubtle = Color(0xFF18181A);
  static const Color border = Color(0xFF2C2C2E);
  static const Color borderSubtle = Color(0x1FFFFFFF);

  // Typography
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textTertiary = Colors.white38;

  // Semantic Status Colors
  static const Color success = Color(0xFF00E676); // Green / Target Reached
  static const Color successGlow = Color(0x3300E676);
  static const Color warning = Color(0xFFFFAB00); // Amber / Approaching Limit
  static const Color error = Color(0xFFFF5252); // Red / Deficit alert
  static const Color info = Color(0xFF00F0FF); // Neon Cyan / AI Accent

  // Macro Nutrient Badges & Charts
  static const Color protein = Color(0xFF00F0FF); // Cyan
  static const Color carbs = Color(0xFFFF9F0A); // Orange
  static const Color fat = Color(0xFFFF375F); // Rose Pink
  static const Color water = Color(0xFF2979FF); // Electric Blue
}

/// Hệ thống khoảng cách chuẩn (Design Tokens - Spacing)
class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Hệ thống bo góc chuẩn (Design Tokens - Radius)
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double card = 20.0;
  static const double pill = 999.0;

  static SmoothBorderRadius smooth(double radius) =>
      SmoothBorderRadius(cornerRadius: radius, cornerSmoothing: 0.6);

  static SmoothRectangleBorder smoothBorder({
    double radius = card,
    BorderSide side = BorderSide.none,
  }) =>
      SmoothRectangleBorder(
        borderRadius: smooth(radius),
        side: side,
      );
}

/// Hệ thống Theme & Typography chính của ứng dụng
class AppTheme {
  // Backward-compatible color aliases
  static const Color backgroundColor = AppColors.background;
  static const Color primaryColor = AppColors.primary;
  static const Color cardColor = AppColors.card;
  static const Color textPrimaryColor = AppColors.textPrimary;
  static const Color textSecondaryColor = AppColors.textSecondary;

  // Typography Builder
  static TextStyle font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      letterSpacing: letterSpacing ?? 0.1,
      height: height,
      fontStyle: fontStyle,
    );
  }

  /// Dark Theme chính chuẩn Premium OLED
  static ThemeData get darkTheme {
    final baseTextTheme =
        GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.card,
        // ignore: deprecated_member_use
        background: AppColors.background,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.0,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.0,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    );
  }
}
