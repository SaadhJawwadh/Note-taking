import 'package:flutter/material.dart';

/// Available aspect ratio presets for social media exports.
enum StoryCardAspectRatio {
  story(
    label: '9:16 Story',
    ratio: 9 / 16,
    icon: Icons.smartphone_rounded,
    baseLogicalWidth: 380.0,
    baseLogicalHeight: 675.5,
  ),
  square(
    label: '1:1 Square',
    ratio: 1.0,
    icon: Icons.crop_square_rounded,
    baseLogicalWidth: 380.0,
    baseLogicalHeight: 380.0,
  ),
  portrait(
    label: '4:5 Portrait',
    ratio: 4 / 5,
    icon: Icons.crop_portrait_rounded,
    baseLogicalWidth: 380.0,
    baseLogicalHeight: 475.0,
  );

  final String label;
  final double ratio;
  final IconData icon;
  final double baseLogicalWidth;
  final double baseLogicalHeight;

  const StoryCardAspectRatio({
    required this.label,
    required this.ratio,
    required this.icon,
    required this.baseLogicalWidth,
    required this.baseLogicalHeight,
  });
}

/// Available word limit presets for story card quotes.
enum StoryCardWordLimit {
  w25('25 words', 25),
  w50('50 words', 50),
  w80('80 words', 80),
  all('All words', null);

  final String label;
  final int? maxWords;
  const StoryCardWordLimit(this.label, this.maxWords);
}

/// Available font style presets for story card typography.
enum StoryCardFontStyle {
  auto('Auto'),
  serif('Serif'),
  sans('Sans');

  final String label;
  const StoryCardFontStyle(this.label);
}
