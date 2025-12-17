import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../data/database_helper.dart';
import '../data/note_model.dart';
import '../data/settings_provider.dart';
import '../theme/app_theme.dart';
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
      backgroundColor: AppTheme.darkSurface, // Assuming dark or use theme
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.filterType == FilterType.archived) ...[
                ListTile(
                  leading:
                      const Icon(Icons.archive_outlined, color: Colors.grey),
                  title: const Text('Unarchive',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await DatabaseHelper.instance.archiveNote(note.id, false);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    refreshNotes();
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
                    refreshNotes();
                  },
                ),
              ] else ...[
                // Trash actions
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.white),
                  title: const Text('Restore',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await DatabaseHelper.instance.restoreNote(note.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    refreshNotes();
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
                    refreshNotes();
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
                    child: settings.isGridView
                        ? MasonryGridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            itemCount: displayedNotes.length,
                            itemBuilder: (context, index) {
                              return NoteCard(
                                note: displayedNotes[index],
                                tagColors: _tagColors,
                                onTap: () async {
                                  // For now, allow viewing editor.
                                  // If trash, maybe read-only?
                                  // Existing app allows edit of trash? Standard behavior usually requires restore to edit.
                                  // Let's assume standard behavior: if Archived, can edit. If Trash, maybe warn or readonly.
                                  // For simplicity matching current user state, let's open editor.
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => NoteEditorScreen(
                                          note: displayedNotes[index]),
                                    ),
                                  );
                                  refreshNotes();
                                },
                                onLongPress: () =>
                                    _showNoteActions(displayedNotes[index]),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: displayedNotes.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: NoteCard(
                                  note: displayedNotes[index],
                                  tagColors: _tagColors,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => NoteEditorScreen(
                                            note: displayedNotes[index]),
                                      ),
                                    );
                                    refreshNotes();
                                  },
                                  onLongPress: () =>
                                      _showNoteActions(displayedNotes[index]),
                                ),
                              );
                            },
                          ),
                  ),
      );
    });
  }
}
