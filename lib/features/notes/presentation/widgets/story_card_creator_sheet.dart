import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_bottom_sheet.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../screens/app_lock_screen.dart';

/// Available aspect ratio presets for social media exports.
enum StoryCardAspectRatio {
  story('9:16 Story', 9 / 16, Icons.smartphone_rounded),
  square('1:1 Square', 1.0, Icons.crop_square_rounded),
  portrait('4:5 Portrait', 4 / 5, Icons.crop_portrait_rounded);

  final String label;
  final double ratio;
  final IconData icon;
  const StoryCardAspectRatio(this.label, this.ratio, this.icon);
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

/// Visual theme presets for the Story Card.
enum StoryCardThemePreset {
  materialYou('Material You', Icons.palette_outlined),
  oledBlack('OLED Pitch', Icons.dark_mode_rounded),
  editorial('Editorial', Icons.menu_book_rounded),
  frostedGlass('Frosted Glass', Icons.blur_on_rounded),
  noteTint('Note Accent', Icons.color_lens_outlined),
  terminal('Terminal', Icons.terminal_rounded);

  final String label;
  final IconData icon;
  const StoryCardThemePreset(this.label, this.icon);
}

/// Interactive modal studio to preview, customize, and export selected text
/// or note passages into publication-grade social media story images.
class StoryCardCreatorSheet extends StatefulWidget {
  final String initialText;
  final String noteTitle;
  final int noteColorValue;
  final DateTime noteDate;

  const StoryCardCreatorSheet({
    super.key,
    required this.initialText,
    required this.noteTitle,
    this.noteColorValue = 0,
    required this.noteDate,
  });

  /// Displays the [StoryCardCreatorSheet] modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required String initialText,
    required String noteTitle,
    int noteColorValue = 0,
    required DateTime noteDate,
  }) {
    return AppBottomSheet.show(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      child: StoryCardCreatorSheet(
        initialText: initialText,
        noteTitle: noteTitle,
        noteColorValue: noteColorValue,
        noteDate: noteDate,
      ),
    );
  }

  @override
  State<StoryCardCreatorSheet> createState() => _StoryCardCreatorSheetState();
}

class _StoryCardCreatorSheetState extends State<StoryCardCreatorSheet> {
  final GlobalKey _repaintKey = GlobalKey();
  late TextEditingController _textController;

  StoryCardAspectRatio _aspectRatio = StoryCardAspectRatio.story;
  StoryCardThemePreset _selectedTheme = StoryCardThemePreset.materialYou;
  StoryCardWordLimit _wordLimit = StoryCardWordLimit.all;
  StoryCardFontStyle _fontStyle = StoryCardFontStyle.auto;

  bool _showTitle = true;
  bool _showDate = true;
  bool _showWatermark = false;
  bool _isExporting = false;
  bool _isEditingText = false;

  static bool _containsTamil(String text) {
    return RegExp(r'[\u0B80-\u0BFF]').hasMatch(text);
  }

