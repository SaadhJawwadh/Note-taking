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
  int color = 0; // 0 = System Default
  String? imagePath;
  String category = 'All Notes';
  List<String> tags = [];
  bool _isPreview = true; // Default to preview
  List<String> _allTags = [];
  Timer? _debounce;
  final UndoHistoryController _undoController = UndoHistoryController();
  late String _noteId;
  late DateTime _dateCreated;

  Map<String, int> _tagColors = {}; // Cache for tag colors

  @override
  void initState() {
    super.initState();
    // Default: Preview if existing note, Edit if new note
    _isPreview = widget.note != null;

    _noteId = widget.note?.id ?? const Uuid().v4();
    _dateCreated = widget.note?.dateCreated ?? DateTime.now();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        MarkdownFormattingController(text: widget.note?.content ?? '');
    isPinned = widget.note?.isPinned ?? false;
    isArchived = widget.note?.isArchived ?? false;

    // Initialize color (int)
    color = widget.note?.color ?? 0;

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
    final c = await DatabaseHelper.instance.getAllTagColors();
    if (mounted) {
      setState(() {
        _allTags = t;
        _tagColors = c;
      });
    }
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
      final savedImage =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');

      if (!mounted) return;
      setState(() {
        imagePath = savedImage.path;
      });
      saveNote();
    }
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        String newTag = '';
        int newTagColor = 0; // Default color

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
                        onPressed: () async {
                          if (newTag.isNotEmpty) {
                            if (newTagColor != 0) {
                              await DatabaseHelper.instance
                                  .setTagColor(newTag, newTagColor);
                            }
                            // Refresh colors from DB to be safe/consistent, or just update local map
                            // Updating local map is faster for UI responsiveness
                            if (newTagColor != 0) {
                              _tagColors[newTag] = newTagColor;
                            }

                            setState(() {
                              if (!tags.contains(newTag)) {
                                tags.add(newTag);
                                _updateColorFromTags();
                              }
                              if (!_allTags.contains(newTag)) {
                                _allTags.add(newTag);
                              }
                            });
                            setModalState(() {
                              newTag = '';
                              newTagColor = 0;
                            });
                            // Close for now, or keep open?
                            // Keeping open allows adding multiple, but we need to clear input (done above)
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                      ),
                    ),
                    onChanged: (v) => newTag = v.trim(),
                    onSubmitted: (v) async {
                      if (v.isNotEmpty) {
                        final t = v.trim();
                        if (newTagColor != 0) {
                          await DatabaseHelper.instance
                              .setTagColor(t, newTagColor);
                          _tagColors[t] = newTagColor;
                        }

                        setState(() {
                          if (!tags.contains(t)) {
                            tags.add(t);
                            _updateColorFromTags();
                          }
                          if (!_allTags.contains(t)) _allTags.add(t);
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Color Picker for New Tag
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      // Import AppTheme to use noteColors
                      // We need to make sure AppTheme is imported. It is not currently imported in this file based on my view.
                      // I will use hardcoded list here or add import. adding import is better but might need separate tool call.
                      // Let's check imports. Main imports note_model, database_helper.
                      // I'll add the color list locally here to avoid import issues if I can't switch context easily,
                      // BUT better to just add import at top.
                      // I will proceed with adding import in a separate call if needed, but for now I'll hardcode the colors to match AppTheme for simplicity in this replacement chunk,
                      // or rely on context theme? No, `AppTheme.noteColors` is static.
                      // Actually, looking at previous file view, AppTheme IS NOT imported in NoteEditorScreen.
                      // I'll use the colors directly here.
                      ...[
                        const Color(0x00000000), // Default
                        const Color(0xFFE57373),
                        const Color(0xFFFFB74D),
                        const Color(0xFF81C784),
                        const Color(0xFF64B5F6),
                        const Color(0xFF9575CD),
                      ].map((c) {
                        final bool isSystem =
                            c.toARGB32() == 0; // Check value for 0x00000000
                        final bool isSelected = newTagColor == c.toARGB32();
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => newTagColor = c.toARGB32()),
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
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
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
                    ],
                  ),
                  if (newTagColor != 0) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Builder(builder: (context) {
                        final scheme = ColorScheme.fromSeed(
                            seedColor: Color(newTagColor),
                            brightness: Theme.of(context).brightness);
                        return Chip(
                          label: Text('Sample Tag Appearance',
                              style:
                                  TextStyle(color: scheme.onPrimaryContainer)),
                          backgroundColor: scheme.primaryContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                        );
                      }),
                    ),
                  ],
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
                              _updateColorFromTags();
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

  void _togglePreview() {
    setState(() {
      _isPreview = !_isPreview;
    });
    if (_isPreview) saveNote();
  }

  void _updateColorFromTags() {
    int newColor = 0; // Default
    // Find the last tag that has a color assigned
    for (final tag in tags.reversed) {
      final c = _tagColors[tag];
      if (c != null && c != 0) {
        newColor = c;
        break;
      }
    }

    // If no specific color found, revert to 0 (system default)
    color = newColor;
  }

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

      final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 16;

      return Scaffold(
        backgroundColor: backgroundColor,
        body: GestureDetector(
          onDoubleTap: _togglePreview, // Double tap to toggle mode
          child: Stack(
            children: [
              // Main Content
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  slivers: [
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
                              ? theme.colorScheme.surfaceContainerHighest
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
                                      onPressed: value.canUndo
                                          ? _undoController.undo
                                          : null,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.redo),
                                      color: value.canRedo
                                          ? textColor
                                          : textColor.withValues(alpha: 0.3),
                                      onPressed: value.canRedo
                                          ? _undoController.redo
                                          : null,
                                    ),
                                  ],
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(_isPreview
                                  ? Icons.edit_outlined
                                  : Icons.check),
                              tooltip: _isPreview ? 'Edit' : 'Save & View',
                              color: textColor,
                              onPressed: _togglePreview,
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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 50, color: Colors.grey)),
                                      ),
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
                                            backgroundColor: Colors.black
                                                .withValues(alpha: 0.5)),
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
                                children: tags.map((tag) {
                                  final tagColorValue = _tagColors[tag];
                                  final tagColor = tagColorValue != null &&
                                          tagColorValue != 0
                                      ? Color(tagColorValue)
                                      : null;

                                  Color? chipBgColor;
                                  Color? chipLabelColor;

                                  if (tagColor != null) {
                                    final scheme = ColorScheme.fromSeed(
                                      seedColor: tagColor,
                                      brightness: Theme.of(context).brightness,
                                    );
                                    chipBgColor = scheme.primaryContainer;
                                    chipLabelColor = scheme.onPrimaryContainer;
                                  }

                                  return Chip(
                                    label: Text(tag,
                                        style:
                                            TextStyle(color: chipLabelColor)),
                                    backgroundColor: chipBgColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    side: BorderSide.none,
                                    onDeleted: _isPreview
                                        ? null
                                        : () {
                                            setState(() {
                                              tags.remove(tag);
                                              _updateColorFromTags();
                                            });
                                            saveNote();
                                          },
                                    deleteIconColor: chipLabelColor,
                                  );
                                }).toList(),
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
                    // Bottom padding provided by SizedBox in list
                  ],
                ),
              ),
              // Floating Bottom Toolbar
              if (MediaQuery.of(context).viewInsets.bottom > 0 || !_isPreview)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: bottomPadding,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSystemDefault
                          ? theme.colorScheme.surfaceContainerHighest
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
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
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
