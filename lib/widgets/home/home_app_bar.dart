import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/settings_provider.dart';
import '../../providers/note_provider.dart';
import '../../screens/settings_screen.dart';
import '../../screens/search_delegate.dart';
import '../../theme/app_layout.dart';
import '../../utils/app_route.dart';
import '../../l10n/app_localizations.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onClearSelection;
  final VoidCallback onBulkArchive;
  final VoidCallback onBulkDelete;
  final VoidCallback onBulkTag;
  final VoidCallback onCycleViewMode;
  final VoidCallback onRefresh;

  const HomeAppBar({
    super.key,
    required this.onClearSelection,
    required this.onBulkArchive,
    required this.onBulkDelete,
    required this.onBulkTag,
    required this.onCycleViewMode,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final noteProvider = context.watch<NoteProvider>();
    final settings = context.watch<SettingsProvider>();

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      snap: true,
      toolbarHeight: 84,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      title: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 64,
        decoration: BoxDecoration(
          color: noteProvider.isSelectionMode
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
          boxShadow: AppLayout.softShadow(context),
        ),
        child: noteProvider.isSelectionMode
            ? _buildSelectionMode(context, noteProvider)
            : _buildNormalMode(context, settings),
      ),
    );
  }

  Widget _buildSelectionMode(BuildContext context, NoteProvider noteProvider) {
    return Row(
      children: [
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            HapticFeedback.selectionClick();
            onClearSelection();
          },
        ),
        const SizedBox(width: 8),
        Text(
          '${noteProvider.selectedNoteIds.length} selected',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.push_pin_outlined),
          tooltip: 'Pin / unpin selected',
          onPressed: () {
            HapticFeedback.lightImpact();
            context.read<NoteProvider>().bulkTogglePin();
          },
        ),
        IconButton(
          icon: const Icon(Icons.archive_outlined),
          tooltip: 'Archive selected',
          onPressed: () {
            HapticFeedback.lightImpact();
            onBulkArchive();
          },
        ),
        IconButton(
          icon: const Icon(Icons.label_outline),
          tooltip: 'Tag selected',
          onPressed: () {
            HapticFeedback.selectionClick();
            onBulkTag();
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete selected',
          color: Theme.of(context).colorScheme.error,
          onPressed: () {
            HapticFeedback.mediumImpact();
            onBulkDelete();
          },
        ),
      ],
    );
  }

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return l10n.greetingMorning;
    } else if (hour >= 12 && hour < 17) {
      return l10n.greetingAfternoon;
    } else if (hour >= 17 && hour < 21) {
      return l10n.greetingEvening;
    } else {
      return l10n.greetingNight;
    }
  }

  Widget _buildNormalMode(BuildContext context, SettingsProvider settings) {
    final noteProvider = context.watch<NoteProvider>();
    return Row(
      children: [
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getGreeting(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              AppLocalizations.of(context)!.noteCount(
                  noteProvider.tagCounts['All'] ??
                      noteProvider.filteredNotes.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
        const Spacer(),
        if (noteProvider.folders.isNotEmpty)
          PopupMenuButton<String>(
            icon: Icon(
              noteProvider.selectedFolder != null
                  ? Icons.folder
                  : Icons.folder_outlined,
              color: noteProvider.selectedFolder != null
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: 'Filter by folder',
            onSelected: (value) {
              HapticFeedback.selectionClick();
              noteProvider.setFolder(value == '__all__' ? null : value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: '__all__', child: Text('All folders')),
              ...noteProvider.folders.map(
                (f) => PopupMenuItem(value: f, child: Text(f)),
              ),
            ],
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort notes',
          initialValue: noteProvider.sortMode,
          onSelected: (mode) {
            HapticFeedback.selectionClick();
            noteProvider.setSortMode(mode);
          },
          itemBuilder: (context) => const [
            CheckedPopupMenuItem(value: 'modified', child: Text('Last modified')),
            CheckedPopupMenuItem(value: 'created', child: Text('Date created')),
            CheckedPopupMenuItem(value: 'title', child: Text('Title')),
            CheckedPopupMenuItem(value: 'color', child: Text('Color')),
          ],
        ),
        IconButton(
          icon: Icon(_getIconForMode(settings.noteViewMode)),
          tooltip: _getTooltipForMode(settings.noteViewMode),
          onPressed: () {
            HapticFeedback.selectionClick();
            onCycleViewMode();
          },
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Global search',
          onPressed: () {
            HapticFeedback.selectionClick();
            showSearch(context: context, delegate: GlobalSearchDelegate());
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              HapticFeedback.selectionClick();
              AppRoute.push(context, const SettingsScreen())
                  .then((_) => onRefresh());
            },
          ),
        )
      ],
    );
  }

  IconData _getIconForMode(NoteViewMode mode) {
    switch (mode) {
      case NoteViewMode.list:
        return Icons.grid_view_outlined;
      case NoteViewMode.grid:
        return Icons.view_agenda_outlined;
    }
  }

  String _getTooltipForMode(NoteViewMode mode) {
    switch (mode) {
      case NoteViewMode.list:
        return 'Switch to grid view';
      case NoteViewMode.grid:
        return 'Switch to list view';
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(84);
}
