import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';

import '../data/note_model.dart';
import '../data/note_templates.dart';
import '../data/settings_provider.dart';
import '../providers/note_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_layout.dart';
import '../widgets/tag_filter_bar.dart';
import '../widgets/home/home_app_bar.dart';
import '../widgets/home/note_view_builder.dart';
import 'note_editor_screen.dart';
import 'search_delegate.dart';
import 'financial_manager_screen.dart';
import 'period_tracker_screen.dart';
import 'app_lock_screen.dart';
import 'transaction_editor_screen.dart';
import '../data/repositories/note_repository.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/onboarding_sheet.dart';
import '../utils/widget_helper.dart';
import '../l10n/app_localizations.dart';
import '../widgets/whats_new_sheet.dart';
import '../services/update_rating_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _onboardingChecked = false;
  bool _whatsNewChecked = false;
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);

    // Update home screen widget on startup to ensure intents are fresh
    unawaited(WidgetHelper.updateWidgetData());

    AppLockScreen.sessionAuthenticated.addListener(_handleSessionUnlock);
    AppLockScreen.sharedMediaTick.addListener(_handleSharedMediaTick);

    // Warm shares while unlocked land here; locked ones are parked by
    // AppLockScreen and consumed in _checkAndProcessPendingIntents.
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      if (files.isEmpty || !mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final isLocked =
          settings.appLockEnabled && !AppLockScreen.sessionAuthenticated.value;
      if (!isLocked) {
        unawaited(_openSharedAsNote(files));
      }
    }, onError: (err) {
      debugPrint('getMediaStream error: $err');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndProcessPendingIntents();
      }
    });
  }

  void _handleSessionUnlock() {
    if (AppLockScreen.sessionAuthenticated.value && mounted) {
      _checkAndProcessPendingIntents();
    }
  }

  void _handleSharedMediaTick() {
    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isLocked =
        settings.appLockEnabled && !AppLockScreen.sessionAuthenticated.value;
    if (!isLocked) {
      _checkAndProcessPendingIntents();
    }
  }

  /// Turns shared media (text, links, images) into a prefilled new note.
  Future<void> _openSharedAsNote(List<SharedMediaFile> files) async {
    final textParts = <String>[];
    final imagePaths = <String>[];

    for (final file in files) {
      switch (file.type) {
        case SharedMediaType.text:
        case SharedMediaType.url:
          if (file.path.trim().isNotEmpty) textParts.add(file.path.trim());
          break;
        case SharedMediaType.image:
          final copied = await _copySharedImage(file.path);
          if (copied != null) imagePaths.add(copied);
          break;
        default:
          break;
      }
    }

    if (textParts.isEmpty && imagePaths.isEmpty) return;
    if (!mounted) return;

    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            final noteProvider = Provider.of<NoteProvider>(context, listen: false);
            return NoteEditorScreen(
              initialSharedText: textParts.isEmpty ? null : textParts.join('\n'),
              initialSharedImagePaths: imagePaths.isEmpty ? null : imagePaths,
              initialFolder: noteProvider.selectedFolder,
            );
          },
        ),
      ),
    );
  }

  /// Copies a shared image out of the transient share cache into app
  /// documents so the note's embed doesn't break when the cache is purged.
  Future<String?> _copySharedImage(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'shared_images'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final target = p.join(dir.path,
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}');
      await source.copy(target);
      return target;
    } catch (e) {
      debugPrint('Error copying shared image: $e');
      return sourcePath; // fall back to the cache path rather than dropping it
    }
  }

  Future<void> _checkAndProcessPendingIntents() async {
    // Shares parked by AppLockScreen (cold start or arrived-while-locked).
    final pendingShared = AppLockScreen.pendingSharedMedia;
    if (pendingShared != null && pendingShared.isNotEmpty) {
      AppLockScreen.pendingSharedMedia = null;
      unawaited(_openSharedAsNote(pendingShared));
      return;
    }

    try {
      const widgetChannel = MethodChannel('com.saadhjawwadh.notebook/widget');
      final String? action = await widgetChannel.invokeMethod<String>('getPendingAction');
      if (action == 'add_transaction' && mounted) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        if (settings.showFinancialManager) {
          final List<Widget> destinations = _buildDestinations(settings);
          int financesIndex = -1;
          for (int i = 0; i < destinations.length; i++) {
            if (destinations[i] is FinancialManagerScreen) {
              financesIndex = i;
              break;
            }
          }
          if (financesIndex != -1) {
            setState(() {
              _currentIndex = financesIndex;
            });
          }
        }
        if (mounted) {
          unawaited(
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditorScreen()),
            ),
          );
        }
      } else if (action == 'view_budgets' && mounted) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        if (settings.showFinancialManager) {
          final List<Widget> destinations = _buildDestinations(settings);
          int financesIndex = -1;
          for (int i = 0; i < destinations.length; i++) {
            if (destinations[i] is FinancialManagerScreen) {
              financesIndex = i;
              break;
            }
          }
          if (financesIndex != -1) {
            setState(() {
              _currentIndex = financesIndex;
            });
            FinancialManagerScreen.tabRedirectNotifier.value = 'Budgets';
          }
        }
      } else if (action == 'new_note' && mounted) {
        final noteProvider = Provider.of<NoteProvider>(context, listen: false);
        unawaited(
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(initialFolder: noteProvider.selectedFolder),
            ),
          ),
        );
      } else if (action == 'search' && mounted) {
        unawaited(
          showSearch(context: context, delegate: GlobalSearchDelegate()),
        );
      } else if (action == 'process_text' && mounted) {
        final String? sharedText =
            await widgetChannel.invokeMethod<String>('getPendingSharedText');
        if (sharedText != null && sharedText.trim().isNotEmpty && mounted) {
          final noteProvider = Provider.of<NoteProvider>(context, listen: false);
          unawaited(
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    NoteEditorScreen(
                      initialSharedText: sharedText,
                      initialFolder: noteProvider.selectedFolder,
                    ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting pending widget action: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NoteProvider>().refreshNotes();
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final bool isLocked = settings.appLockEnabled && !AppLockScreen.sessionAuthenticated.value;
      if (!isLocked) {
        _checkAndProcessPendingIntents();
      }
    }
  }

  @override
  void dispose() {
    unawaited(_intentDataStreamSubscription?.cancel());
    _scrollController.dispose();
    AppLockScreen.sessionAuthenticated.removeListener(_handleSessionUnlock);
    AppLockScreen.sharedMediaTick.removeListener(_handleSharedMediaTick);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _bulkDeleteWithUndo(NoteProvider noteProvider) async {
    final ids = await noteProvider.bulkDelete();
    if (ids.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text(ids.length == 1
            ? 'Note moved to Trash'
            : '${ids.length} notes moved to Trash'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            for (final id in ids) {
              await NoteRepository.instance.restoreNote(id);
            }
            await refreshNotes();
          },
        ),
      ),
    );
  }

  void _cycleViewMode(SettingsProvider settings) {
    const values = NoteViewMode.values;
    final nextIndex = (settings.noteViewMode.index + 1) % values.length;
    settings.setNoteViewMode(values[nextIndex]);
  }

  Future<void> refreshNotes() async {
    if (!mounted) return;
    await context.read<NoteProvider>().refreshNotes();
  }

  void onNoteTap(Note note, VoidCallback openContainer) {
    if (context.read<NoteProvider>().isSelectionMode) {
      context.read<NoteProvider>().toggleSelection(note.id);
    } else {
      openContainer();
    }
  }

  void onNoteLongPress(Note note) {
    context.read<NoteProvider>().toggleSelection(note.id);
  }

  Future<void> bulkTag() async {
    final noteProvider = context.read<NoteProvider>();
    final availableTags = noteProvider.allTags.where((t) => t != 'All' && t != 'Archived' && t != 'Trash').toList();
    if (availableTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tags available. Create a tag first.')));
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
            itemBuilder: (context, index) => ListTile(
              title: Text(availableTags[index]),
              onTap: () => Navigator.pop(context, availableTags[index]),
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
      ),
    );

    if (selectedNewTag != null) await noteProvider.bulkTag([selectedNewTag]);
  }

  Future<void> _editTag(String tag) async {
    final controller = TextEditingController(text: tag);
    int selectedColor = context.read<NoteProvider>().tagColors[tag] ?? 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Edit Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: const InputDecoration(labelText: 'Tag Name'), autofocus: true),
              const SizedBox(height: 16),
              const Text('Tag Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
                children: AppTheme.noteColors.map((c) {
                  final bool isSystem = c.toARGB32() == 0;
                  final bool isSelected = !isSystem && selectedColor == c.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      if (isSystem) {
                        final nonZeroColors = AppTheme.noteColors.where((color) => color.toARGB32() != 0).toList();
                        final randomColor = (nonZeroColors..shuffle()).first;
                        setDialogState(() => selectedColor = randomColor.toARGB32());
                      } else {
                        setDialogState(() => selectedColor = c.toARGB32());
                      }
                    },
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isSystem ? Theme.of(context).colorScheme.surface : c,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant, width: isSelected ? 3 : 1),
                      ),
                      child: isSystem ? const Icon(Icons.shuffle, size: 16) : (isSelected ? Icon(Icons.check, size: 16, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white) : null),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final newName = controller.text.trim();
                final noteProvider = context.read<NoteProvider>();
                if (newName.isNotEmpty) {
                  if (newName != tag) await NoteRepository.instance.renameTag(tag, newName);
                  if (selectedColor != (noteProvider.tagColors[tag] ?? 0)) await NoteRepository.instance.setTagColor(newName, selectedColor);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  await noteProvider.refreshNotes();
                  if (noteProvider.selectedTag == tag) noteProvider.setTag(newName);
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
        content: Text('Are you sure you want to delete "$tag"? This will remove the tag from all notes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await NoteRepository.instance.deleteTag(tag);
      if (!mounted) return;
      final noteProvider = context.read<NoteProvider>();
      if (noteProvider.selectedTag == tag) noteProvider.setTag('All');
      await noteProvider.refreshNotes();
    }
  }

  void _showTagOptions(String tag) {
    if (tag == 'All' || tag == 'Archived' || tag == 'Trash') return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit Tag'), onTap: () { Navigator.pop(context); _editTag(tag); }),
            ListTile(leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error), title: Text('Delete Tag', style: TextStyle(color: Theme.of(context).colorScheme.error)), onTap: () { Navigator.pop(context); _deleteTag(tag); }),
          ],
        ),
      ),
    );
  }

  void _scrollListener() {
    if (_scrollController.hasClients && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      context.read<NoteProvider>().loadMoreNotes();
    }
  }

  void _showOnboardingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const OnboardingSheet(),
    );
  }

  /// Shows the What's New sheet once per version after an update, and kicks
  /// off the (silent) Play in-app-update and rating-milestone checks.
  Future<void> _maybeShowWhatsNew(SettingsProvider settings) async {
    unawaited(UpdateRatingService.checkForUpdates());
    unawaited(UpdateRatingService.incrementMilestoneAndCheckRating());

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;
    if (settings.lastSeenVersion == currentVersion) return;

    if (_onboardingChecked) {
      // Fresh install: onboarding is showing this session — everything is
      // new to them anyway, so just record the version silently.
      await settings.setLastSeenVersion(currentVersion);
      return;
    }

    if (!mounted) return;
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => WhatsNewSheet(currentVersion: currentVersion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      if (settings.isInitialized && !settings.hasSeenOnboarding && !_onboardingChecked) {
        _onboardingChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOnboardingSheet();
        });
      }

      if (settings.isInitialized && !_whatsNewChecked) {
        _whatsNewChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _maybeShowWhatsNew(settings);
        });
      }

      final bool hasExtraFeatures = settings.showFinancialManager || settings.isPeriodTrackerEnabled;
      
      if (!hasExtraFeatures) return _buildNotesScaffold(context, settings);

      final List<Widget> destinations = _buildDestinations(settings);
      _currentIndex = _currentIndex.clamp(0, destinations.length - 1);

      final bool isTablet = MediaQuery.sizeOf(context).width >= 600;

      if (isTablet) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = index);
                },
                labelType: NavigationRailLabelType.all,
                destinations: _buildNavRailDestinations(settings),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _buildFeatureScreens(settings),
                ),
              ),
            ],
          ),
        );
      }

      return Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _buildFeatureScreens(settings),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          destinations: _buildNavDestinations(settings),
        ),
      );
    });
  }

  List<NavigationRailDestination> _buildNavRailDestinations(SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    return [
      NavigationRailDestination(
        icon: const Icon(Icons.note_alt_outlined),
        selectedIcon: const Icon(Icons.note_alt),
        label: Text(l10n.navNotes),
      ),
      if (settings.showFinancialManager)
        NavigationRailDestination(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: const Icon(Icons.account_balance_wallet),
          label: Text(l10n.navFinances),
        ),
      if (settings.isPeriodTrackerEnabled)
        NavigationRailDestination(
          icon: const Icon(Icons.water_drop_outlined),
          selectedIcon: const Icon(Icons.water_drop),
          label: Text(l10n.navTracker),
        ),
    ];
  }

  List<Widget> _buildNavDestinations(SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    return [
      NavigationDestination(icon: const Icon(Icons.note_alt_outlined), selectedIcon: const Icon(Icons.note_alt), label: l10n.navNotes),
      if (settings.showFinancialManager) NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet), label: l10n.navFinances),
      if (settings.isPeriodTrackerEnabled) NavigationDestination(icon: const Icon(Icons.water_drop_outlined), selectedIcon: const Icon(Icons.water_drop), label: l10n.navTracker),
    ];
  }

  List<Widget> _buildDestinations(SettingsProvider settings) {
    final List<Widget> list = [const SizedBox()]; // Placeholder for Notes
    if (settings.showFinancialManager) list.add(const FinancialManagerScreen());
    if (settings.isPeriodTrackerEnabled) list.add(const PeriodTrackerScreen());
    return list;
  }

  List<Widget> _buildFeatureScreens(SettingsProvider settings) {
    return [
      _buildNotesScaffold(context, settings),
      if (settings.showFinancialManager) const FinancialManagerScreen(),
      if (settings.isPeriodTrackerEnabled) const PeriodTrackerScreen(),
    ];
  }

  Widget _buildNotesScaffold(BuildContext context, SettingsProvider settings) {
    final noteProvider = context.watch<NoteProvider>();
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          HomeAppBar(
            onClearSelection: () => noteProvider.clearSelection(),
            onBulkArchive: () => noteProvider.bulkArchive(),
            onBulkDelete: () => _bulkDeleteWithUndo(noteProvider),
            onBulkTag: bulkTag,
            onCycleViewMode: () => _cycleViewMode(settings),
            onRefresh: refreshNotes,
          ),
          SliverToBoxAdapter(child: TagFilterBar(onTagLongPress: _showTagOptions)),
          NoteViewBuilder(
            onRefresh: refreshNotes,
            onNoteTap: onNoteTap,
            onNoteLongPress: onNoteLongPress,
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  void _showNewNoteOptions(BuildContext context, VoidCallback openBlankNote) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'New Note',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(sheetContext).colorScheme.primaryContainer,
                child: Icon(Icons.note_alt_outlined,
                    color: Theme.of(sheetContext).colorScheme.onPrimaryContainer),
              ),
              title: const Text('Blank Note'),
              subtitle: const Text('Start writing in a new blank note'),
              onTap: () {
                Navigator.pop(sheetContext);
                openBlankNote();
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(sheetContext).colorScheme.secondaryContainer,
                child: Icon(Icons.style_outlined,
                    color: Theme.of(sheetContext).colorScheme.onSecondaryContainer),
              ),
              title: const Text('Use a Template'),
              subtitle: const Text('Create a note from a pre-defined layout'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showTemplateSheet();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    return OpenContainer<bool>(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 300),
      openBuilder: (context, _) => NoteEditorScreen(initialFolder: noteProvider.selectedFolder),
      closedElevation: 6.0,
      openElevation: 0,
      closedShape: const StadiumBorder(),
      closedColor: Theme.of(context).colorScheme.primary,
      openColor: Theme.of(context).colorScheme.surface,
      onClosed: (returned) async { if (returned == true) await refreshNotes(); },
      closedBuilder: (context, openContainer) => SizedBox(
        height: 56,
        child: FloatingActionButton.extended(
          heroTag: 'home_fab',
          label: const Text('New Note'),
          icon: const Icon(Icons.add),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showNewNoteOptions(context, openContainer);
          },
        ),
      ),
    );
  }

  void _showTemplateSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Start from a template',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ...NoteTemplate.all().map(
              (t) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(sheetContext).colorScheme.primaryContainer,
                  child: Icon(t.icon,
                      color: Theme.of(sheetContext)
                          .colorScheme
                          .onPrimaryContainer),
                ),
                title: Text(t.name),
                subtitle: Text(t.description),
                onTap: () async {
                  unawaited(HapticFeedback.selectionClick());
                  Navigator.pop(sheetContext);
                  final noteProvider = Provider.of<NoteProvider>(context, listen: false);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteEditorScreen(
                        templateTitle: t.title,
                        templateContent: t.contentDeltaJson,
                        initialFolder: noteProvider.selectedFolder,
                      ),
                    ),
                  );
                  await refreshNotes();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// Keep NoteCard and NoteViewMode for now as they are used in many places.
