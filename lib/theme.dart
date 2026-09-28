import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF000000); // Black
  static const Color primaryColor = Color(0xFFE50914); // Red
  static const Color cardColor = Color(0xFF1C1C1E); // Dark Grey 
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Colors.white70;

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

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        surface: cardColor,
        // ignore: deprecated_member_use
        background: backgroundColor,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: textPrimaryColor,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          color: textPrimaryColor,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: textPrimaryColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: textPrimaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: textPrimaryColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.0,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textSecondaryColor,
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
          color: textPrimaryColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
