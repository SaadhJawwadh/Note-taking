import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../theme/app_theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
    final tags = await DatabaseHelper.instance.getAllTags();
    final col = await DatabaseHelper.instance.getAllTagColors();
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
                  final bool isSelected = selectedColor == c.toARGB32();
                  return GestureDetector(
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteTag(tag);
      await _loadTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tags'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? Center(
                  child: Text(
                    'No tags found',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : AnimationLimiter(
                  child: ListView.separated(
                    itemCount: _tags.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
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
                              child: ListTile(
                                leading: Icon(Icons.label,
                                    color: tagColor ??
                                        Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                title: Text(tag),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Semantics(
                                      label: 'Edit tag $tag',
                                      button: true,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Edit',
                                        onPressed: () => _editTag(tag),
                                      ),
                                    ),
                                    Semantics(
                                      label: 'Delete tag $tag',
                                      button: true,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Delete',
                                        onPressed: () => _deleteTag(tag),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
