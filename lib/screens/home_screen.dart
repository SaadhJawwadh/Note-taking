import 'package:flutter/material.dart';
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
  String selectedCategory = 'All Notes';
  final List<String> categories = [
    'All Notes',
    'Journal',
    'Work',
    'Personal',
    'Ideas',
    'Archived',
    'Trash'
  ];

  @override
  void initState() {
    super.initState();
    refreshNotes();
  }

  Future refreshNotes() async {
    setState(() => isLoading = true);
    notes = await DatabaseHelper.instance.readAllNotes();
    filterNotes();
    setState(() => isLoading = false);
  }

  void filterNotes() {
    if (selectedCategory == 'All Notes') {
      filteredNotes = notes.where((n) => !n.isArchived).toList();
    } else if (selectedCategory == 'Archived') {
      filteredNotes =
          notes.where((n) => n.isArchived && n.deletedAt == null).toList();
    } else if (selectedCategory == 'Trash') {
      // Load from DB to include deleted notes
      // For simplicity, fetch trashed notes synchronously via cached list if present
      filteredNotes = notes.where((n) => n.deletedAt != null).toList();
    } else {
      filteredNotes = notes
          .where((note) =>
              note.category == selectedCategory &&
              !note.isArchived &&
              note.deletedAt == null)
          .toList();
    }
  }

  void onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
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
            onPressed: () {
              showSearch(context: context, delegate: NoteSearchDelegate());
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Color(0xFF3A3A3C),
              child: Icon(Icons.person, color: Colors.white),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Category Selector
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) onCategorySelected(category);
                    },
                    backgroundColor: const Color(0xFF2C2C30),
                    selectedColor: AppTheme.primaryPurple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
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
                        child: Text(
                          'No notes here',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
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
        child: const Icon(Icons.add, size: 28),
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
    final bgColor = Color(note.color);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor == const Color(0xFF252529)
              ? const Color(0xFF2C2C30)
              : bgColor,
          borderRadius: BorderRadius.circular(20),
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
                  ?.copyWith(fontSize: 18),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.imagePath != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(note.imagePath!),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              note.content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.MMMd().format(note.dateModified),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary.withOpacity(0.6),
                        fontSize: 12,
                      ),
                ),
                if (note.category != 'All Notes')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      note.category,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  )
              ],
            ),
          ],
        ),
      ),
    );
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
