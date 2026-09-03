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
    success: Color(0xFF1B873F),
    phaseMenstrual: Color(0xFFD32F2F),
    phaseFollicular: Color(0xFF1976D2),
    phaseOvulatory: Color(0xFFF57C00),
    phaseLuteal: Color(0xFF7B1FA2),
  );
  static const dark = AppSemanticColors(
    success: Color(0xFF32D74B),
    phaseMenstrual: Color(0xFFEF9A9A),
    phaseFollicular: Color(0xFF90CAF9),
    phaseOvulatory: Color(0xFFFFCC80),
    phaseLuteal: Color(0xFFCE93D8),
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
  // Single Source of Truth Brand & Theme Colors
  static const Color darkBackground = Color(0xFF000000); // True Black
  static const Color darkSurface = Color(0xFF1E1E1E); // Distinct surface color
  static const Color primaryPurple = Color(0xFF6B4EFF); // Modern Purple
  static const Color accentPink = Color(0xFFFF85C2); // Soft accent
  static const Color textPrimary = Color(0xFFF2F2F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color errorRed = Color(0xFFFF453A);

  // Font Family Single Source of Truth Constants
  static const String fontGoogleSansFlex = 'Google Sans Flex';
  static const String fontInter = 'Inter';
  static const String fontNotoSansTamil = 'Noto Sans Tamil';
  static const String fontNotoSerifTamil = 'Noto Serif Tamil';

  // Note Color Seeds (Material 3 Expressive Curated Palette)
  static const List<Color> noteColors = [
    Color(0x00000000), // System Default (0)
    Color(0xFFE06D53), // Coral Dusk
    Color(0xFFD9779B), // Soft Rose
    Color(0xFF9E7BB5), // Lavender Dusk
    Color(0xFF6A7EC0), // Indigo Dusk
    Color(0xFF5194B6), // Sky Blue
    Color(0xFF4E9F90), // Sage Teal
    Color(0xFF5A9E75), // Emerald
    Color(0xFF86A148), // Olive Green
    Color(0xFFD49339), // Amber Harvest
    Color(0xFFC86F4B), // Terracotta
    Color(0xFF917265), // Warm Brown
    Color(0xFF758596), // Slate Blue
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

    final rawBaseTextTheme = (brightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light())
        .textTheme;

    GoogleFonts.config.allowRuntimeFetching = false;

    final baseTextTheme = GoogleFonts.interTextTheme(rawBaseTextTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final fontVariations = brightness == Brightness.dark
        ? const [FontVariation('GRAD', 15.0)]
        : null;

    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontFamily: fontGoogleSansFlex,
        fontVariations: fontVariations,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontFamily: fontGoogleSansFlex,
        fontVariations: fontVariations,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontFamily: fontGoogleSansFlex,
        fontVariations: fontVariations,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: fontGoogleSansFlex,
        fontVariations: fontVariations,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: fontGoogleSansFlex,
        fontVariations: fontVariations,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: fontGoogleSansFlex,
        fontVariations: fontVariations,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontFamily: fontGoogleSansFlex,
        fontVariations: fontVariations,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontFamily: fontGoogleSansFlex,
        fontVariations: fontVariations,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontFamily: fontGoogleSansFlex,
        fontVariations: fontVariations,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      splashFactory: InkSparkle.splashFactory,
      splashColor: scheme.primary.withValues(alpha: 0.12),
      highlightColor: scheme.primary.withValues(alpha: 0.08),
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusL),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          minimumSize: const Size(48, 48),
        ),
      ),
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
          borderRadius: BorderRadius.circular(AppLayout.radiusL),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        elevation: 3,
        shadowColor: scheme.shadow.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusXL),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        menuPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(scheme.surfaceContainerHigh),
          elevation: WidgetStateProperty.all(3),
          shadowColor: WidgetStateProperty.all(scheme.shadow.withValues(alpha: 0.15)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.radiusXL),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 8, horizontal: 4)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(scheme.surfaceContainerHigh),
          elevation: WidgetStateProperty.all(3),
          shadowColor: WidgetStateProperty.all(scheme.shadow.withValues(alpha: 0.15)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.radiusXL),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 4,
        shape: const StadiumBorder(),
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
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.labelLarge,
        side: BorderSide.none,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 1,
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppLayout.radiusXXL),
          ),
        ),
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusXXL),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: scheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: scheme.primary,
        cursorColor: scheme.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: scheme.inversePrimary,
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
