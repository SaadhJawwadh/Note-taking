import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:note_taking_app/features/notes/data/note_repository.dart';
import 'package:note_taking_app/data/note_model.dart';
import 'package:note_taking_app/data/settings_provider.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:note_taking_app/screens/home_screen.dart';
import 'package:note_taking_app/features/notes/presentation/screens/note_editor_screen.dart';
import 'package:note_taking_app/core/theme/app_layout.dart';
import 'package:note_taking_app/widgets/frosted_glass_sliver_app_bar.dart';
import 'package:note_taking_app/core/ui/app_card.dart';

enum FilterType { archived, trash }

class FilteredNotesScreen extends StatefulWidget {
  final FilterType filterType;

  const FilteredNotesScreen({super.key, required this.filterType});

  @override
  State<FilteredNotesScreen> createState() => _FilteredNotesScreenState();
}

class _FilteredNotesScreenState extends State<FilteredNotesScreen> {
  List<Note> displayedNotes = [];
  bool isLoading = true;
  Map<String, int> _tagColors = {};

  @override
  void initState() {
    super.initState();
    refreshNotes();
  }

  Future refreshNotes() async {
    setState(() => isLoading = true);
    final colors = await NoteRepository.instance.getAllTagColors();
    _tagColors = colors;

    if (widget.filterType == FilterType.archived) {
      displayedNotes = await NoteRepository.instance.readAllNotes(isArchived: true);
    } else {
      displayedNotes = await NoteRepository.instance.readTrashedNotes();
    }

    displayedNotes.sort((a, b) => b.dateModified.compareTo(a.dateModified));

    setState(() => isLoading = false);
  }

  void _showNoteActions(Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppLayout.radiusXXL))),
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.filterType == FilterType.trash) ...[
                ListTile(
                  leading:
                      Icon(Icons.restore_outlined, color: onSurfaceVariant),
                  title: Text('Restore', style: TextStyle(color: onSurface)),
                  onTap: () async {
                    await NoteRepository.instance.restoreNote(note.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await refreshNotes();
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                  title: Text('Delete Permanently',
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Permanently?'),
                        content: const Text(
                            'This note will be removed forever and cannot be recovered.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onError),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete Forever'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await NoteRepository.instance.deleteNote(note.id);
                      await refreshNotes();
                    }
                  },
                ),
              ] else ...[
                ListTile(
                  leading:
                      Icon(Icons.archive_outlined, color: onSurfaceVariant),
                  title: Text('Unarchive', style: TextStyle(color: onSurface)),
                  onTap: () async {
                    await NoteRepository.instance.archiveNote(note.id, false);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await refreshNotes();
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
                  title: Text('Move to Trash',
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () async {
                    await NoteRepository.instance.softDeleteNote(note.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await refreshNotes();
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.filterType == FilterType.archived ? 'Archived' : 'Trash';
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            FrostedGlassSliverAppBar(
              titleText: title,
              showBackButton: true,
            ),
            if (widget.filterType == FilterType.trash && !isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Builder(builder: (ctx) {
                    final isDark = Theme.of(ctx).brightness == Brightness.dark;
                    return AppCard.tonal(
                      color: colorScheme.errorContainer
                          .withValues(alpha: isDark ? 0.16 : 0.35),
                      borderColor: colorScheme.error
                          .withValues(alpha: isDark ? 0.35 : 0.45),
                      borderRadius: AppLayout.radiusL,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.auto_delete_outlined,
                              size: 20,
                              color: colorScheme.error,
                            ),
                          ),
                          const SizedBox(width: AppLayout.spaceM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trash Auto-Purge Active',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  settings.trashAutoPurgeDays > 0
                                      ? 'Notes in trash are automatically purged after ${settings.trashAutoPurgeDays} days.'
                                      : 'Notes in trash can be restored anytime before permanent deletion.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (displayedNotes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.filterType == FilterType.trash
                            ? Icons.delete_outline
                            : Icons.archive_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notes in $title',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final note = displayedNotes[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: OpenContainer<bool>(
                                transitionType: ContainerTransitionType.fade,
                                openBuilder: (context, _) => NoteEditorScreen(note: note),
                                closedElevation: 0,
                                closedColor: Colors.transparent,
                                closedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppLayout.radiusXL),
                                ),
                                onClosed: (returned) async {
                                  if (returned == true) {
                                    await refreshNotes();
                                  }
                                },
                                closedBuilder: (context, openContainer) {
                                  return NoteCard(
                                    note: note,
                                    onTap: openContainer,
                                    tagColors: _tagColors,
                                    onLongPress: () => _showNoteActions(note),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: displayedNotes.length,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
