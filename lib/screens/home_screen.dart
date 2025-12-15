import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import '../data/database_helper.dart';
import '../data/note_model.dart';
import '../theme/app_theme.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';
import 'search_delegate.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> notes = [];
  List<Note> filteredNotes = [];
  bool isLoading = true;
  String selectedTag = 'All Notes';
  List<String> allTags = ['All Notes'];

  @override
  void initState() {
    super.initState();
    refreshNotes();
  }

  Future refreshNotes() async {
    setState(() => isLoading = true);
    notes = await DatabaseHelper.instance.readAllNotes();
    final tags = await DatabaseHelper.instance.getAllTags();
    allTags = ['All Notes', 'Archived', 'Trash', ...tags];

    // If selected tag no longer exists (e.g. deleted), revert to All Notes
    if (!allTags.contains(selectedTag)) {
      selectedTag = 'All Notes';
    }

    filterNotes();
    setState(() => isLoading = false);
  }

  void filterNotes() {
    if (selectedTag == 'All Notes') {
      filteredNotes =
          notes.where((n) => !n.isArchived && n.deletedAt == null).toList();
    } else if (selectedTag == 'Archived') {
      filteredNotes =
          notes.where((n) => n.isArchived && n.deletedAt == null).toList();
    } else if (selectedTag == 'Trash') {
      filteredNotes = notes.where((n) => n.deletedAt != null).toList();
    } else {
      // Filter by Tag
      filteredNotes = notes
          .where((note) =>
              note.tags.contains(selectedTag) &&
              !note.isArchived &&
              note.deletedAt == null)
          .toList();
    }
    // Sort by modification date desc
    filteredNotes.sort((a, b) => b.dateModified.compareTo(a.dateModified));
  }

  void onTagSelected(String tag) {
    setState(() {
      selectedTag = tag;
      filterNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search notes',
            onPressed: () {
              showSearch(context: context, delegate: NoteSearchDelegate());
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Color(0xFF3A3A3C),
              child: Icon(Icons.person, color: Colors.white),
            ),
            tooltip: 'Open settings',
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  )
                  .then((_) => refreshNotes()); // Refresh on return
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Tag Selector
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allTags.length,
              itemBuilder: (context, index) {
                final tag = allTags[index];
                final isSelected = tag == selectedTag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) onTagSelected(tag);
                    },
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainer,
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined,
                                size: 64,
                                color: AppTheme.textSecondary
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No notes here yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create one',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: MasonryGridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            return NoteCard(
                                note: filteredNotes[index],
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => NoteEditorScreen(
                                          note: filteredNotes[index]),
                                    ),
                                  );
                                  refreshNotes();
                                },
                                onLongPress: () =>
                                    _showNoteActions(filteredNotes[index]));
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create new note',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add,
            size: 28, color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
          );
          refreshNotes();
        },
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NoteCard(
      {super.key, required this.note, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    // If color is default dark, use surface container, else use note color
    final isDefaultColor = note.color == 0xFF252529;
    final bgColor = isDefaultColor
        ? Theme.of(context).colorScheme.surfaceContainer
        : Color(note.color);

    return Semantics(
        label:
            'Note ${note.title.isEmpty ? 'Untitled' : note.title}, modified ${DateFormat.MMMd().format(note.dateModified)}',
        button: true,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: isDefaultColor
                  ? Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.imagePath != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(note.imagePath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (note.content.isNotEmpty)
                  MarkdownBody(
                    data: note.content.length > 100
                        ? '${note.content.substring(0, 100)}...'
                        : note.content,
                    styleSheet: MarkdownStyleSheet(
                      p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: note.tags
                        .take(3)
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.MMMd().format(note.dateModified),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}

extension _Actions on _HomeScreenState {
  void _showNoteActions(Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: Colors.grey),
                title: Text(note.isPinned ? 'Unpin' : 'Pin',
                    style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  await DatabaseHelper.instance.updateNote(note.copyWith(
                      isPinned: !note.isPinned, dateModified: DateTime.now()));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  refreshNotes();
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined, color: Colors.grey),
                title: Text(note.isArchived ? 'Unarchive' : 'Archive',
                    style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  await DatabaseHelper.instance
                      .archiveNote(note.id, !note.isArchived);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  refreshNotes();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(
                    note.deletedAt == null
                        ? 'Move to Trash'
                        : 'Restore from Trash',
                    style: TextStyle(
                        color: note.deletedAt == null
                            ? Colors.redAccent
                            : Colors.white)),
                onTap: () async {
                  if (note.deletedAt == null) {
                    await DatabaseHelper.instance.deleteNote(note.id);
                  } else {
                    await DatabaseHelper.instance.restoreNote(note.id);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  refreshNotes();
                },
              ),
              if (note.deletedAt != null)
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
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
