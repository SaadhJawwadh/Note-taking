import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:async';
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
  bool _isPreview = true; // Default to preview
  List<String> _allTags = [];
  Timer? _debounce;
  final UndoHistoryController _undoController = UndoHistoryController();

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
    _loadTags();

    // Auto-save listeners
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  Future<void> _loadTags() async {
    final t = await DatabaseHelper.instance.getAllTags();
    if (mounted) setState(() => _allTags = t);
  }

  void _onContentChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      saveNote();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _undoController.dispose();
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
                  return Semantics(
                    button: true,
                    label: 'Color option ${noteColors.indexOf(c) + 1}',
                    selected: color == c,
                    child: GestureDetector(
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
                              : Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: color == c
                            ? Icon(Icons.check,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                      ),
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

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        String newTag = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Manage Tags',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Create new tag',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (newTag.isNotEmpty) {
                            setState(() {
                              if (!tags.contains(newTag)) tags.add(newTag);
                              if (!_allTags.contains(newTag)) {
                                _allTags.add(newTag);
                              }
                            });
                            setModalState(() => newTag = '');
                            Navigator.pop(
                                context); // Close for now, or keep open?
                            _showTagPicker(); // Reopen to refresh or just keep state?
                            // Simpler: Just refresh local state
                          }
                        },
                      ),
                    ),
                    onChanged: (v) => newTag = v.trim(),
                    onSubmitted: (v) {
                      if (v.isNotEmpty) {
                        setState(() {
                          final t = v.trim();
                          if (!tags.contains(t)) tags.add(t);
                          if (!_allTags.contains(t)) _allTags.add(t);
                        });
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_allTags.isNotEmpty) ...[
                    const Text('Select Tags'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _allTags.map((t) {
                        final isSelected = tags.contains(t);
                        return FilterChip(
                          label: Text(t),
                          selected: isSelected,
                          onSelected: (sel) {
                            setState(() {
                              if (sel) {
                                tags.add(t);
                              } else {
                                tags.remove(t);
                              }
                            });
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ]
                ],
              ),
            );
          },
        );
      },
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
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () {
              saveNote();
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                  _isPreview ? Icons.edit_outlined : Icons.visibility_outlined),
              tooltip: _isPreview ? 'Edit' : 'Preview',
              onPressed: () => setState(() => _isPreview = !_isPreview),
            ),
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: 'Change color',
              onPressed: _showColorPicker,
            ),
            IconButton(
              icon: const Icon(Icons.image_outlined),
              tooltip: 'Add image',
              onPressed: _pickImage,
            ),
            IconButton(
              icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              tooltip: isPinned ? 'Unpin' : 'Pin',
              onPressed: () {
                setState(() => isPinned = !isPinned);
                saveNote();
              },
            ),
            IconButton(
              icon: const Icon(Icons.label_outlined), // Tag icon
              tooltip: 'Manage Tags',
              onPressed: _showTagPicker,
            ),
            IconButton(
              icon: Icon(isArchived ? Icons.archive : Icons.archive_outlined),
              tooltip: isArchived ? 'Unarchive' : 'Archive',
              onPressed: () {
                setState(() => isArchived = !isArchived);
                saveNote();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _isPreview
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imagePath != null) ...[
                            Semantics(
                              label: 'Attached image',
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      File(imagePath!),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          Text(
                            _titleController.text.isEmpty
                                ? 'Untitled'
                                : _titleController.text,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 8),
                          if (tags.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              children: tags
                                  .map((tag) => Chip(
                                        label: Text(tag),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHigh,
                                        labelStyle:
                                            const TextStyle(fontSize: 12),
                                      ))
                                  .toList(),
                            ),
                          const SizedBox(height: 16),
                          MarkdownBody(
                            data: _contentController.text,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                              h1: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              h2: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              blockquote: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                              code: TextStyle(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView(
                        children: [
                          // Tags Row
                          // SingleChildScrollView( // Removed SingleChildScrollView here
                          // scrollDirection: Axis.horizontal,
                          // child:
                          Row(
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
                                onPressed: _showTagPicker,
                              ),
                            ],
                          ),
                          // ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _titleController,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: 'Title',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLines:
                                null, // Keep maxLines null for multiline title
                          ),
                          const SizedBox(height: 10),
                          if (imagePath != null) ...[
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    File(imagePath!),
                                    height:
                                        250, // Keep original height for consistency in edit mode
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    semanticLabel:
                                        'Attached note image', // Keep original semanticLabel
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      foregroundColor: Colors.white,
                                    ),
                                    tooltip: 'Remove image',
                                    onPressed: () {
                                      setState(() => imagePath = null);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                          TextField(
                            controller: _contentController,
                            undoController:
                                _undoController, // Keep undoController here
                            maxLines: null,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    fontSize: settings
                                        .textSize), // Keep textSize from settings
                            decoration: const InputDecoration(
                              hintText: 'Start typing...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(
                              height:
                                  300), // Keep original padding for consistency
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
              ValueListenableBuilder<UndoHistoryValue>(
                valueListenable: _undoController,
                builder: (context, value, child) {
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.undo),
                        onPressed: value.canUndo ? _undoController.undo : null,
                        color: value.canUndo
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      IconButton(
                        icon: const Icon(Icons.redo),
                        onPressed: value.canRedo ? _undoController.redo : null,
                        color: value.canRedo
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.withValues(alpha: 0.3),
                          margin: const EdgeInsets.symmetric(horizontal: 8)),
                    ],
                  );
                },
              ),
              _toolbarButton(context, Icons.format_bold, 'Bold',
                  () => _insertMarkdown('**', '**')),
              _toolbarButton(context, Icons.format_italic, 'Italic',
                  () => _insertMarkdown('_', '_')),
              _toolbarButton(context, Icons.title, 'Heading',
                  () => _insertMarkdown('# ', '')),
              _toolbarButton(context, Icons.format_strikethrough,
                  'Strikethrough', () => _insertMarkdown('~~', '~~')),
              _toolbarButton(context, Icons.format_list_bulleted, 'Bullet List',
                  () => _insertMarkdown('* ', '')),
              _toolbarButton(context, Icons.check_box_outlined, 'Checkbox',
                  () => _insertMarkdown('- [ ] ', '')),
              _toolbarButton(
                  context, Icons.code, 'Code', () => _insertMarkdown('`', '`')),
              _toolbarButton(context, Icons.data_array, 'Code Block',
                  () => _insertMarkdown('```\n', '\n```')),
              _toolbarButton(context, Icons.format_quote, 'Quote',
                  () => _insertMarkdown('> ', '')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton(BuildContext context, IconData icon, String tooltip,
      VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onPressed: onPressed,
      tooltip: tooltip,
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
