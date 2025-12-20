import 'package:flutter/material.dart';

class AppTheme {
  // Premium Colors
  static const Color darkBackground = Color(0xFF0A0A0B); // Deeper black
  static const Color darkSurface = Color(0xFF1C1C1E); // Distinct surface color
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
          surface: darkBackground, // Set absolute background
          surfaceContainer: darkSurface, // High contrast surface
          surfaceContainerHigh: Color(0xFF252529),
          surfaceContainerHighest: Color(0xFF2C2C30),
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
          error: errorRed,
        );
      } else {
        scheme = ColorScheme.fromSeed(
          seedColor: primaryPurple,
          brightness: brightness,
        );
      }
    }

    // Override if tag color is present (handled in UI, but this helper supports main app theme)
    if (dynamicColorScheme != null) {
      scheme = dynamicColorScheme;
    }

    final textTheme =
        (brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light())
            .textTheme
            .apply(
              fontFamily: 'Rubik',
              bodyColor: scheme.onSurface,
              displayColor: scheme.onSurface,
            );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Rubik',
      scaffoldBackgroundColor: scheme.surface,
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
        shape: const StadiumBorder(), // M3 Pill Style
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