class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Map<String, int>? tagColors;
  final bool isSelected;

  const NoteCard({super.key, required this.note, required this.onTap, this.onLongPress, this.tagColors, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final isSystemDefault = note.color == 0;
    final theme = Theme.of(context);
    Color backgroundColor;
    Color borderColor;

    if (isSystemDefault) {
      backgroundColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.3);
    } else {
      final scheme = ColorScheme.fromSeed(seedColor: Color(note.color), brightness: theme.brightness);
      backgroundColor = scheme.surfaceContainerLow;
      borderColor = scheme.outline.withValues(alpha: 0.2);
    }

    return BouncingWidget(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              onLongPress!();
            }
          : null,
      child: Container(
        padding: AppLayout.paddingAllL,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : backgroundColor,
          borderRadius: BorderRadius.circular(AppLayout.radiusXXL),
          border: Border.all(color: isSelected ? theme.colorScheme.primary : borderColor, width: isSelected ? 2 : 1),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.title.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(note.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      if (note.isPinned) Padding(padding: const EdgeInsets.only(left: AppLayout.spaceS), child: Icon(Icons.push_pin, size: AppLayout.iconS, color: theme.colorScheme.primary)),
                    ],
                  ),
                if (note.isLocked) ...[
                  const SizedBox(height: AppLayout.spaceS),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: AppLayout.iconS, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppLayout.spaceS),
                      Text('Locked note', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ],
                if (!note.isLocked && note.imagePath != null) ...[
                  const SizedBox(height: AppLayout.spaceM),
                  ClipRRect(borderRadius: BorderRadius.circular(AppLayout.radiusL), child: Image.file(File(note.imagePath!), height: 120, width: double.infinity, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (c, e, s) => const SizedBox.shrink())),
                ],
                const SizedBox(height: AppLayout.spaceS),
                if (!note.isLocked && ((note.previewText?.isNotEmpty ?? false) || note.content.isNotEmpty))
                  Flexible(child: Text(note.previewText ?? '...', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 6, overflow: TextOverflow.ellipsis)),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: AppLayout.spaceM),
                  Wrap(
                    spacing: AppLayout.spaceXS, runSpacing: AppLayout.spaceXS,
                    children: [
                      ...note.tags.take(3).map((tag) {
                        final colorVal = tagColors?[tag];
                        Color bg = theme.colorScheme.secondaryContainer.withValues(alpha: 0.5);
                        Color fg = theme.colorScheme.onSecondaryContainer;
                        if (colorVal != null && colorVal != 0) {
                          final scheme = ColorScheme.fromSeed(seedColor: Color(colorVal), brightness: theme.brightness);
                          bg = scheme.primaryContainer;
                          fg = scheme.onPrimaryContainer;
                        }
                        return Container(padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceS, vertical: AppLayout.spaceXS), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppLayout.radiusM)), child: Text(tag, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600)));
                      }),
                      if (note.tags.length > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceS, vertical: AppLayout.spaceXS),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppLayout.radiusM),
                          ),
                          child: Text(
                            '+${note.tags.length - 3}',
                            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
            if (isSelected) Positioned(top: 0, right: 0, child: Icon(Icons.check_circle, color: theme.colorScheme.primary, size: AppLayout.icon20)),
          ],
        ),
      ),
    );
  }
}
