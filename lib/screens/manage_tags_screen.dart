import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/repositories/note_repository.dart';
import '../theme/app_theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../theme/app_layout.dart';

class ManageTagsScreen extends StatefulWidget {
  const ManageTagsScreen({super.key});

  @override
  State<ManageTagsScreen> createState() => _ManageTagsScreenState();
}

class _ManageTagsScreenState extends State<ManageTagsScreen> {
  List<String> _tags = [];
  Map<String, int> _tagColors = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    final tags = await NoteRepository.instance.getAllTags();
    final col = await NoteRepository.instance.getAllTagColors();
    setState(() {
      _tags = tags;
      _tagColors = col;
      _isLoading = false;
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
                  final bool isSelected = !isSystem && selectedColor == c.toARGB32();
                  return GestureDetector(
                    onTap: () async {
                      await HapticFeedback.selectionClick();
                      if (isSystem) {
                        final nonZeroColors = AppTheme.noteColors.where((color) => color.toARGB32() != 0).toList();
                        final randomColor = (nonZeroColors..shuffle()).first;
                        setState(() => selectedColor = randomColor.toARGB32());
                      } else {
                        setState(() => selectedColor = c.toARGB32());
                      }
                    },
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
                          ? const Icon(Icons.shuffle, size: 16)
                          : (isSelected
                              ? Icon(Icons.check,
                                  size: 16,
                                  color: c.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white)
                              : null),
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
                    await NoteRepository.instance.renameTag(tag, newName);
                  }
                  if (selectedColor != (_tagColors[tag] ?? 0)) {
                    await NoteRepository.instance
                        .setTagColor(newName, selectedColor);
                  }
                  await HapticFeedback.mediumImpact();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  await _loadTags();
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
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HapticFeedback.mediumImpact();
      await NoteRepository.instance.deleteTag(tag);
      await _loadTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: AnimationLimiter(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              floating: true,
              snap: true,
              toolbarHeight: 84,
              titleSpacing: 16,
              automaticallyImplyLeading: false,
              title: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                  boxShadow: AppLayout.softShadow(context),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () async {
                        await HapticFeedback.lightImpact();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Manage Tags',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tags.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No tags found',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tag = _tags[index];
                      final tagColorValue = _tagColors[tag];
                      final tagColor =
                          tagColorValue != null && tagColorValue != 0
                              ? Color(tagColorValue)
                              : null;

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Semantics(
                              label: 'Tag: $tag',
                              child: Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                color: colorScheme.surfaceContainerLow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppLayout.radiusL),
                                  side: BorderSide(
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                    width: 1.0,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: tagColor ?? colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  title: Text(tag),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Edit',
                                        onPressed: () async {
                                          await HapticFeedback.lightImpact();
                                          await _editTag(tag);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Delete',
                                        onPressed: () async {
                                          await HapticFeedback.lightImpact();
                                          await _deleteTag(tag);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _tags.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
