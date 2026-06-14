import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import '../../data/note_model.dart';
import '../../data/settings_provider.dart';
import '../../providers/note_provider.dart';
import '../../screens/note_editor_screen.dart';
import '../../screens/home_screen.dart'; // For NoteCard for now, maybe move it too
import '../../data/repositories/note_repository.dart';

class NoteViewBuilder extends StatelessWidget {
  final VoidCallback onRefresh;
  final Function(Note, VoidCallback) onNoteTap;
  final Function(Note) onNoteLongPress;

  const NoteViewBuilder({
    super.key,
    required this.onRefresh,
    required this.onNoteTap,
    required this.onNoteLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final noteProvider = context.watch<NoteProvider>();
    final settings = context.watch<SettingsProvider>();

    if (noteProvider.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (noteProvider.filteredNotes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          key: const ValueKey('empty'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_alt_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                'No notes here yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to create one',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
                  ).then((_) => onRefresh());
                },
                icon: const Icon(Icons.add),
                label: const Text('Create My First Note'),
              ),
              ],
              ),
              ),
              );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      sliver: _buildSliverLayout(context, settings, noteProvider),
    );
  }

  Widget _buildSliverLayout(BuildContext context, SettingsProvider settings, NoteProvider noteProvider) {
    if (settings.noteViewMode == NoteViewMode.list) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final note = noteProvider.filteredNotes[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 220),
              child: SlideAnimation(
                verticalOffset: 24.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDismissibleNoteCard(context, note, onRefresh, noteProvider),
                  ),
                ),
              ),
            );
          },
          childCount: noteProvider.filteredNotes.length,
        ),
      );
    } else {
      // Grid (Masonry Grid)
      return SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childCount: noteProvider.filteredNotes.length,
        itemBuilder: (context, index) {
          final note = noteProvider.filteredNotes[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 220),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildOpenContainer(context, note, onRefresh, noteProvider),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildDismissibleNoteCard(BuildContext context, Note note, VoidCallback refresh, NoteProvider noteProvider) {
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.horizontal,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await NoteRepository.instance.softDeleteNote(note.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note moved to trash'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await NoteRepository.instance.restoreNote(note.id);
                  refresh();
                },
              ),
            ),
          );
        } else {
          final updated = note.copyWith(isArchived: true);
          await NoteRepository.instance.updateNote(updated);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note archived'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  final reverted = note.copyWith(isArchived: false);
                  await NoteRepository.instance.updateNote(reverted);
                  refresh();
                },
              ),
            ),
          );
        }
        refresh();
      },
      child: _buildOpenContainer(context, note, refresh, noteProvider),
    );
  }

  Widget _buildOpenContainer(BuildContext context, Note note, VoidCallback refresh, NoteProvider noteProvider) {
    return OpenContainer<bool>(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 300),
      openBuilder: (context, _) => NoteEditorScreen(note: note),
      closedElevation: 0,
      openElevation: 0,
      closedColor: Theme.of(context).colorScheme.surfaceContainer,
      openColor: Theme.of(context).colorScheme.surface,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onClosed: (returned) async {
        if (returned == true) {
          refresh();
        }
      },
      closedBuilder: (context, openContainer) {
        return NoteCard(
          note: note,
          onTap: () => onNoteTap(note, openContainer),
          isSelected: noteProvider.selectedNoteIds.contains(note.id),
          tagColors: noteProvider.tagColors,
          onLongPress: () => onNoteLongPress(note),
        );
      },
    );
  }
}
