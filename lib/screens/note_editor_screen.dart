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
import '../theme/app_theme.dart';
import '../utils/markdown_controller.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late MarkdownFormattingController _contentController;
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
  late String _noteId;
  late DateTime _dateCreated;
  bool _hasUserModifiedColor = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.note == null && !_hasUserModifiedColor) {
      final settings = Provider.of<SettingsProvider>(context);
      if (color != settings.defaultNoteColor) {
        color = settings.defaultNoteColor;
        // No setState needed effectively as build will use new color,
        // but technically we should ensure it triggers update if called outside build cycle.
        // However, didChangeDependencies is part of build cycle setup.
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _noteId = widget.note?.id ?? const Uuid().v4();
    _dateCreated = widget.note?.dateCreated ?? DateTime.now();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        MarkdownFormattingController(text: widget.note?.content ?? '');
    isPinned = widget.note?.isPinned ?? false;
    isArchived = widget.note?.isArchived ?? false;
    color = widget.note?.color ??
        0xFF252529; // Init with fallback, updated in didChangeDependencies if new
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Note Color',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: AppTheme.noteColors.map((c) {
                    final bool isSystem = c.toARGB32() == 0;
                    final bool isSelected = color == c.toARGB32();

                    return GestureDetector(
                      onTap: () {
                        // Update Parent
                        setState(() {
                          color = c.toARGB32();
                          _hasUserModifiedColor = true;
                        });
                        // Update Sheet
                        setSheetState(() {});
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: isSystem
                                ? Theme.of(context).colorScheme.surface
                                : c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: (isSystem ? Colors.black : c)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                            ]),
                        child: isSystem
                            ? Icon(Icons.auto_awesome,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurface)
                            : (isSelected
                                ? Icon(Icons.check,
                                    size: 24,
                                    color: c.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white)
                                : null),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        });
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

    final note = Note(
      id: _noteId,
      title: title,
      content: content,
      dateCreated: _dateCreated,
      dateModified: DateTime.now(),
      isPinned: isPinned,
      isArchived: isArchived,
      color: color,
      imagePath: imagePath,
      category: category,
      tags: tags,
    );

    // Always update since we ensure ID exists
    final exists = widget.note != null || isNoteSaved;
    if (exists) {
      await DatabaseHelper.instance.updateNote(note);
    } else {
      await DatabaseHelper.instance.createNote(note);
      isNoteSaved = true; // Mark as saved so subsequent saves allow update
    }
  }

  bool isNoteSaved = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      // Dynamic Material You Logic
      final theme = Theme.of(context);
      final isSystemDefault = color == 0;

      Color backgroundColor;
      Color onBackground;

      if (isSystemDefault) {
        backgroundColor =
            theme.colorScheme.surface; // Default System Background
        onBackground = theme.colorScheme.onSurface;
      } else {
        // Generate Scheme from Seed
        final scheme = ColorScheme.fromSeed(
          seedColor: Color(color),
          brightness: theme.brightness,
        );
        // Use surfaceContainer for a distinct but integrated feel, or surface.
        // Material 3 Colored/Tinted surfaces often use surfaceContainerHigh or similar.
        // Let's use surfaceContainer for a nice tint.
        backgroundColor = scheme.surfaceContainerHigh;
        onBackground = scheme.onSurface;
      }

      // Ensure visibility of icons
      final textColor = onBackground;
      final hintColor = onBackground.withValues(alpha: 0.6);

      return Scaffold(
        backgroundColor: backgroundColor,
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            height: 64,
            decoration: BoxDecoration(
              color: isSystemDefault
                  ? theme.colorScheme.surfaceContainer
                  : ColorScheme.fromSeed(
                          seedColor: Color(color), brightness: theme.brightness)
                      .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                IconButton(
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: 'Color',
                  color: textColor,
                  onPressed: _showColorPicker,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.format_bold),
                  tooltip: 'Bold',
                  color: textColor,
                  onPressed: () => _applyFormat('**', '**'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.format_italic),
                  tooltip: 'Italic',
                  color: textColor,
                  onPressed: () => _applyFormat('_', '_'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.title),
                  tooltip: 'Heading',
                  color: textColor,
                  onPressed: () => _applyFormat('# ', ''),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.strikethrough_s),
                  tooltip: 'Strikethrough',
                  color: textColor,
                  onPressed: () => _applyFormat('~~', '~~'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.code),
                  tooltip: 'Code',
                  color: textColor,
                  onPressed: () => _applyFormat('`', '`'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.format_quote),
                  tooltip: 'Quote',
                  color: textColor,
                  onPressed: () => _applyFormat('> ', ''),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted),
                  tooltip: 'List',
                  color: textColor,
                  onPressed: () => _applyFormat('- ', ''),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check_box_outlined),
                  tooltip: 'Checkbox',
                  color: textColor,
                  onPressed: () => _applyFormat('- [ ] ', ''),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  tooltip: 'Cover',
                  color: textColor,
                  onPressed: _pickImage,
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // ... Rest of UI using backgroundColor/textColor handles itself usually or uses inherited theme?
              // We need to pass these colors to Sivers or ensure Theme override.
              // Best way: Wrap Scaffold body in Theme?
              // But existing code uses explicit colors in some places.
              // We need to verify SliverAppBar and TextFields.
              // SliverAppBar pill needs to contrast?
              // Let's rely on calculating them here and using them.
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                toolbarHeight: 64,
                title: Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSystemDefault
                        ? theme.colorScheme.surfaceContainer
                        : ColorScheme.fromSeed(
                                seedColor: Color(color),
                                brightness: theme.brightness)
                            .surfaceContainerHighest,
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
                        color: textColor,
                        onPressed: () async {
                          await saveNote();
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.label_outline),
                        tooltip: 'Tags',
                        color: textColor,
                        onPressed: _showTagPicker,
                      ),
                      IconButton(
                        icon: Icon(isPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined),
                        tooltip: isPinned ? 'Unpin' : 'Pin',
                        color: textColor,
                        onPressed: () {
                          setState(() => isPinned = !isPinned);
                          saveNote();
                        },
                      ),
                      ValueListenableBuilder<UndoHistoryValue>(
                        valueListenable: _undoController,
                        builder: (context, value, child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.undo),
                                color: value.canUndo
                                    ? textColor
                                    : textColor.withValues(alpha: 0.3),
                                onPressed:
                                    value.canUndo ? _undoController.undo : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.redo),
                                color: value.canRedo
                                    ? textColor
                                    : textColor.withValues(alpha: 0.3),
                                onPressed:
                                    value.canRedo ? _undoController.redo : null,
                              ),
                            ],
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                            _isPreview ? Icons.edit_outlined : Icons.check),
                        tooltip: _isPreview ? 'Edit' : 'Save & View',
                        color: textColor,
                        onPressed: () {
                          setState(() => _isPreview = !_isPreview);
                          if (_isPreview) saveNote();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    TextField(
                      controller: _titleController,
                      readOnly: _isPreview,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                        filled: false,
                        hintStyle: TextStyle(color: hintColor),
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 8),
                    if (imagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(imagePath!),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (!_isPreview)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white),
                                  style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.black.withValues(alpha: 0.5)),
                                  onPressed: () {
                                    setState(() => imagePath = null);
                                    saveNote();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 8,
                          children: tags
                              .map((tag) => Chip(
                                    label: Text(tag),
                                    onDeleted: _isPreview
                                        ? null
                                        : () {
                                            setState(() {
                                              tags.remove(tag);
                                            });
                                            saveNote();
                                          },
                                  ))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (_isPreview)
                      MarkdownBody(
                        data: _contentController.text,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                              fontSize: settings.textSize,
                              height: 1.5,
                              color: textColor),
                          h1: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor),
                          h2: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor),
                          blockquote: TextStyle(
                              color: textColor.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic),
                          code: TextStyle(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.2),
                              fontFamily: 'monospace',
                              color: textColor),
                          checkbox: TextStyle(color: textColor),
                        ),
                      )
                    else
                      Column(
                        children: [
                          TextField(
                            controller: _contentController,
                            undoController: _undoController,
                            style: TextStyle(
                              fontSize: settings.textSize,
                              height: 1.5,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Start typing...',
                              border: InputBorder.none,
                              filled: false,
                              hintStyle: TextStyle(color: hintColor),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          ),
                          // Toolbar space
                          const SizedBox(height: 60),
                        ],
                      ),
                    const SizedBox(height: 80), // Bottom padding
                  ]),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _applyFormat(String start, String end) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid) {
      final newText = text.replaceRange(selection.start, selection.end,
          '$start${selection.textInside(text)}$end');

      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: selection.start +
                start.length +
                selection.textInside(text).length +
                end.length),
      );
    } else {
      final newText = '$text$start$end';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }
}
