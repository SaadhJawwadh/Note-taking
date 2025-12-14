import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../data/database_helper.dart';
import '../data/note_model.dart';
import '../theme/app_theme.dart';
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
  bool _isPreview = false;

  final List<String> categories = [
    'All Notes',
    'Journal',
    'Work',
    'Personal',
    'Ideas'
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
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: categories.where((c) => c != 'All Notes').map((c) {
                  return ChoiceChip(
                    label: Text(c),
                    selected: category == c,
                    onSelected: (selected) {
                      setState(() => category = c);
                      Navigator.pop(context);
                    },
                    backgroundColor: const Color(0xFF2C2C30),
                    selectedColor: AppTheme.primaryPurple,
                    labelStyle: TextStyle(
                      color: category == c ? Colors.white : Colors.grey,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
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
        backgroundColor: AppTheme.darkBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await saveNote();
              if (mounted) Navigator.of(context).pop();
            },
          ),
          title: Text(
            _isPreview ? 'Preview' : 'Edit',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          actions: [
            IconButton(
              icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
              onPressed: () => setState(() => _isPreview = !_isPreview),
              tooltip: _isPreview ? 'Edit' : 'Preview',
            ),
            IconButton(
              icon: const Icon(Icons.category_outlined),
              onPressed: _showCategoryPicker,
            ),
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _pickImage,
            ),
            IconButton(
              icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              color: isPinned ? AppTheme.primaryPurple : null,
              onPressed: () => setState(() => isPinned = !isPinned),
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              color: isArchived ? AppTheme.primaryPurple : null,
              onPressed: () => setState(() => isArchived = !isArchived),
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                await saveNote();
                if (mounted) Navigator.of(context).pop();
              },
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
                          MarkdownBody(
                            data: _contentController.text,
                            styleSheet: MarkdownStyleSheet(
                              p: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontSize: settings.textSize),
                              h1: Theme.of(context).textTheme.headlineSmall,
                              h2: Theme.of(context).textTheme.titleMedium,
                              // Add more styles to match AppTheme
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
                          if (category != 'All Notes') ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Chip(
                                label: Text(category),
                                backgroundColor:
                                    AppTheme.primaryPurple.withOpacity(0.2),
                                labelStyle: const TextStyle(
                                    color: AppTheme.primaryPurple,
                                    fontSize: 12),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
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
            if (!_isPreview) _buildMarkdownToolbar(),
          ],
        ),
      );
    });
  }

  Widget _buildMarkdownToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _toolbarButton(
                  Icons.format_bold, () => _insertMarkdown('**', '**')),
              _toolbarButton(
                  Icons.format_italic, () => _insertMarkdown('_', '_')),
              _toolbarButton(Icons.title, () => _insertMarkdown('# ', '')),
              _toolbarButton(
                  Icons.format_list_bulleted, () => _insertMarkdown('* ', '')),
              _toolbarButton(Icons.check_box_outlined,
                  () => _insertMarkdown('- [ ] ', '')),
              _toolbarButton(
                  Icons.code, () => _insertMarkdown('```\n', '\n```')),
              _toolbarButton(
                  Icons.format_quote, () => _insertMarkdown('> ', '')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
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
