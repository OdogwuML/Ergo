import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Architectural Curator Tokens
  static const Color primary = Color(0xFF1650bc);
  static const Color primaryContainer = Color(0xFF3a6ad6);
  static const Color backgroundLight = Color(0xFFf9f9f9);
  static const Color surfaceContainerLow = Color(0xFFf3f3f3);
  static const Color surfaceContainerHigh = Color(0xFFe8e8e8);
  static const Color surfaceContainerLowest = Color(0xFFffffff);
  
  static const Color outlineVariant = Color(0xFFc3c6d5);
  static const Color onSurface = Color(0xFF1a1c1c);
  static const Color onSurfaceVariant = Color(0xFF434653);
  static const Color onPrimary = Color(0xFFffffff);
  static const Color onPrimaryContainer = Color(0xFFf3f4ff);
  static const Color onBackground = Color(0xFF1a1c1c);
  static const Color error = Color(0xFFba1a1a);


  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primary,
        background: backgroundLight,
        surface: surfaceContainerLowest,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outlineVariant,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(color: onSurface),
        displayMedium: GoogleFonts.manrope(color: onSurface),
        displaySmall: GoogleFonts.manrope(color: onSurface),
        headlineLarge: GoogleFonts.manrope(color: onSurface),
        headlineMedium: GoogleFonts.manrope(color: onSurface),
        headlineSmall: GoogleFonts.manrope(color: onSurface),
        titleLarge: GoogleFonts.manrope(color: onSurface),
        titleMedium: GoogleFonts.manrope(color: onSurface),
        titleSmall: GoogleFonts.manrope(color: onSurface),
      ),
      useMaterial3: true,
    );
  }
}
