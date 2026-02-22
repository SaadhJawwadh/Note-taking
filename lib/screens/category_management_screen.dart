// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../data/category_definition.dart';
import '../data/database_helper.dart';
import '../data/transaction_category.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<CategoryDefinition> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getAllCategoryDefinitions();
    if (mounted) {
      setState(() {
        _categories = cats;
        _loading = false;
      });
    }
  }

  Future<void> _saveAndReload() async {
    await TransactionCategory.reload();
    await _loadCategories();
  }

  Future<void> _showEditDialog(CategoryDefinition def) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EditKeywordsDialog(
        definition: def,
        onSave: (updated) async {
          await DatabaseHelper.instance.upsertCategoryDefinition(updated);
          await _saveAndReload();
        },
      ),
    );
  }

  Future<void> _showAddDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AddCategoryDialog(
        onSave: (newDef) async {
          await DatabaseHelper.instance.upsertCategoryDefinition(newDef);
          await _saveAndReload();
        },
      ),
    );
  }

  Future<void> _deleteCategory(CategoryDefinition def) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Delete "${def.name}"? Existing transactions with this category will keep their label but will no longer match new transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await DatabaseHelper.instance.deleteCategoryDefinition(def.name);
      await _saveAndReload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            snap: true,
            toolbarHeight: 84,
            automaticallyImplyLeading: false,
            title: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Manage Categories',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = _categories[index];
                    final catColor = Color(cat.colorValue);
                    final isLast = index == _categories.length - 1;
                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.only(bottom: isLast ? 80 : 12),
                      color: colorScheme.surfaceContainerHigh,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: catColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!cat.isBuiltIn)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    iconSize: 20,
                                    color: colorScheme.error,
                                    tooltip: 'Delete category',
                                    onPressed: () => _deleteCategory(cat),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  iconSize: 20,
                                  color: colorScheme.onSurfaceVariant,
                                  tooltip: 'Edit keywords',
                                  onPressed: () => _showEditDialog(cat),
                                ),
                              ],
                            ),
                            if (cat.keywords.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: cat.keywords.map((kw) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              catColor.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: catColor
                                                .withValues(alpha: 0.3),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          kw,
                                          style: textTheme.labelSmall
                                              ?.copyWith(color: catColor),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ] else
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'No keywords',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _categories.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }
}

// ── Edit Keywords Dialog ─────────────────────────────────────────────────────

class _EditKeywordsDialog extends StatefulWidget {
  final CategoryDefinition definition;
  final Future<void> Function(CategoryDefinition) onSave;

  const _EditKeywordsDialog({
    required this.definition,
    required this.onSave,
  });

  @override
  State<_EditKeywordsDialog> createState() => _EditKeywordsDialogState();
}

class _EditKeywordsDialogState extends State<_EditKeywordsDialog> {
  late List<String> _keywords;
  final _addController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _keywords = List.from(widget.definition.keywords);
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final kw = _addController.text.trim().toLowerCase();
    if (kw.isEmpty || _keywords.contains(kw)) return;
    setState(() => _keywords.add(kw));
    _addController.clear();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(widget.definition.copyWith(keywords: _keywords));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final catColor = Color(widget.definition.colorValue);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: catColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('${widget.definition.name} Keywords'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    decoration: InputDecoration(
                      hintText: 'Add keyword…',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _addKeyword(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: colorScheme.primary,
                  onPressed: _addKeyword,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_keywords.isEmpty)
              Text(
                'No keywords — this category will only be used explicitly.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _keywords.map((kw) {
                  return Chip(
                    label: Text(kw),
                    labelStyle: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: catColor),
                    backgroundColor: catColor.withValues(alpha: 0.1),
                    side: BorderSide(
                        color: catColor.withValues(alpha: 0.3), width: 0.5),
                    deleteIconColor: colorScheme.onSurfaceVariant,
                    onDeleted: () => setState(() => _keywords.remove(kw)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Add Category Dialog ──────────────────────────────────────────────────────

class _AddCategoryDialog extends StatefulWidget {
  final Future<void> Function(CategoryDefinition) onSave;

  const _AddCategoryDialog({required this.onSave});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  static const _colorSwatches = [
    Color(0xFFE53935), // Red
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF607D8B), // Blue Grey
  ];

  final _nameController = TextEditingController();
  final _keywordController = TextEditingController();
  Color _selectedColor = _colorSwatches[5]; // Blue default
  final List<String> _keywords = [];
  bool _saving = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final kw = _keywordController.text.trim().toLowerCase();
    if (kw.isEmpty || _keywords.contains(kw)) return;
    setState(() => _keywords.add(kw));
    _keywordController.clear();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
    });
    final def = CategoryDefinition(
      name: name,
      colorValue: _selectedColor.value,
      keywords: _keywords,
      isBuiltIn: false,
    );
    await widget.onSave(def);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('New Category'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category name',
                errorText: _nameError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            // Color picker
            Text(
              'Colour',
              style: textTheme.labelMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorSwatches.map((color) {
                final selected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: colorScheme.onSurface, width: 2.5)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Keywords
            Text(
              'Keywords',
              style: textTheme.labelMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keywordController,
                    decoration: InputDecoration(
                      hintText: 'Add keyword…',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _addKeyword(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: colorScheme.primary,
                  onPressed: _addKeyword,
                ),
              ],
            ),
            if (_keywords.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _keywords.map((kw) {
                  return Chip(
                    label: Text(kw),
                    labelStyle: textTheme.labelSmall
                        ?.copyWith(color: _selectedColor),
                    backgroundColor:
                        _selectedColor.withValues(alpha: 0.1),
                    side: BorderSide(
                        color: _selectedColor.withValues(alpha: 0.3),
                        width: 0.5),
                    deleteIconColor: colorScheme.onSurfaceVariant,
                    onDeleted: () => setState(() => _keywords.remove(kw)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
