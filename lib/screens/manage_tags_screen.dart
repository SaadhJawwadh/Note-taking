import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class ManageTagsScreen extends StatefulWidget {
  const ManageTagsScreen({super.key});

  @override
  State<ManageTagsScreen> createState() => _ManageTagsScreenState();
}

class _ManageTagsScreenState extends State<ManageTagsScreen> {
  List<String> _tags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    final tags = await DatabaseHelper.instance.getAllTags();
    setState(() {
      _tags = tags;
      _isLoading = false;
    });
  }

  Future<void> _renameTag(String oldTag) async {
    final controller = TextEditingController(text: oldTag);
    final newTag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Tag Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newTag != null && newTag.isNotEmpty && newTag != oldTag) {
      await DatabaseHelper.instance.renameTag(oldTag, newTag);
      _loadTags();
    }
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
      _loadTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
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
              : ListView.separated(
                  itemCount: _tags.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tag = _tags[index];
                    return ListTile(
                      leading: const Icon(Icons.label_outlined),
                      title: Text(tag),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Rename',
                            onPressed: () => _renameTag(tag),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete',
                            onPressed: () => _deleteTag(tag),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
