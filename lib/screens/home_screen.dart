import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';

import '../data/note_model.dart';
import '../data/settings_provider.dart';
import '../providers/note_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_layout.dart';
import '../widgets/tag_filter_bar.dart';
import '../widgets/home/home_app_bar.dart';
import '../widgets/home/note_view_builder.dart';
import 'note_editor_screen.dart';
import 'file_converter_screen.dart';
import 'financial_manager_screen.dart';
import 'period_tracker_screen.dart';
import 'app_lock_screen.dart';
import 'transaction_editor_screen.dart';
import '../data/repositories/note_repository.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/onboarding_sheet.dart';
import '../utils/widget_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  late StreamSubscription _intentDataStreamSubscription;
  bool _onboardingChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    
    // Update home screen widget on startup to ensure intents are fresh
    unawaited(WidgetHelper.updateWidgetData());
    
    AppLockScreen.sessionAuthenticated.addListener(_handleSessionUnlock);

    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && mounted) {
        _handleSharedPaths(value.map((f) => f.path).toList());
      }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && mounted) {
        _handleSharedPaths(value.map((f) => f.path).toList());
      }
      ReceiveSharingIntent.instance.reset();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndProcessPendingIntents();
      }
    });
  }

  void _handleSharedPaths(List<String> paths) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool isLocked = settings.appLockEnabled && !AppLockScreen.sessionAuthenticated.value;
    if (isLocked) {
      AppLockScreen.pendingSharedPaths = paths;
    } else {
      _navigateToConverter(paths);
    }
  }

  void _handleSessionUnlock() {
    if (AppLockScreen.sessionAuthenticated.value && mounted) {
      _checkAndProcessPendingIntents();
    }
  }

  Future<void> _checkAndProcessPendingIntents() async {
    if (AppLockScreen.pendingSharedPaths != null && AppLockScreen.pendingSharedPaths!.isNotEmpty) {
      final paths = AppLockScreen.pendingSharedPaths!;
      AppLockScreen.pendingSharedPaths = null;
      unawaited(_navigateToConverter(paths));
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

  static const MethodChannel _lockChannel = MethodChannel('com.saadhjawwadh.notebook/device_lock');

  Future<void> _navigateToConverter(List<String> paths) async {
    final resolvedPaths = <String>[];
    for (final path in paths) {
      if (path.startsWith('content://')) {
        try {
          final String? localPath = await _lockChannel.invokeMethod('copyContentUriToTempFile', {'uri': path});
          if (localPath != null) {
            resolvedPaths.add(localPath);
          } else {
            resolvedPaths.add(path);
          }
        } catch (e) {
          debugPrint('Error copying content URI: $e');
          resolvedPaths.add(path);
        }
      } else {
        resolvedPaths.add(path);
      }
    }

    if (!mounted) return;
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FileConverterScreen(initialFilePaths: resolvedPaths)),
      ),
    );
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _scrollController.dispose();
    AppLockScreen.sessionAuthenticated.removeListener(_handleSessionUnlock);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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
            ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: const Text('Delete Tag', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); _deleteTag(tag); }),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      if (settings.isInitialized && !settings.hasSeenOnboarding && !_onboardingChecked) {
        _onboardingChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOnboardingSheet();
        });
      }
      
      final bool hasExtraFeatures = settings.showFinancialManager || settings.isPeriodTrackerEnabled || settings.showFileConverter;
      
      if (!hasExtraFeatures) return _buildNotesScaffold(context, settings);

      final List<Widget> destinations = _buildDestinations(settings);
      _currentIndex = _currentIndex.clamp(0, destinations.length - 1);

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

  List<Widget> _buildNavDestinations(SettingsProvider settings) {
    return [
      const NavigationDestination(icon: Icon(Icons.note_alt_outlined), selectedIcon: Icon(Icons.note_alt), label: 'Notes'),
      if (settings.showFileConverter) const NavigationDestination(icon: Icon(Icons.transform_rounded), selectedIcon: Icon(Icons.transform_rounded), label: 'Converter'),
      if (settings.showFinancialManager) const NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Finances'),
      if (settings.isPeriodTrackerEnabled) const NavigationDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop), label: 'Tracker'),
    ];
  }

  List<Widget> _buildDestinations(SettingsProvider settings) {
    final List<Widget> list = [const SizedBox()]; // Placeholder for Notes
    if (settings.showFileConverter) list.add(const FileConverterScreen());
    if (settings.showFinancialManager) list.add(const FinancialManagerScreen());
    if (settings.isPeriodTrackerEnabled) list.add(const PeriodTrackerScreen());
    return list;
  }

  List<Widget> _buildFeatureScreens(SettingsProvider settings) {
    return [
      _buildNotesScaffold(context, settings),
      if (settings.showFileConverter) const FileConverterScreen(),
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
            onBulkDelete: () => noteProvider.bulkDelete(),
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

  Widget _buildFAB(BuildContext context) {
    return OpenContainer<bool>(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 300),
      openBuilder: (context, _) => const NoteEditorScreen(),
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
          tooltip: 'Create new note',
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
          onPressed: () {
            HapticFeedback.lightImpact();
            openContainer();
          },
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
                if (note.imagePath != null) ...[
                  const SizedBox(height: AppLayout.spaceM),
                  ClipRRect(borderRadius: BorderRadius.circular(AppLayout.radiusL), child: Image.file(File(note.imagePath!), height: 120, width: double.infinity, fit: BoxFit.cover, alignment: Alignment.topCenter, errorBuilder: (c, e, s) => const SizedBox.shrink())),
                ],
                const SizedBox(height: AppLayout.spaceS),
                if ((note.previewText?.isNotEmpty ?? false) || note.content.isNotEmpty)
                  Flexible(child: Text(note.previewText ?? '...', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), maxLines: 6, overflow: TextOverflow.ellipsis)),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: AppLayout.spaceM),
                  Wrap(
                    spacing: AppLayout.spaceXS, runSpacing: AppLayout.spaceXS,
                    children: note.tags.take(3).map((tag) {
                      final colorVal = tagColors?[tag];
                      Color bg = theme.colorScheme.secondaryContainer.withValues(alpha: 0.5);
                      Color fg = theme.colorScheme.onSecondaryContainer;
                      if (colorVal != null && colorVal != 0) {
                        final scheme = ColorScheme.fromSeed(seedColor: Color(colorVal), brightness: theme.brightness);
                        bg = scheme.primaryContainer;
                        fg = scheme.onPrimaryContainer;
                      }
                      return Container(padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceS, vertical: AppLayout.spaceXS), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppLayout.radiusM)), child: Text(tag, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600)));
                    }).toList(),
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
