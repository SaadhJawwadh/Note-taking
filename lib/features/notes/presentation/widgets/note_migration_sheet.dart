import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/ui/app_bottom_sheet.dart';
import '../../../../core/ui/app_card.dart';
import '../../../../core/ui/app_chip.dart';
import '../../../../data/note_model.dart';
import '../../../../providers/note_provider.dart';
import '../../services/note_migration_service.dart';

class NoteMigrationSheet extends StatefulWidget {
  const NoteMigrationSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await AppBottomSheet.show<void>(
      context: context,
      title: 'Import & Migrate Notes',
      child: const NoteMigrationSheet(),
    );
  }

  @override
  State<NoteMigrationSheet> createState() => _NoteMigrationSheetState();
}

class _NoteMigrationSheetState extends State<NoteMigrationSheet> {
  bool _isLoading = false;
  List<Note>? _parsedNotes;
  Set<String> _detectedTags = {};

  Future<void> _pickFiles() async {
    setState(() => _isLoading = true);
    await HapticFeedback.lightImpact();
    try {
      final notes = await NoteMigrationService.pickAndParseNotes();
      if (!mounted) return;

      final tags = <String>{};
      for (final n in notes) {
        tags.addAll(n.tags);
      }

      setState(() {
        _parsedNotes = notes;
        _detectedTags = tags;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing notes: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _performImport() async {
    if (_parsedNotes == null || _parsedNotes!.isEmpty) return;
    setState(() => _isLoading = true);
    await HapticFeedback.mediumImpact();

    try {
      final result = await NoteMigrationService.batchInsertNotes(_parsedNotes!);
      if (!mounted) return;

      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      await noteProvider.refreshNotes();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${result.totalImported} notes${result.importedTags.isNotEmpty ? ' with ${result.importedTags.length} tags' : ''}.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import notes: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceM, vertical: AppLayout.spaceS),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_parsedNotes == null) ...[
            AppCard(
              padding: const EdgeInsets.all(AppLayout.spaceL),
              backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.25),
              border: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.import_contacts_rounded, color: colorScheme.primary, size: 24),
                      const SizedBox(width: AppLayout.spaceS),
                      Text(
                        'Google Keep & Markdown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppLayout.spaceS),
                  Text(
                    'Import notes directly from Google Takeout (ZIP or JSON files) or generic Markdown/Text files (.md, .txt). Your titles, checklists, tags, and timestamps will be preserved.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppLayout.spaceM),
                  Container(
                    padding: const EdgeInsets.all(AppLayout.spaceS),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppLayout.radiusS),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: colorScheme.primary),
                        const SizedBox(width: AppLayout.spaceS),
                        Expanded(
                          child: Text(
                            'To export from Google Keep: takeout.google.com → Select Keep → Download ZIP.',
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.spaceL),
            FilledButton.icon(
              onPressed: _isLoading ? null : _pickFiles,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.folder_open_rounded),
              label: Text(_isLoading ? 'Scanning Files...' : 'Select Takeout ZIP or Note Files'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
              ),
            ),
          ] else ...[
            // Preview parsed notes
            AppCard(
              padding: const EdgeInsets.all(AppLayout.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ready to Import',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppChip(
                        label: '${_parsedNotes!.length} Notes Found',
                        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        textColor: colorScheme.primary,
                      ),
                    ],
                  ),
                  if (_detectedTags.isNotEmpty) ...[
                    const SizedBox(height: AppLayout.spaceS),
                    Text(
                      'Detected Tags (${_detectedTags.length}):',
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppLayout.spaceXS),
                    Wrap(
                      spacing: AppLayout.spaceXS,
                      runSpacing: AppLayout.spaceXS,
                      children: _detectedTags.take(8).map((tag) {
                        return AppChip(label: '#$tag');
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: AppLayout.spaceM),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _parsedNotes!.length.clamp(0, 5),
                      itemBuilder: (context, index) {
                        final note = _parsedNotes![index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description_outlined, size: 20),
                          title: Text(
                            note.title.isNotEmpty ? note.title : 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            note.tags.isNotEmpty ? note.tags.join(', ') : 'No tags',
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_parsedNotes!.length > 5) ...[
                    Text(
                      'And ${_parsedNotes!.length - 5} more notes...',
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppLayout.spaceL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => setState(() => _parsedNotes = null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                    ),
                    child: const Text('Change Files'),
                  ),
                ),
                const SizedBox(width: AppLayout.spaceM),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading || _parsedNotes!.isEmpty ? null : _performImport,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_done_rounded),
                    label: Text(_isLoading ? 'Importing...' : 'Import Notes'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppLayout.radiusM)),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppLayout.spaceS),
        ],
      ),
    );
  }
}
