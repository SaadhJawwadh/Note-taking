import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../data/database_helper.dart';
import '../data/note_model.dart';
import '../data/settings_provider.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'home_screen.dart'; // For NoteCard and actions (if reuse needed, for now we might duplicate actions or move them)
import 'note_editor_screen.dart';

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
    final allNotes = await DatabaseHelper.instance.readAllNotes();
    final colors = await DatabaseHelper.instance.getAllTagColors();
    _tagColors = colors;

    if (widget.filterType == FilterType.archived) {
      displayedNotes =
          allNotes.where((n) => n.isArchived && n.deletedAt == null).toList();
    } else {
      displayedNotes = allNotes.where((n) => n.deletedAt != null).toList();
    }

    // Sort by modification date desc by default
    displayedNotes.sort((a, b) => b.dateModified.compareTo(a.dateModified));

    setState(() => isLoading = false);
  }

  void _showNoteActions(Note note) {
    // Re-implementing action logic similar to HomeScreen but specific to context
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.filterType == FilterType.archived) ...[
                ListTile(
                  leading:
                      Icon(Icons.archive_outlined, color: onSurfaceVariant),
                  title: Text('Unarchive', style: TextStyle(color: onSurface)),
                  onTap: () async {
                    await DatabaseHelper.instance.archiveNote(note.id, false);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await refreshNotes();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Move to Trash',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    await DatabaseHelper.instance.deleteNote(note.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await refreshNotes();
                  },
                ),
              ] else ...[
                // Trash actions
                ListTile(
                  leading: Icon(Icons.restore, color: onSurfaceVariant),
                  title: Text('Restore', style: TextStyle(color: onSurface)),
                  onTap: () async {
                    await DatabaseHelper.instance.restoreNote(note.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    await refreshNotes();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Permanently',
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await DatabaseHelper.instance.hardDeleteNote(note.id);
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

    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : displayedNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.filterType == FilterType.archived
                              ? Icons.archive_outlined
                              : Icons.delete_outline,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes in $title',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AnimationLimiter(
                      child: settings.isGridView
                          ? MasonryGridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              itemCount: displayedNotes.length,
                              itemBuilder: (context, index) {
                                final note = displayedNotes[index];
                                return AnimationConfiguration.staggeredGrid(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  columnCount: 2,
                                  child: ScaleAnimation(
                                    child: FadeInAnimation(
                                      child: OpenContainer<bool>(
                                        transitionType:
                                            ContainerTransitionType.fade,
                                        openBuilder: (context, _) =>
                                            NoteEditorScreen(note: note),
                                        closedElevation: 0,
                                        closedColor: Colors.transparent,
                                        closedShape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        onClosed: (returned) async {
                                          if (returned == true) {
                                            await refreshNotes();
                                          }
                                        },
                                        closedBuilder:
                                            (context, openContainer) {
                                          return NoteCard(
                                            note: note,
                                            onTap: openContainer,
                                            tagColors: _tagColors,
                                            onLongPress: () =>
                                                _showNoteActions(note),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: displayedNotes.length,
                              itemBuilder: (context, index) {
                                final note = displayedNotes[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12.0),
                                        child: OpenContainer<bool>(
                                          transitionType:
                                              ContainerTransitionType.fade,
                                          openBuilder: (context, _) =>
                                              NoteEditorScreen(note: note),
                                          closedElevation: 0,
                                          closedColor: Colors.transparent,
                                          closedShape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          onClosed: (returned) async {
                                            if (returned == true) {
                                              await refreshNotes();
                                            }
                                          },
                                          closedBuilder:
                                              (context, openContainer) {
                                            return NoteCard(
                                              note: note,
                                              onTap: openContainer,
                                              tagColors: _tagColors,
                                              onLongPress: () =>
                                                  _showNoteActions(note),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
      );
    });
  }
}
