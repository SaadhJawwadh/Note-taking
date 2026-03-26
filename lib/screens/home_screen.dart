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
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'file_converter_screen.dart';
import 'app_lock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Note> notes = [];
  List<Note> filteredNotes = [];
  bool isLoading = true;
  String selectedTag = 'All';
  List<String> allTags = ['All'];
  int _currentIndex = 0;
  Set<String> selectedNoteIds = {};
  bool isSelectionMode = false;
  
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreNotes = true;
  
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    refreshNotes();
    
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && mounted) {
        _navigateToConverter(value.map((f) => f.path).toList());
      }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && mounted) {
        _navigateToConverter(value.map((f) => f.path).toList());
      }
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshNotes();
    }
  }


  void _navigateToConverter(List<String> paths) {
    // Unlock session for sharing utility to avoid interrupting the user
    AppLockScreen.unlockSession();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileConverterScreen(initialFilePaths: paths),
      ),
    );
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, int> _tagColors = {};

  IconData _getIconForMode(NoteViewMode mode) {
    switch (mode) {
      case NoteViewMode.list: return Icons.view_agenda_outlined;
      case NoteViewMode.masonryGrid: return Icons.grid_view_outlined;
      case NoteViewMode.uniformGrid: return Icons.dashboard_outlined;
    }
  }

  String _getTooltipForMode(NoteViewMode mode) {
    switch (mode) {
      case NoteViewMode.list: return 'List view';
      case NoteViewMode.masonryGrid: return 'Masonry grid view';
      case NoteViewMode.uniformGrid: return 'Uniform grid view';
    }
  }

  void _cycleViewMode(SettingsProvider settings) {
    const values = NoteViewMode.values;
    final nextIndex = (settings.noteViewMode.index + 1) % values.length;
    settings.setNoteViewMode(values[nextIndex]);
  }

  Future refreshNotes() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      _currentPage = 0;
      _hasMoreNotes = true;
    });

    // 1. Fetch tags and colors (small tables)
    final tags = await DatabaseHelper.instance.getAllTags();
    final colors = await DatabaseHelper.instance.getAllTagColors();

    // 2. Fetch first page of notes
    final fetchedNotes = await DatabaseHelper.instance.readAllNotes(
      limit: _pageSize,
      offset: 0,
    );

    // 3. Optional: Still sort tags by MRU based on ALL active notes (lightweight query)
    // For now, we'll just use the tags as fetched or from the first page if we want MRU.
    // Let's assume tags are already somewhat ordered or order doesn't matter as much as performance.
    
    allTags = ['All', ...tags];
    if (!allTags.contains(selectedTag)) {
      selectedTag = 'All';
    }

    _tagColors = colors;
    
    if (mounted) {
      setState(() {
        notes = fetchedNotes;
        filterNotes();
        isLoading = false;
        if (fetchedNotes.length < _pageSize) {
          _hasMoreNotes = false;
        }
      });
    }
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

  void onNoteTap(Note note, VoidCallback openContainer) {
    if (isSelectionMode) {
      toggleSelection(note.id);
    } else {
      openContainer();
    }
  }

  void onNoteLongPress(Note note) {
    toggleSelection(note.id);
  }

  void toggleSelection(String id) {
    setState(() {
      if (selectedNoteIds.contains(id)) {
        selectedNoteIds.remove(id);
        if (selectedNoteIds.isEmpty) isSelectionMode = false;
      } else {
        selectedNoteIds.add(id);
        isSelectionMode = true;
      }
    });
  }

  void clearSelection() {
    setState(() {
      selectedNoteIds.clear();
      isSelectionMode = false;
    });
  }

  Future<void> bulkArchive() async {
    for (final id in selectedNoteIds) {
      final note = notes.firstWhere((n) => n.id == id);
      await DatabaseHelper.instance.updateNote(note.copyWith(isArchived: true));
    }
    clearSelection();
    await refreshNotes();
  }

  Future<void> bulkDelete() async {
    for (final id in selectedNoteIds) {
      await DatabaseHelper.instance.softDeleteNote(id);
    }
    clearSelection();
    await refreshNotes();
  }

  Future<void> bulkTag() async {
    final availableTags = allTags.where((t) => t != 'All').toList();
    if (availableTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tags available. Create a tag first.')),
      );
      return;
    }

    final selectedNewTag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag to Selected'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableTags.length,
            itemBuilder: (context, index) {
              final tag = availableTags[index];
              return ListTile(
                title: Text(tag),
                onTap: () => Navigator.pop(context, tag),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ],
      ),
    );

    if (selectedNewTag != null) {
      for (final id in selectedNoteIds) {
        final note = notes.firstWhere((n) => n.id == id);
        if (!note.tags.contains(selectedNewTag)) {
          final newTags = [...note.tags, selectedNewTag];
          await DatabaseHelper.instance
              .updateNote(note.copyWith(tags: newTags));
        }
      }
      clearSelection();
      await refreshNotes();
    }
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
      // Return simple Notes View if no extra features are enabled
      if (!settings.showFinancialManager && 
          !settings.isPeriodTrackerEnabled && 
          !settings.showFileConverter) {
        return _buildNotesView(context, settings);
      }

      // Return Bottom Nav View if any feature is enabled
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
            if (settings.showFileConverter)
              const NavigationDestination(
                icon: Icon(Icons.transform_rounded),
                selectedIcon: Icon(Icons.transform_rounded),
                label: 'Converter',
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

    // Notes is always at 0
    if (_currentIndex == 0) return _buildNotesView(context, settings);
    index++;

    // Check File Converter
    if (settings.showFileConverter) {
      if (_currentIndex == index) return const FileConverterScreen();
      index++;
    }

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
        controller: _scrollController,
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
                color: isSelectionMode
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isSelectionMode
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: clearSelection,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedNoteIds.length} selected',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.archive_outlined),
                          tooltip: 'Archive selected',
                          onPressed: bulkArchive,
                        ),
                        IconButton(
                          icon: const Icon(Icons.label_outline),
                          tooltip: 'Tag selected',
                          onPressed: bulkTag,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete selected',
                          color: Colors.red,
                          onPressed: bulkDelete,
                        ),
                      ],
                    )
                  : Row(
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
                          icon: Icon(_getIconForMode(settings.noteViewMode)),
                          tooltip: _getTooltipForMode(settings.noteViewMode),
                          onPressed: () => _cycleViewMode(settings),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: 'Global search',
                          onPressed: () {
                            showSearch(
                                context: context, delegate: GlobalSearchDelegate());
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
                child: _buildSliverLayout(settings),
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

  Widget _buildSliverLayout(SettingsProvider settings) {
    if (settings.noteViewMode == NoteViewMode.list) {
      return SliverList(
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
                    child: _buildDismissibleNoteCard(note),
                  ),
                ),
              ),
            );
          },
          childCount: filteredNotes.length,
        ),
      );
    } else if (settings.noteViewMode == NoteViewMode.uniformGrid) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8, // Uniform aspect ratio
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final note = filteredNotes[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 220),
              columnCount: 2,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: _buildOpenContainer(note),
                ),
              ),
            );
          },
          childCount: filteredNotes.length,
        ),
      );
    } else {
      // Masonry Grid
      return SliverMasonryGrid.count(
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
                child: _buildOpenContainer(note),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildDismissibleNoteCard(Note note) {
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
          // Swipe left -> Delete to trash
          await DatabaseHelper.instance.softDeleteNote(note.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note moved to trash'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await DatabaseHelper.instance.restoreNote(note.id);
                  await refreshNotes();
                },
              ),
            ),
          );
        } else {
          // Swipe right -> Archive
          final updated = note.copyWith(isArchived: true);
          await DatabaseHelper.instance.updateNote(updated);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note archived'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  final reverted = note.copyWith(isArchived: false);
                  await DatabaseHelper.instance.updateNote(reverted);
                  await refreshNotes();
                },
              ),
            ),
          );
        }
        await refreshNotes();
      },
      child: _buildOpenContainer(note),
    );
  }

  Widget _buildOpenContainer(Note note) {
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
          await refreshNotes();
        }
      },
      closedBuilder: (context, openContainer) {
        return NoteCard(
          note: note,
          onTap: () => onNoteTap(note, openContainer),
          isSelected: selectedNoteIds.contains(note.id),
          tagColors: _tagColors,
          onLongPress: () => onNoteLongPress(note),
        );
      },
    );
  }

  void _scrollListener() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 500 &&
        !_isLoadingMore &&
        _hasMoreNotes &&
        selectedTag == 'All') {
      _loadMoreNotes();
    }
  }

  Future<void> _loadMoreNotes() async {
    if (_isLoadingMore || !_hasMoreNotes) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    final moreNotes = await DatabaseHelper.instance.readAllNotes(
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );

    if (mounted) {
      setState(() {
        notes.addAll(moreNotes);
        filterNotes();
        _isLoadingMore = false;
        if (moreNotes.length < _pageSize) {
          _hasMoreNotes = false;
        }
      });
    }
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Map<String, int>? tagColors;

  final bool isSelected;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLongPress,
    this.tagColors,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic Material You logic
    final isSystemDefault = note.color == 0;
    final theme = Theme.of(context);

    Color backgroundColor;
    Color borderColor;

    if (isSystemDefault) {
      backgroundColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.3);
    } else {
      final scheme = ColorScheme.fromSeed(
        seedColor: Color(note.color),
        brightness: theme.brightness,
      );
      backgroundColor = scheme.surfaceContainerLow;
      borderColor = scheme.outline.withValues(alpha: 0.2);
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
              color: isSelected ? theme.colorScheme.primaryContainer : backgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSystemDefault ? null : [
                BoxShadow(
                  color: Color(note.color).withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
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
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ));
  }
}

