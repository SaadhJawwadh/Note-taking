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

  void _showCreateFolderDialog(BuildContext context, NoteProvider noteProvider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            prefixIcon: Icon(Icons.create_new_folder_outlined),
          ),
          onSubmitted: (v) {
            final name = v.trim();
            if (name.isNotEmpty) {
              HapticFeedback.selectionClick();
              noteProvider.createFolder(name);
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                HapticFeedback.selectionClick();
                noteProvider.createFolder(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showFolderPicker(BuildContext context, NoteProvider noteProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final folders = ['All folders', ...noteProvider.folders];
        final currentFolder = noteProvider.selectedFolder ?? 'All folders';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter by folder',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                      label: const Text('New Folder'),
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet
                        _showCreateFolderDialog(context, noteProvider);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final isSelected = folder == currentFolder;
                    return ListTile(
                      leading: Icon(
                        index == 0 ? Icons.folder_open_outlined : Icons.folder,
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      ),
                      title: Text(
                        folder,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        noteProvider.setFolder(index == 0 ? null : folder);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNormalMode(BuildContext context, SettingsProvider settings) {
    final noteProvider = context.watch<NoteProvider>();
    return Row(
      children: [
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(AppLayout.radiusM),
          onTap: () {
            HapticFeedback.selectionClick();
            _showFolderPicker(context, noteProvider);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  noteProvider.selectedFolder != null ? Icons.folder : Icons.folder_open_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          noteProvider.selectedFolder ?? 'All folders',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                      ],
                    ),
                    Text(
                      AppLocalizations.of(context)!.noteCount(
                        noteProvider.selectedFolder == null
                            ? (noteProvider.tagCounts['All'] ?? 0)
                            : (noteProvider.folderCounts[noteProvider.selectedFolder] ?? 0),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
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
