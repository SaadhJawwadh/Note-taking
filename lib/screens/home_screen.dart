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
import 'financial_manager_screen.dart';
import 'period_tracker_screen.dart';
import '../utils/rich_text_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> notes = [];
  List<Note> filteredNotes = [];
  bool isLoading = true;
  String selectedTag = 'All';
  List<String> allTags = ['All'];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    refreshNotes();
  }

  Map<String, int> _tagColors = {};

  Future refreshNotes() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    notes = await DatabaseHelper.instance.readAllNotes();
    final tags = await DatabaseHelper.instance.getAllTags();
    final colors = await DatabaseHelper.instance.getAllTagColors();

    // Sort tags by most recently modified active note (MRU)
    final tagLastModified = <String, DateTime>{};
    for (final note in notes) {
      if (note.isArchived || note.deletedAt != null) continue;
      for (final tag in note.tags) {
        final existing = tagLastModified[tag];
        if (existing == null || note.dateModified.isAfter(existing)) {
          tagLastModified[tag] = note.dateModified;
        }
      }
    }
    tags.sort((a, b) {
      final aTime = tagLastModified[a];
      final bTime = tagLastModified[b];
      if (aTime == null && bTime == null) return a.compareTo(b);
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    allTags = ['All', ...tags];

    // If selected tag no longer exists (e.g. deleted), revert to All Notes
    if (!allTags.contains(selectedTag)) {
      selectedTag = 'All';
    }

    // Refresh local colors map
    _tagColors = colors;

    filterNotes();
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void filterNotes() {
    if (selectedTag == 'All') {
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
        selectedTag = 'All';
      } else {
        selectedTag = tag;
      }
      filterNotes();
    });
  }

  Future<void> _editTag(String tag) async {
    final controller = TextEditingController(text: tag);
    int selectedColor = _tagColors[tag] ?? 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Edit Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Tag Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('Tag Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: AppTheme.noteColors.map((c) {
                  final bool isSystem = c.toARGB32() == 0;
                  final bool isSelected = selectedColor == c.toARGB32();
                  return Semantics(
                    label: isSystem ? 'System Default Color' : 'Color option',
                    selected: isSelected,
                    button: true,
                    child: GestureDetector(
                      onTap: () => setState(() => selectedColor = c.toARGB32()),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSystem
                              ? Theme.of(context).colorScheme.surface
                              : c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSystem
                            ? const Icon(Icons.auto_awesome, size: 16)
                            : (isSelected
                                ? Icon(Icons.check,
                                    size: 16,
                                    color: c.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white)
                                : null),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  if (newName != tag) {
                    await DatabaseHelper.instance.renameTag(tag, newName);
                  }
                  if (selectedColor != (_tagColors[tag] ?? 0)) {
                    await DatabaseHelper.instance
                        .setTagColor(newName, selectedColor);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);

                  // Update selected tag if it was the one modified
                  if (selectedTag == tag) {
                    selectedTag = newName;
                  }

                  await refreshNotes();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _deleteTag(String tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag?'),
        content: Text(
            'Are you sure you want to delete "$tag"? This will remove the tag from all notes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteTag(tag);
      if (selectedTag == tag) {
        selectedTag = 'All';
      }
      await refreshNotes();
    }
  }

  void _showTagOptions(String tag) {
    if (tag == 'All') return; // Cannot edit/delete 'All Notes'

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Tag'),
              onTap: () {
                Navigator.pop(context);
                _editTag(tag);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title:
                  const Text('Delete Tag', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteTag(tag);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      // Return simple Notes View if both features are disabled
      if (!settings.showFinancialManager && !settings.isPeriodTrackerEnabled) {
        return _buildNotesView(context, settings);
      }

      // Return Bottom Nav View if enabled
      return Scaffold(
        body: PageTransitionSwitcher(
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: _buildCurrentScreen(settings),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.note_alt_outlined),
              selectedIcon: Icon(Icons.note_alt),
              label: 'Notes',
            ),
            if (settings.showFinancialManager)
              const NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Finances',
              ),
            if (settings.isPeriodTrackerEnabled)
              const NavigationDestination(
                icon: Icon(Icons.water_drop_outlined),
                selectedIcon: Icon(Icons.water_drop),
                label: 'Tracker',
              ),
          ],
        ),
      );
    });
  }

  Widget _buildCurrentScreen(SettingsProvider settings) {
    int index = 0;

    // Check index 0
    if (_currentIndex == index) return _buildNotesView(context, settings);
    index++;

    // Check Financial Manager
    if (settings.showFinancialManager) {
      if (_currentIndex == index) return const FinancialManagerScreen();
      index++;
    }

    // Check Period Tracker
    if (settings.isPeriodTrackerEnabled) {
      if (_currentIndex == index) return const PeriodTrackerScreen();
      index++;
    }

    // Default fallback
    return _buildNotesView(context, settings);
  }

  Widget _buildNotesView(BuildContext context, SettingsProvider settings) {
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
                    'Note book',
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
                                  builder: (context) => const SettingsScreen()),
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
                  BorderSide? chipSide;

                  if (isSelected) {
                    if (tagColorValue != null && tagColorValue != 0) {
                      final scheme = ColorScheme.fromSeed(
                          seedColor: Color(tagColorValue),
                          brightness: Theme.of(context).brightness);
                      chipBg = scheme.primary;
                      chipFg = scheme.onPrimary;
                    } else {
                      chipBg = Theme.of(context).colorScheme.primary;
                      chipFg = Theme.of(context).colorScheme.onPrimary;
                    }
                    chipSide = BorderSide.none;
                  } else {
                    if (tagColorValue != null && tagColorValue != 0) {
                      final scheme = ColorScheme.fromSeed(
                          seedColor: Color(tagColorValue),
                          brightness: Theme.of(context).brightness);
                      chipBg = Colors.transparent;
                      chipFg = scheme.primary;
                      chipSide = BorderSide(color: scheme.primary);
                    } else {
                      chipBg = Colors.transparent;
                      chipFg = Theme.of(context).colorScheme.onSurfaceVariant;
                      chipSide = BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      );
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onLongPress: () => _showTagOptions(tag),
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
                        side: chipSide,
                        showCheckmark: false,
                      ),
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
                        color: Theme.of(context).colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No notes here yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
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
                            duration: const Duration(milliseconds: 220),
                            columnCount: 2,
                            child: ScaleAnimation(
                              child: FadeInAnimation(
                                child: OpenContainer<bool>(
                                  transitionType:
                                      ContainerTransitionType.fadeThrough,
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                  openBuilder: (context, _) =>
                                      NoteEditorScreen(note: note),
                                  closedElevation: 0,
                                  openElevation: 0,
                                  closedColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  openColor:
                                      Theme.of(context).colorScheme.surface,
                                  closedShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
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
                          );
                        },
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final note = filteredNotes[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 220),
                              child: SlideAnimation(
                                verticalOffset: 24.0,
                                child: FadeInAnimation(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: OpenContainer<bool>(
                                      transitionType:
                                          ContainerTransitionType.fadeThrough,
                                      transitionDuration:
                                          const Duration(milliseconds: 300),
                                      openBuilder: (context, _) =>
                                          NoteEditorScreen(note: note),
                                      closedElevation: 0,
                                      openElevation: 0,
                                      closedColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                      openColor:
                                          Theme.of(context).colorScheme.surface,
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
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: const Duration(milliseconds: 300),
        openBuilder: (context, _) => const NoteEditorScreen(),
        closedElevation: 6.0,
        openElevation: 0,
        closedShape: const StadiumBorder(),
        closedColor: Theme.of(context).colorScheme.primary,
        openColor: Theme.of(context).colorScheme.surface,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.6), // Subtle but visible
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (note.title.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (note.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.push_pin,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  if (note.imagePath != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(note.imagePath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (note.content.isNotEmpty)
                    MarkdownBody(
                      data: () {
                        String md;
                        if (note.content.startsWith('[')) {
                          final delta =
                              RichTextUtils.contentToDelta(note.content);
                          md = RichTextUtils.deltaToMarkdown(delta);
                        } else {
                          md = note.content;
                        }
                        final lines = md.split('\n');
                        final preview = lines.take(6).join('\n');
                        return lines.length > 6 ? '$preview...' : preview;
                      }(),
                      checkboxBuilder: (value) {
                        return Icon(
                          value
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 16,
                          color: theme.colorScheme.primary,
                        );
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        checkbox: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                        blockquote: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.9),
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
                          backgroundColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.1),
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
                        Color bg;
                        Color fg;

                        if (colorVal != null && colorVal != 0) {
                          final scheme = ColorScheme.fromSeed(
                              seedColor: Color(colorVal),
                              brightness: Theme.of(context).brightness);
                          bg = scheme.primaryContainer;
                          fg = scheme.onPrimaryContainer;
                        } else {
                          // Fallback
                          bg = Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.5);
                          fg = Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            // No border for filled style
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: fg,
                              fontWeight: FontWeight.w600,
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
                title: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Move to Trash?'),
                      content: const Text('This note will be moved to Trash.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Move to Trash'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await DatabaseHelper.instance.softDeleteNote(note.id);
                    await refreshNotes();
                  }
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
