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
        scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4), // M3 Violet Dusk Seed
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF141318), // Soft Charcoal Dark Slate
          surfaceContainerLow: const Color(0xFF1C1A22),
          surfaceContainer: const Color(0xFF211F28),
          surfaceContainerHigh: const Color(0xFF2B2834),
          surfaceContainerHighest: const Color(0xFF363442),
          onSurface: const Color(0xFFE6E1E5),
          onSurfaceVariant: const Color(0xFFCAC4D0),
        );
      } else {
        scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
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
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 6,
        shadowColor: scheme.shadow.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusXL),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        menuPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 4,
        shape: const StadiumBorder(), // M3 Pill Style
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          shape: WidgetStateProperty.all(const StadiumBorder()),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onSecondaryContainer, size: 24);
          }
          return IconThemeData(color: scheme.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            );
          }
          return textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          );
        }),
      ),
      // Keep modal sheets readable on tablets/foldables instead of
      // stretching edge to edge.
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.labelLarge,
        side: BorderSide.none,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        constraints: BoxConstraints(maxWidth: AppLayout.maxContentWidth),
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
