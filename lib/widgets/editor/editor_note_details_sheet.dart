import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_layout.dart';

/// A Material 3 bottom sheet showing statistics (words, chars, read time)
/// and metadata (folder, created date, modified date) for a note.
class EditorNoteDetailsSheet extends StatelessWidget {
  final String plainText;
  final String folder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EditorNoteDetailsSheet({
    super.key,
    required this.plainText,
    required this.folder,
    this.createdAt,
    this.updatedAt,
  });

  /// Static helper to launch the bottom sheet.
  static void show(
    BuildContext context, {
    required String plainText,
    required String folder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => EditorNoteDetailsSheet(
        plainText: plainText,
        folder: folder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedText = plainText.trim();
    final words = trimmedText.isEmpty
        ? 0
        : trimmedText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final chars = trimmedText.length;
    final readingTimeMin = (words / 200).ceil();
    final readingTimeStr = words == 0
        ? '0 min read'
        : readingTimeMin <= 1
            ? '1 min read'
            : '$readingTimeMin min read';

    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Note Details & Stats',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StatCard(
                  icon: Icons.notes,
                  value: '$words',
                  label: 'Words',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.text_fields,
                  value: '$chars',
                  label: 'Characters',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.timer_outlined,
                  value: readingTimeStr,
                  label: 'Read Time',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppLayout.radiusM),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Folder',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        folder,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (createdAt != null) ...[
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Created',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          dateFormat.format(createdAt!),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                  if (updatedAt != null) ...[
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Last Modified',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          dateFormat.format(updatedAt!),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppLayout.radiusM),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
