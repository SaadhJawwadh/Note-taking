import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium Colors
  static const Color darkBackground = Color(0xFF161618);
  static const Color darkSurface =
      Color(0xFF252529); // Slightly lighter for cards
  static const Color primaryPurple = Color(0xFF6B4EFF); // Modern Purple
  static const Color accentPink = Color(0xFFFF85C2); // Soft accent
  static const Color textPrimary = Color(0xFFF2F2F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color errorRed = Color(0xFFFF453A);

  static ThemeData createTheme(
      ColorScheme? dynamicColorScheme, Brightness brightness) {
    ColorScheme scheme;

    if (dynamicColorScheme != null) {
      scheme = dynamicColorScheme;
    } else {
      // Fallback Schemes
      if (brightness == Brightness.dark) {
        scheme = const ColorScheme.dark(
          primary: primaryPurple,
          secondary: accentPink,
          surface: darkSurface,
          error: errorRed,
        );
      } else {
        scheme = ColorScheme.fromSeed(
          seedColor: primaryPurple,
          brightness: Brightness.light,
        );
      }
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          color: scheme.onSurface,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: GoogleFonts.outfit(
          color: scheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.inter(
          color: scheme.onSurface,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)), // M3 FAB
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.inter(color: scheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