  static int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  static String _limitWords(String text, int? maxWords) {
    final trimmed = text.trim();
    if (maxWords == null || trimmed.isEmpty) return trimmed;
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= maxWords) return trimmed;
    return '${words.take(maxWords).join(' ')}...';
  }

  @override
  void initState() {
    super.initState();
    final trimmed = widget.initialText.trim();
    _textController = TextEditingController(text: trimmed);
    final totalWords = _countWords(trimmed);
    _wordLimit = totalWords > 60 ? StoryCardWordLimit.w50 : StoryCardWordLimit.all;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Rasterizes the card widget into high-resolution PNG bytes.
  Future<Uint8List?> _captureCardBytes() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('StoryCardCreatorSheet: capture failed: $e');
      return null;
    }
  }

  /// Shares the story card via native OS share sheet.
  Future<void> _shareCard() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    await HapticFeedback.mediumImpact();

    try {
      final bytes = await _captureCardBytes();
      if (bytes == null || !mounted) {
        if (mounted) AppSnackBar.showError(context, message: 'Could not generate story image');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filename = 'story_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);

      AppLockScreen.ignoreNextResumeLock();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.noteTitle.isNotEmpty ? widget.noteTitle : 'Story Note',
      );
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, message: 'Sharing failed: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Saves the rendered story card to local device documents.
  Future<void> _saveCardToDevice() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    await HapticFeedback.selectionClick();

    try {
      final bytes = await _captureCardBytes();
      if (bytes == null || !mounted) {
        if (mounted) AppSnackBar.showError(context, message: 'Could not generate story image');
        return;
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${appDocDir.path}/story_cards');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      final filename = 'story_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${exportDir.path}/$filename');
      await file.writeAsBytes(bytes);

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          message: 'Saved to documents: $filename',
        );
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, message: 'Failed to save image: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Copies the text to clipboard.
  Future<void> _copyText() async {
    await HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: _textController.text.trim()));
    if (mounted) {
      AppSnackBar.show(
        context,
        message: 'Quote copied to clipboard',
        icon: Icons.copy_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppLayout.spaceM,
        right: AppLayout.spaceM,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppLayout.spaceM,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_camera_back_rounded, size: 20, color: colorScheme.primary),
                ),
                const SizedBox(width: AppLayout.spaceS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Story Card Studio',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Export text as high-res social image',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_isEditingText ? Icons.check_rounded : Icons.edit_note_rounded),
                  tooltip: _isEditingText ? 'Done Editing' : 'Edit Text',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isEditingText = !_isEditingText);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppLayout.spaceM),

            // Live Interactive Card Viewport (Centered)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 320,
                  maxWidth: 340,
                ),
                child: AspectRatio(
                  aspectRatio: _aspectRatio.ratio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppLayout.radiusL),
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: _buildStoryCardContent(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppLayout.spaceM),

          // Quick Edit Text Field (Expandable)
          if (_isEditingText) ...[
            TextField(
              controller: _textController,
              maxLines: 3,
              maxLength: 2000,
              decoration: InputDecoration(
                labelText: 'Edit Quote Text',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppLayout.spaceS),
          ],

          // Controls 1: Word Limit Selector & Stats Pill
          Builder(
            builder: (context) {
              final totalWords = _countWords(_textController.text);
              final displayedText = _limitWords(_textController.text, _wordLimit.maxWords);
              final displayedWords = _countWords(displayedText);
              final isTrimmed = _wordLimit.maxWords != null && totalWords > _wordLimit.maxWords!;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppLayout.radiusS),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notes_rounded, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 5),
                          Text(
                            isTrimmed ? '$displayedWords / $totalWords words' : '$totalWords words',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppLayout.spaceS),
                    ...StoryCardWordLimit.values.map((limit) {
                      final isSelected = _wordLimit == limit;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ChoiceChip(
                          label: Text(
                            limit.label.split(' ').first,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          selected: isSelected,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onSelected: (val) {
                            if (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _wordLimit = limit);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppLayout.spaceS),

          // Controls 2: Aspect Ratio Segmented Button
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<StoryCardAspectRatio>(
              segments: StoryCardAspectRatio.values.map((ratio) {
                return ButtonSegment<StoryCardAspectRatio>(
                  value: ratio,
                  label: Text(
                    ratio.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  icon: Icon(ratio.icon, size: 16),
                );
              }).toList(),
              selected: {_aspectRatio},
              onSelectionChanged: (set) {
                HapticFeedback.selectionClick();
                setState(() => _aspectRatio = set.first);
              },
            ),
          ),
          const SizedBox(height: AppLayout.spaceS),

          // Controls 3: Visual Theme Carousel
          SizedBox(
            height: 38,
            child: ListView.separated(
              key: const ValueKey('theme_preset_list'),
              scrollDirection: Axis.horizontal,
              itemCount: StoryCardThemePreset.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = StoryCardThemePreset.values[index];
                final isSelected = _selectedTheme == preset;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(preset.icon, size: 14, color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface),
                      const SizedBox(width: 6),
                      Text(preset.label, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTheme = preset);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppLayout.spaceS),

          // Controls 4: Typography & Metadata Toggle Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...StoryCardFontStyle.values.map((style) {
                final isSelected = _fontStyle == style;
                return ChoiceChip(
                  label: Text(
                    style.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  selected: isSelected,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (val) {
                    if (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _fontStyle = style);
                    }
                  },
                );
              }),
              FilterChip(
                label: const Text('Title', style: TextStyle(fontSize: 11)),
                avatar: Icon(Icons.title_rounded, size: 13, color: _showTitle ? colorScheme.primary : colorScheme.onSurfaceVariant),
                selected: _showTitle,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _showTitle = val);
                },
              ),
              FilterChip(
                label: const Text('Date', style: TextStyle(fontSize: 11)),
                avatar: Icon(Icons.event_outlined, size: 13, color: _showDate ? colorScheme.primary : colorScheme.onSurfaceVariant),
                selected: _showDate,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _showDate = val);
                },
              ),
              FilterChip(
                label: const Text('Watermark', style: TextStyle(fontSize: 11)),
                avatar: Icon(Icons.verified_outlined, size: 13, color: _showWatermark ? colorScheme.primary : colorScheme.onSurfaceVariant),
                selected: _showWatermark,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _showWatermark = val);
                },
              ),
            ],
          ),
          const SizedBox(height: AppLayout.spaceM),

          // Action Buttons: Primary Share + Compact Save/Copy
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isExporting ? null : _shareCard,
                    icon: _isExporting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.share_rounded, size: 20),
                    label: Text(
                      _isExporting ? 'Generating...' : 'Share Image',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppLayout.spaceS),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isExporting ? null : _saveCardToDevice,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Icon(Icons.download_rounded, size: 20),
                ),
              ),
              const SizedBox(width: AppLayout.spaceS),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _isExporting ? null : _copyText,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Icon(Icons.copy_rounded, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  /// Builds the visual content of the Story Card based on selected theme & typography.
  Widget _buildStoryCardContent(BuildContext context) {
    final theme = Theme.of(context);
    final fullText = _textController.text.trim();
    final text = _limitWords(fullText, _wordLimit.maxWords);
    final isTamil = _containsTamil(text);
    final isStory = _aspectRatio == StoryCardAspectRatio.story;
    final isPortrait = _aspectRatio == StoryCardAspectRatio.portrait;
    final dateStr = DateFormat.yMMMd().format(widget.noteDate);

    // Resolve color styling according to theme
    Color cardBackground;
    Color textColor;
    Color accentColor;
    Color subtextColor;
    Color borderColor;
    bool isFrosted = false;

    switch (_selectedTheme) {
      case StoryCardThemePreset.oledBlack:
        cardBackground = Colors.black;
        textColor = const Color(0xFFF5F5F7);
        accentColor = theme.colorScheme.primary;
        subtextColor = const Color(0xFF9E9E9E);
        borderColor = const Color(0x33FFFFFF);
        break;
      case StoryCardThemePreset.frostedGlass:
        cardBackground = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);
        textColor = theme.colorScheme.onSurface;
        accentColor = theme.colorScheme.primary;
        subtextColor = theme.colorScheme.onSurfaceVariant;
        borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.35);
        isFrosted = true;
        break;
      case StoryCardThemePreset.noteTint:
        final seedColor = widget.noteColorValue != 0
            ? Color(widget.noteColorValue)
            : theme.colorScheme.secondaryContainer;
        cardBackground = seedColor;
        final isBright = seedColor.computeLuminance() > 0.45;
        textColor = isBright ? const Color(0xFF1C1B1F) : const Color(0xFFF4EFF4);
        accentColor = isBright ? const Color(0xFF311B92) : const Color(0xFFD0BCFF);
        subtextColor = textColor.withValues(alpha: 0.75);
        borderColor = textColor.withValues(alpha: 0.15);
        break;
      case StoryCardThemePreset.editorial:
        cardBackground = const Color(0xFFFBF8F2);
        textColor = const Color(0xFF222222);
        accentColor = const Color(0xFF8B2500);
        subtextColor = const Color(0xFF666666);
        borderColor = const Color(0x1A000000);
        break;
      case StoryCardThemePreset.terminal:
        cardBackground = const Color(0xFF1E1E2E);
        textColor = const Color(0xFFCDD6F4);
        accentColor = const Color(0xFF89B4FA);
        subtextColor = const Color(0xFF6C7086);
        borderColor = const Color(0x3389B4FA);
        break;
      case StoryCardThemePreset.materialYou:
        cardBackground = theme.colorScheme.surfaceContainerHigh;
        textColor = theme.colorScheme.onSurface;
        accentColor = theme.colorScheme.primary;
        subtextColor = theme.colorScheme.onSurfaceVariant;
        borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.3);
        break;
    }

    // Resolve font family with packaged Tamil and English fonts
    String resolvedFontFamily;
    switch (_fontStyle) {
      case StoryCardFontStyle.serif:
        resolvedFontFamily = isTamil ? AppTheme.fontNotoSerifTamil : 'serif';
        break;
      case StoryCardFontStyle.sans:
        resolvedFontFamily = isTamil ? AppTheme.fontNotoSansTamil : AppTheme.fontGoogleSansFlex;
        break;
      case StoryCardFontStyle.auto:
        if (_selectedTheme == StoryCardThemePreset.editorial) {
          resolvedFontFamily = isTamil ? AppTheme.fontNotoSerifTamil : 'serif';
        } else if (_selectedTheme == StoryCardThemePreset.terminal) {
          resolvedFontFamily = 'monospace';
        } else {
          resolvedFontFamily = isTamil ? AppTheme.fontNotoSansTamil : AppTheme.fontGoogleSansFlex;
        }
        break;
    }

    const fontFallback = [
      AppTheme.fontNotoSansTamil,
      AppTheme.fontNotoSerifTamil,
      AppTheme.fontGoogleSansFlex,
      AppTheme.fontInter,
      'sans-serif',
    ];

    // Adaptive typography sizing optimized for aspect ratio and Tamil/English scripts
    final charCount = text.length;
    double fontSize;
    double lineHeight;
    FontWeight fontWeight;

    if (charCount < 60) {
      fontSize = isStory ? 24.0 : (isPortrait ? 20.0 : 18.0);
      lineHeight = isTamil ? 1.5 : 1.35;
      fontWeight = FontWeight.bold;
    } else if (charCount < 140) {
      fontSize = isStory ? 18.0 : (isPortrait ? 15.5 : 14.5);
      lineHeight = isTamil ? 1.55 : 1.4;
      fontWeight = FontWeight.w600;
    } else if (charCount < 300) {
      fontSize = isStory ? 14.5 : (isPortrait ? 13.0 : 12.0);
      lineHeight = isTamil ? 1.55 : 1.45;
      fontWeight = FontWeight.w500;
    } else if (charCount < 500) {
      fontSize = isStory ? 12.5 : (isPortrait ? 11.0 : 10.5);
      lineHeight = isTamil ? 1.5 : 1.4;
      fontWeight = FontWeight.normal;
    } else {
      fontSize = isStory ? 11.0 : (isPortrait ? 10.0 : 9.5);
      lineHeight = isTamil ? 1.45 : 1.35;
      fontWeight = FontWeight.normal;
    }

    Widget cardBody = Container(
      decoration: BoxDecoration(
        color: cardBackground,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      padding: EdgeInsets.fromLTRB(
        isStory ? 24.0 : 18.0,
        isStory ? 32.0 : 20.0, // Top safe zone for social story header chrome
        isStory ? 24.0 : 18.0,
        isStory ? 28.0 : 18.0, // Bottom safe zone for social story reply bar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Note Title & Optional Window Dots
          if (_selectedTheme == StoryCardThemePreset.terminal)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _buildTerminalDot(const Color(0xFFFF5F56)),
                  const SizedBox(width: 6),
                  _buildTerminalDot(const Color(0xFFFFBD2E)),
                  const SizedBox(width: 6),
                  _buildTerminalDot(const Color(0xFF27C93F)),
                  const Spacer(),
                  if (_showDate)
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: subtextColor,
                        fontFamily: 'monospace',
                        fontFamilyFallback: fontFallback,
                      ),
                    ),
                ],
              ),
            ),

          if (_showTitle && widget.noteTitle.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 3,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.noteTitle.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: accentColor,
                      fontFamily: resolvedFontFamily,
                      fontFamilyFallback: fontFallback,
                    ),
                  ),
                ),
                if (_showDate && _selectedTheme != StoryCardThemePreset.terminal)
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: subtextColor,
                      fontFamily: resolvedFontFamily,
                      fontFamilyFallback: fontFallback,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Editorial Watermark Quotation Mark
          if (_selectedTheme == StoryCardThemePreset.editorial)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '“',
                style: TextStyle(
                  fontSize: 38,
                  height: 0.6,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.bold,
                  color: accentColor.withValues(alpha: 0.35),
                ),
              ),
            ),

          // Main Quote Excerpt (Vertically Centered with Zero-Overflow FittedBox)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isStory ? 12.0 : 8.0,
                vertical: 6.0,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: _selectedTheme == StoryCardThemePreset.editorial
                      ? Alignment.centerLeft
                      : Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isStory ? 285.0 : (isPortrait ? 260.0 : 240.0),
                    ),
                    child: Text(
                      text.isEmpty ? 'No text selected.' : text,
                      textAlign: _selectedTheme == StoryCardThemePreset.editorial
                          ? TextAlign.left
                          : TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: lineHeight,
                        fontWeight: fontWeight,
                        color: textColor,
                        fontFamily: resolvedFontFamily,
                        fontFamilyFallback: fontFallback,
                        letterSpacing: _selectedTheme == StoryCardThemePreset.terminal
                            ? 0.0
                            : (isTamil ? 0.3 : -0.2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Footer (Properly Centered Watermark with App Logo & Date Fallback)
          if (_showWatermark)
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: textColor.withValues(alpha: 0.12), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Image.asset(
                          'assets/app_icon_monochrome.png',
                          width: 12,
                          height: 12,
                          cacheWidth: 36,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Everything App',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: subtextColor,
                          fontFamily: AppTheme.fontInter,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (!_showTitle && _showDate && _selectedTheme != StoryCardThemePreset.terminal)
            Center(
              child: Text(
                dateStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: subtextColor,
                  fontFamily: resolvedFontFamily,
                  fontFamilyFallback: fontFallback,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );

    // If frosted glass, wrap with background gradient and blur
    if (isFrosted) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.tertiaryContainer,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppLayout.radiusM),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: cardBody,
          ),
        ),
      );
    }

    return cardBody;
  }

  Widget _buildTerminalDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
