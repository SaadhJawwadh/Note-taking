import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../widgets/bouncing_widget.dart';

/// Floating voice dictation recording status pill widget.
class VoiceDictationPill extends StatelessWidget {
  final bool isListening;
  final String liveText;
  final VoidCallback onStop;

  const VoiceDictationPill({
    super.key,
    required this.isListening,
    required this.liveText,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    if (!isListening) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
        color: colorScheme.primaryContainer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  liveText.isNotEmpty ? liveText : 'Listening... Speak clearly',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              BouncingWidget(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onStop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                  ),
                  child: Text(
                    'Done',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
