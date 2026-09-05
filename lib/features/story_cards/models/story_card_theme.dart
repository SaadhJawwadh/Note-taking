import 'package:flutter/material.dart';

/// Visual theme presets for the Story Card.
enum StoryCardThemePreset {
  editorial('Editorial', Icons.menu_book_rounded),
  obsidianAura('Obsidian Aura', Icons.auto_awesome_rounded),
  velvetOled('Velvet OLED', Icons.dark_mode_rounded),
  frostedGlassLuxe('Frosted Luxe', Icons.blur_on_rounded),
  noteTint('Note Accent', Icons.color_lens_outlined),
  terminal('Terminal', Icons.terminal_rounded);

  final String label;
  final IconData icon;
  const StoryCardThemePreset(this.label, this.icon);
}

/// Resolved color and visual styling properties for a Story Card theme.
class StoryCardThemeStyle {
  final Color background;
  final Color text;
  final Color accent;
  final Color subtext;
  final Color border;
  final Color categoryBg;
  final Color categoryText;
  final bool hasAuraGlow;
  final List<Color>? auraColors;
  final bool isFrostedGlass;
  final bool isEditorial;
  final bool isTerminal;

  const StoryCardThemeStyle({
    required this.background,
    required this.text,
    required this.accent,
    required this.subtext,
    required this.border,
    required this.categoryBg,
    required this.categoryText,
    this.hasAuraGlow = false,
    this.auraColors,
    this.isFrostedGlass = false,
    this.isEditorial = false,
    this.isTerminal = false,
  });

  /// Resolves the concrete [StoryCardThemeStyle] given the preset, app theme, and optional note color.
  factory StoryCardThemeStyle.resolve({
    required StoryCardThemePreset preset,
    required ThemeData appTheme,
    int noteColorValue = 0,
  }) {
    switch (preset) {
      case StoryCardThemePreset.editorial:
        return const StoryCardThemeStyle(
          background: Color(0xFFFBF8F2),
          text: Color(0xFF1E1E1E),
          accent: Color(0xFF8B2500),
          subtext: Color(0xFF5A5A5A),
          border: Color(0xFFE5DFD3),
          categoryBg: Color(0xFF8B2500),
          categoryText: Color(0xFFFFF7F2),
          isEditorial: true,
        );

      case StoryCardThemePreset.obsidianAura:
        return const StoryCardThemeStyle(
          background: Color(0xFF0C0E14),
          text: Color(0xFFF8F9FA),
          accent: Color(0xFF818CF8),
          subtext: Color(0xFF94A3B8),
          border: Color(0xFF1E293B),
          categoryBg: Color(0x336366F1),
          categoryText: Color(0xFFC7D2FE),
          hasAuraGlow: true,
          auraColors: [
            Color(0x406366F1), // Indigo
            Color(0x30A855F7), // Purple
            Color(0x000C0E14),
          ],
        );

      case StoryCardThemePreset.velvetOled:
        return StoryCardThemeStyle(
          background: Colors.black,
          text: const Color(0xFFF5F5F7),
          accent: appTheme.colorScheme.primary,
          subtext: const Color(0xFFA1A1AA),
          border: const Color(0x2EFFFFFF),
          categoryBg: appTheme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          categoryText: appTheme.colorScheme.primary,
        );

      case StoryCardThemePreset.frostedGlassLuxe:
        return const StoryCardThemeStyle(
          background: Color(0xDD12131F),
          text: Color(0xFFF8FAFC),
          accent: Color(0xFF38BDF8),
          subtext: Color(0xFF94A3B8),
          border: Color(0x4038BDF8),
          categoryBg: Color(0x3338BDF8),
          categoryText: Color(0xFFBAE6FD),
          isFrostedGlass: true,
          hasAuraGlow: true,
          auraColors: [
            Color(0x3D0EA5E9), // Sky blue
            Color(0x296366F1), // Indigo
            Color(0x000F172A),
          ],
        );

      case StoryCardThemePreset.noteTint:
        final seedColor = noteColorValue != 0
            ? Color(noteColorValue)
            : appTheme.colorScheme.secondaryContainer;
        final isBright = seedColor.computeLuminance() > 0.45;
        final textColor = isBright ? const Color(0xFF18181B) : const Color(0xFFF4EFF4);
        final accentColor = isBright ? const Color(0xFF311B92) : const Color(0xFFD0BCFF);
        return StoryCardThemeStyle(
          background: seedColor,
          text: textColor,
          accent: accentColor,
          subtext: textColor.withValues(alpha: 0.72),
          border: textColor.withValues(alpha: 0.16),
          categoryBg: textColor.withValues(alpha: 0.12),
          categoryText: textColor,
        );

      case StoryCardThemePreset.terminal:
        return const StoryCardThemeStyle(
          background: Color(0xFF1E1E2E),
          text: Color(0xFFCDD6F4),
          accent: Color(0xFF89B4FA),
          subtext: Color(0xFF7F849C),
          border: Color(0x4089B4FA),
          categoryBg: Color(0x2689B4FA),
          categoryText: Color(0xFF89B4FA),
          isTerminal: true,
        );
    }
  }
}
