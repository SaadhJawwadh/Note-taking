import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/settings_provider.dart';
import '../../providers/note_provider.dart';
import '../../screens/settings_screen.dart';
import '../../screens/search_delegate.dart';

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
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
          onPressed: onClearSelection,
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
          icon: const Icon(Icons.archive_outlined),
          tooltip: 'Archive selected',
          onPressed: onBulkArchive,
        ),
        IconButton(
          icon: const Icon(Icons.label_outline),
          tooltip: 'Tag selected',
          onPressed: onBulkTag,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete selected',
          color: Colors.red,
          onPressed: onBulkDelete,
        ),
      ],
    );
  }

  Widget _buildNormalMode(BuildContext context, SettingsProvider settings) {
    return Row(
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
          onPressed: onCycleViewMode,
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Global search',
          onPressed: () {
            showSearch(context: context, delegate: GlobalSearchDelegate());
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
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  )
                  .then((_) => onRefresh());
            },
          ),
        )
      ],
    );
  }

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

  @override
  Size get preferredSize => const Size.fromHeight(84);
}
