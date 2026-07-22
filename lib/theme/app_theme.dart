import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_layout.dart';

/// Semantic color roles not covered by [ColorScheme] (success/income,
/// cycle phases; destructive already maps to [ColorScheme.error]).
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color phaseMenstrual;
  final Color phaseFollicular;
  final Color phaseOvulatory;
  final Color phaseLuteal;

  const AppSemanticColors({
    required this.success,
    required this.phaseMenstrual,
    required this.phaseFollicular,
    required this.phaseOvulatory,
    required this.phaseLuteal,
  });

  static const light = AppSemanticColors(
    success: Color(0xFF1E8E3E),
    phaseMenstrual: Color(0xFFE57373),
    phaseFollicular: Color(0xFF64B5F6),
    phaseOvulatory: Color(0xFFFFB74D),
    phaseLuteal: Color(0xFFBA68C8),
  );
  static const dark = AppSemanticColors(
    success: Color(0xFF34C759),
    phaseMenstrual: Color(0xFFE57373),
    phaseFollicular: Color(0xFF64B5F6),
    phaseOvulatory: Color(0xFFFFB74D),
    phaseLuteal: Color(0xFFBA68C8),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? phaseMenstrual,
    Color? phaseFollicular,
    Color? phaseOvulatory,
    Color? phaseLuteal,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      phaseMenstrual: phaseMenstrual ?? this.phaseMenstrual,
      phaseFollicular: phaseFollicular ?? this.phaseFollicular,
      phaseOvulatory: phaseOvulatory ?? this.phaseOvulatory,
      phaseLuteal: phaseLuteal ?? this.phaseLuteal,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      phaseMenstrual: Color.lerp(phaseMenstrual, other.phaseMenstrual, t)!,
      phaseFollicular: Color.lerp(phaseFollicular, other.phaseFollicular, t)!,
      phaseOvulatory: Color.lerp(phaseOvulatory, other.phaseOvulatory, t)!,
      phaseLuteal: Color.lerp(phaseLuteal, other.phaseLuteal, t)!,
    );
  }
}

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

    final rawBaseTextTheme = (brightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light())
        .textTheme;

    GoogleFonts.config.allowRuntimeFetching = false;

    final baseTextTheme = GoogleFonts.interTextTheme(rawBaseTextTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    // Material Expressive pairing: Google Sans Text for display/headline/
    // titleLarge (hero numbers, screen titles), Inter for everything else
    // (body copy, labels, smaller titles).
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontFamily: 'Google Sans Text'),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontFamily: 'Google Sans Text'),
      displaySmall: baseTextTheme.displaySmall?.copyWith(fontFamily: 'Google Sans Text'),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontFamily: 'Google Sans Text'),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontFamily: 'Google Sans Text'),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontFamily: 'Google Sans Text'),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontFamily: 'Google Sans Text'),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
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
      // Deliberate shape steps: cards (16) < buttons (20) < FAB (full pill),
      // rather than pill-ifying every control.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppLayout.radiusXL),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppLayout.radiusXL),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppLayout.radiusXL),
          ),
        ),
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
      // Keep modal sheets readable on tablets/foldables instead of
      // stretching edge to edge.
      bottomSheetTheme: const BottomSheetThemeData(
        constraints: BoxConstraints(maxWidth: AppLayout.maxContentWidth),
      ),
      // One shape language for every floating surface (menus, dialogs,
      // snackbars) so ad hoc surfaces like context menus match the cards.
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusL),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // M3 dialog spec
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusM),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
        },
      ),
      extensions: [
        brightness == Brightness.dark ? AppSemanticColors.dark : AppSemanticColors.light,
      ],
    );
  }
}
