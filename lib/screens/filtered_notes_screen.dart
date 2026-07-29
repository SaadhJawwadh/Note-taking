import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/note_repository.dart';
import '../data/note_model.dart';
import '../data/settings_provider.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'home_screen.dart';
import 'note_editor_screen.dart';
import '../theme/app_layout.dart';
import '../widgets/bouncing_widget.dart';

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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                      Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
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
            SliverAppBar(
              pinned: true,
              floating: false,
              snap: false,
              primary: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: MediaQuery.of(context).padding.top + 68.0,
              titleSpacing: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 6,
                      left: 16,
                      right: 16,
                      bottom: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.82 : 0.88),
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: AppLayout.softShadow(context),
                        ),
                        child: Row(
                          children: [
                            BouncingWidget(
                              onTap: () => Navigator.pop(context),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              title,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
