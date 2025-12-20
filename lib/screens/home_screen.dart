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
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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

  Map<String, int> _tagColors = {};

  Future refreshNotes() async {
    setState(() => isLoading = true);
    notes = await DatabaseHelper.instance.readAllNotes();
    final tags = await DatabaseHelper.instance.getAllTags();
    final colors = await DatabaseHelper.instance.getAllTagColors();
    allTags = ['All Notes', ...tags];

    // If selected tag no longer exists (e.g. deleted), revert to All Notes
    if (!allTags.contains(selectedTag)) {
      selectedTag = 'All Notes';
    }

    // Refresh local colors map
    _tagColors = colors;

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
    // Sort by Pinned DESC (pinned=1, unpinned=0) then Modification Date DESC
    filteredNotes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1; // Pinned first
      }
      return b.dateModified.compareTo(a.dateModified);
    });
  }

  void onTagSelected(String tag) {
    setState(() {
      if (selectedTag == tag) {
        selectedTag = 'All Notes';
      } else {
        selectedTag = tag;
      }
      filterNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              floating: true,
              snap: true,
              toolbarHeight: 84, // Taller to accommodate the float and shadow
              titleSpacing: 16,
              automaticallyImplyLeading: false, // Home doesn't need back
              title: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(settings.isGridView
                          ? Icons.view_agenda_outlined
                          : Icons.grid_view_outlined),
                      tooltip: settings.isGridView ? 'List view' : 'Grid view',
                      onPressed: () {
                        settings.setIsGridView(!settings.isGridView);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: 'Search notes',
                      onPressed: () {
                        showSearch(
                            context: context, delegate: NoteSearchDelegate());
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen()),
                              )
                              .then((_) => refreshNotes());
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Tag Selector
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allTags.length,
                  itemBuilder: (context, index) {
                    final tag = allTags[index];
                    final isSelected = tag == selectedTag;
                    final tagColorValue = _tagColors[tag];

                    Color? chipBg;
                    Color? chipFg;

                    if (tagColorValue != null && tagColorValue != 0) {
                      final scheme = ColorScheme.fromSeed(
                          seedColor: Color(tagColorValue),
                          brightness: Theme.of(context).brightness);
                      chipBg = isSelected
                          ? scheme.inversePrimary
                          : scheme.primaryContainer;
                      chipFg = isSelected
                          ? scheme.onInverseSurface
                          : scheme.onPrimaryContainer;

                      if (isSelected) {
                        chipBg = scheme.primary;
                        chipFg = scheme.onPrimary;
                      }
                    }

                    // Fallbacks
                    chipBg ??= Theme.of(context).colorScheme.surfaceContainer;
                    chipFg ??= isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant;
                    if (isSelected &&
                        chipBg ==
                            Theme.of(context).colorScheme.surfaceContainer) {
                      chipBg = Theme.of(context).colorScheme.primaryContainer;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) onTagSelected(tag);
                        },
                        backgroundColor: chipBg,
                        selectedColor: chipBg,
                        labelStyle: TextStyle(
                          color: chipFg,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Content
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredNotes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  key: const ValueKey('empty'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_alt_outlined,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No notes here yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create one',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: AnimationLimiter(
                  child: settings.isGridView
                      ? SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
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
                                    closedBuilder: (context, openContainer) {
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
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final note = filteredNotes[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
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
                            childCount: filteredNotes.length,
                          ),
                        ),
                ),
              ),
          ],
        ),
        floatingActionButton: OpenContainer<bool>(
          transitionType: ContainerTransitionType.fade,
          openBuilder: (context, _) => const NoteEditorScreen(),
          closedElevation: 6.0,
          closedShape: const StadiumBorder(),
          closedColor: Theme.of(context).colorScheme.primary,
          onClosed: (returned) async {
            if (returned == true) await refreshNotes();
          },
          closedBuilder: (context, openContainer) {
            return SizedBox(
              height: 56,
              child: FloatingActionButton.extended(
                label: const Text('New Note'),
                icon: const Icon(Icons.add),
                tooltip: 'Create new note',
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 0,
                shape: const StadiumBorder(),
                onPressed: openContainer,
              ),
            );
          },
        ),
      );
    });
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Map<String, int>? tagColors;

  const NoteCard(
      {super.key,
      required this.note,
      required this.onTap,
      this.onLongPress,
      this.tagColors});

  @override
  Widget build(BuildContext context) {
    // Dynamic Material You logic
    final isSystemDefault = note.color == 0;
    final theme = Theme.of(context);

    Color backgroundColor;
    Color borderColor;

    if (isSystemDefault) {
      backgroundColor = theme.colorScheme.surfaceContainer;
      borderColor = theme.colorScheme.outlineVariant;
    } else {
      final scheme = ColorScheme.fromSeed(
        seedColor: Color(note.color),
        brightness: theme.brightness,
      );
      backgroundColor = scheme.surfaceContainerHigh;
      borderColor = scheme.outline; // Use outline color for visibility
    }

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
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.6), // Subtle but visible
                width: 1,
              ),
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
                      p: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      blockquote: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.9),
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: isSystemDefault
                            ? theme.colorScheme.surfaceContainerHighest
                            : ColorScheme.fromSeed(
                                    seedColor: Color(note.color),
                                    brightness: theme.brightness)
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                        border: Border(
                          left: BorderSide(
                            color: isSystemDefault
                                ? theme.colorScheme.primary
                                : ColorScheme.fromSeed(
                                        seedColor: Color(note.color),
                                        brightness: theme.brightness)
                                    .primary,
                            width: 3,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.all(8),
                      code: TextStyle(
                        backgroundColor:
                            theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: note.tags.take(3).map((tag) {
                      final colorVal = tagColors?[tag];
                      Color? bg;
                      Color? fg;
                      if (colorVal != null && colorVal != 0) {
                        final scheme = ColorScheme.fromSeed(
                            seedColor: Color(colorVal),
                            brightness: Theme.of(context).brightness);
                        bg = scheme.primaryContainer;
                        fg = scheme.onPrimaryContainer;
                      }
                      // Fallback
                      bg ??= Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.5);
                      fg ??= Theme.of(context).colorScheme.onSecondaryContainer;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            color: fg,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
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
              ListTile(
                leading: Icon(
                    note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: onSurfaceVariant),
                title: Text(note.isPinned ? 'Unpin' : 'Pin',
                    style: TextStyle(color: onSurface)),
                onTap: () async {
                  await DatabaseHelper.instance.updateNote(note.copyWith(
                      isPinned: !note.isPinned, dateModified: DateTime.now()));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  await refreshNotes();
                },
              ),
              ListTile(
                leading: Icon(Icons.archive_outlined, color: onSurfaceVariant),
                title: Text(note.isArchived ? 'Unarchive' : 'Archive',
                    style: TextStyle(color: onSurface)),
                onTap: () async {
                  await DatabaseHelper.instance
                      .archiveNote(note.id, !note.isArchived);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  await refreshNotes();
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
                            : onSurface)),
                onTap: () async {
                  if (note.deletedAt == null) {
                    await DatabaseHelper.instance.deleteNote(note.id);
                  } else {
                    await DatabaseHelper.instance.restoreNote(note.id);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  await refreshNotes();
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
                    await refreshNotes();
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
