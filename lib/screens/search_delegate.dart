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
        backgroundColor: const Color(0xFF161618),
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
    return FutureBuilder<List<Note>>(
      future: DatabaseHelper.instance.searchNotes(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notes = snapshot.data!;

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

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(); // Optional suggestions
  }
}
