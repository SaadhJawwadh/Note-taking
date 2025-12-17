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

  // Note Color Seeds (Material Standard Colors)
  // 5 Colors + System Default
  static const List<Color> noteColors = [
    Color(0x00000000), // System Default
    Color(0xFFE57373), // Red (Warm) - Red-300
    Color(0xFFFFB74D), // Orange (Energy) - Orange-300
    Color(0xFF81C784), // Green (Nature) - Green-300
    Color(0xFF64B5F6), // Blue (Calm) - Blue-300
    Color(0xFF9575CD), // Purple (Creative) - DeepPurple-300
  ];

  static ThemeData createTheme(ColorScheme? dynamicColorScheme,
      Brightness brightness, String fontFamily) {
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

    TextTheme getTextTheme(String font) {
      switch (font) {
        case 'Comic Neue':
          return GoogleFonts.comicNeueTextTheme();
        case 'Nunito':
          return GoogleFonts.nunitoTextTheme();
        case 'Quicksand':
          return GoogleFonts.quicksandTextTheme();
        case 'Varela Round':
          return GoogleFonts.varelaRoundTextTheme();
        case 'Rubik':
        default:
          return GoogleFonts.rubikTextTheme();
      }
    }

    final baseTextTheme = getTextTheme(fontFamily);
    final textTheme = baseTextTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: baseTextTheme.bodyLarge?.fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
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
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
