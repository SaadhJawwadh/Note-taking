import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../data/database_helper.dart';
import '../data/note_model.dart';
import 'home_screen.dart'; // For NoteCard
import 'note_editor_screen.dart';

class NoteSearchDelegate extends SearchDelegate {
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text("Type something to search"));
    }
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text("Search for notes..."));
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        DatabaseHelper.instance.searchNotes(query),
        DatabaseHelper.instance.getAllTagColors(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final notes = snapshot.data?[0] as List<Note>? ?? [];
        final tagColors = snapshot.data?[1] as Map<String, int>? ?? {};

        if (notes.isEmpty) {
          return const Center(child: Text("No results found"));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return Semantics(
                label: 'Search result: ${notes[index].title}',
                button: true,
                child: NoteCard(
                  note: notes[index],
                  tagColors: tagColors,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NoteEditorScreen(note: notes[index]),
                        ));
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
