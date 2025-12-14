import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../data/database_helper.dart';
import '../data/note_model.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool isPinned = false;
  bool isArchived = false;
  int color = 0xFF252529;
  String? imagePath;
  String category = 'All Notes';
  List<String> tags = [];
  bool _isPreview = false;

  final List<String> categories = [
    'All Notes',
    'Journal',
    'Work',
    'Personal',
    'Ideas'
  ];

  final List<int> noteColors = [
    0xFF252529, // Default Dark
    0xFF1C1B1F, // M3 Surface
    0xFF332D2D, // Reddish
    0xFF2F3129, // Greenish
    0xFF282F33, // Blueish
    0xFF312833, // Purplish
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    isPinned = widget.note?.isPinned ?? false;
    isArchived = widget.note?.isArchived ?? false;
    color = widget.note?.color ?? 0xFF252529;
    imagePath = widget.note?.imagePath;
    category = widget.note?.category ?? 'All Notes';
    tags = List.from(widget.note?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final localImage =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');

      setState(() {
        imagePath = localImage.path;
      });
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: categories.where((c) => c != 'All Notes').map((c) {
                  return FilterChip(
                    label: Text(c),
                    selected: category == c,
                    onSelected: (selected) {
                      setState(() => category = c);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Note Color',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: noteColors.map((c) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => color = c);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: color == c
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3)
                            : Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: color == c
                          ? Icon(Icons.check,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _addTag() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter tag name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  tags.add(controller.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future saveNote() async {
    final title = _titleController.text;
    final content = _contentController.text;

    if (title.isEmpty && content.isEmpty && imagePath == null) return;

    final note = widget.note?.copyWith(
          title: title,
          content: content,
          isPinned: isPinned,
          isArchived: isArchived,
          color: color,
          imagePath: imagePath,
          category: category,
          tags: tags,
          dateModified: DateTime.now(),
        ) ??
        Note(
          id: const Uuid().v4(),
          title: title,
          content: content,
          dateCreated: DateTime.now(),
          dateModified: DateTime.now(),
          isPinned: isPinned,
          isArchived: isArchived,
          color: color,
          imagePath: imagePath,
          category: category,
          tags: tags,
        );

    if (widget.note != null) {
      await DatabaseHelper.instance.updateNote(note);
    } else {
      await DatabaseHelper.instance.createNote(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      // Use logic to determine background color suitable for brightness
      Color backgroundColor = Color(color);
      // If color is very dark but theme is light, we might want to invert or adjust,
      // but for now we trust the user selection or default.

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Transparent for M3
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await saveNote();
              if (mounted) Navigator.of(context).pop();
            },
          ),
          title: Text(
            category,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          actions: [
            IconButton(
              icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
              onPressed: () => setState(() => _isPreview = !_isPreview),
              tooltip: _isPreview ? 'Edit' : 'Preview',
            ),
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              onPressed: _showColorPicker,
              tooltip: 'Color',
            ),
            IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: _showCategoryPicker,
              tooltip: 'Category',
            ),
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: _pickImage,
              tooltip: 'Image',
            ),
            IconButton(
              icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              color: isPinned ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => setState(() => isPinned = !isPinned),
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              color: isArchived ? Theme.of(context).colorScheme.primary : null,
              onPressed: () => setState(() => isArchived = !isArchived),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _isPreview
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imagePath != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(imagePath!),
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            _titleController.text,
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(fontSize: 34),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: tags
                                .map((tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHigh,
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          MarkdownBody(
                            data: _contentController.text,
                            styleSheet: MarkdownStyleSheet(
                              p: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontSize: settings.textSize),
                              // Styles will inherit from Theme
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView(
                        children: [
                          // Tags Row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...tags.map((tag) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: InputChip(
                                        label: Text(tag),
                                        onDeleted: () {
                                          setState(() {
                                            tags.remove(tag);
                                          });
                                        },
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHigh,
                                      ),
                                    )),
                                ActionChip(
                                  avatar: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Tag'),
                                  onPressed: _addTag,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (imagePath != null) ...[
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    File(imagePath!),
                                    height: 250,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                    right: 8,
                                    top: 8,
                                    child: IconButton.filled(
                                      icon: const Icon(Icons.close),
                                      onPressed: () =>
                                          setState(() => imagePath = null),
                                    )),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextField(
                            controller: _titleController,
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(fontSize: 34),
                            decoration: const InputDecoration(
                              hintText: 'Title',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                            maxLines: null,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _contentController,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontSize: settings.textSize),
                            decoration: const InputDecoration(
                              hintText: 'Start typing...',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                            maxLines: null,
                          ),
                          const SizedBox(height: 300),
                        ],
                      ),
                    ),
            ),
            if (!_isPreview) _buildMarkdownToolbar(context),
          ],
        ),
      );
    });
  }

  Widget _buildMarkdownToolbar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(32), // M3 Rounded Corners
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _toolbarButton(context, Icons.format_bold,
                  () => _insertMarkdown('**', '**')),
              _toolbarButton(context, Icons.format_italic,
                  () => _insertMarkdown('_', '_')),
              _toolbarButton(
                  context, Icons.title, () => _insertMarkdown('# ', '')),
              _toolbarButton(context, Icons.format_strikethrough,
                  () => _insertMarkdown('~~', '~~')),
              _toolbarButton(context, Icons.format_list_bulleted,
                  () => _insertMarkdown('* ', '')),
              _toolbarButton(context, Icons.check_box_outlined,
                  () => _insertMarkdown('- [ ] ', '')),
              _toolbarButton(
                  context, Icons.code, () => _insertMarkdown('`', '`')),
              _toolbarButton(context, Icons.data_array,
                  () => _insertMarkdown('```\n', '\n```')),
              _toolbarButton(
                  context, Icons.format_quote, () => _insertMarkdown('> ', '')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton(
      BuildContext context, IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onPressed: onPressed,
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    // If no selection is active, default to end of text
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final selectedText = text.substring(start, end);
    final newText =
        text.replaceRange(start, end, '$prefix$selectedText$suffix');

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + prefix.length + selectedText.length + suffix.length,
      ),
    );
  }
}
