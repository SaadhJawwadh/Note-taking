import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class AppTheme {
  // Premium Colors
  static const Color darkBackground = Color(0xFF000000); // True Black
  static const Color darkSurface = Color(0xFF1E1E1E); // Distinct surface color
  static const Color primaryPurple = Color(0xFF6B4EFF); // Modern Purple
  static const Color accentPink = Color(0xFFFF85C2); // Soft accent
  static const Color textPrimary = Color(0xFFF2F2F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color errorRed = Color(0xFFFF453A);

  // Note Color Seeds (Material Standard Colors)
  // 5 Colors + System Default
  static const List<Color> noteColors = [
    Color(0x00000000), // System Default
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.blueGrey,
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
        },
      ),
    );
  }
}
