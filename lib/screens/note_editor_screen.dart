import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'dart:async';
import '../data/database_helper.dart';
import '../data/note_model.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import '../utils/rich_text_utils.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  bool isPinned = false;
  bool isArchived = false;
  int color = 0; // 0 = System Default
  List<String> tags = [];
  List<String> _allTags = [];
  Timer? _debounce;
  late String _noteId;
  late DateTime _dateCreated;

  Map<String, int> _tagColors = {}; // Cache for tag colors

  final FocusNode _focusNode = FocusNode();
  bool isNoteSaved = false;

  @override
  void initState() {
    super.initState();
    _noteId = widget.note?.id ?? const Uuid().v4();
    _dateCreated = widget.note?.dateCreated ?? DateTime.now();
    _titleController = TextEditingController(text: widget.note?.title ?? '');

    // Convert Markdown to Delta for Quill
    final initialContent = widget.note?.content ?? '';
    final delta = RichTextUtils.markdownToDelta(initialContent);
    _quillController = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    isPinned = widget.note?.isPinned ?? false;
    isArchived = widget.note?.isArchived ?? false;
    color = widget.note?.color ?? 0;
    tags = List.from(widget.note?.tags ?? []);
    _loadTags();

    // Auto-save listeners
    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);
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
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateColorFromTags() {
    int newColor = 0; // Default
    for (final tag in tags.reversed) {
      final c = _tagColors[tag];
      if (c != null && c != 0) {
        newColor = c;
        break;
      }
    }
    setState(() {
      color = newColor;
    });
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        String enteredTag = '';
        int newTagColor = 0;

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
                          if (enteredTag.isNotEmpty) {
                            if (newTagColor != 0) {
                              await DatabaseHelper.instance
                                  .setTagColor(enteredTag, newTagColor);
                              _tagColors[enteredTag] = newTagColor;
                            }
                            setState(() {
                              if (!tags.contains(enteredTag)) {
                                tags.add(enteredTag);
                                _updateColorFromTags();
                              }
                              if (!_allTags.contains(enteredTag)) {
                                _allTags.add(enteredTag);
                              }
                            });
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    onChanged: (v) => enteredTag = v.trim(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ...[
                        const Color(0x00000000),
                        const Color(0xFFE57373),
                        const Color(0xFFFFB74D),
                        const Color(0xFF81C784),
                        const Color(0xFF64B5F6),
                        const Color(0xFF9575CD),
                      ].map((c) {
                        final bool isSystem = c.toARGB32() == 0;
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
    final title = _titleController.text.trim();
    final delta = _quillController.document.toDelta();
    final content = RichTextUtils.deltaToMarkdown(delta).trim();

    final isEmpty = title.isEmpty && content.isEmpty && tags.isEmpty;
    final exists = widget.note != null || isNoteSaved;

    if (isEmpty) {
      if (exists) {
        await DatabaseHelper.instance.deleteNote(_noteId);
      }
      return;
    }

    final note = Note(
      id: _noteId,
      title: title,
      content: content,
      dateCreated: _dateCreated,
      dateModified: DateTime.now(),
      isPinned: isPinned,
      isArchived: isArchived,
      color: color,
      imagePath: widget.note?.imagePath,
      category: widget.note?.category ?? 'All Notes',
      tags: tags,
    );

    if (exists) {
      await DatabaseHelper.instance.updateNote(note);
    } else {
      await DatabaseHelper.instance.createNote(note);
      isNoteSaved = true;
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This note will be moved to trash.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteNote(_noteId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      final theme = Theme.of(context);
      final isSystemDefault = color == 0;

      Color backgroundColor;
      Color onBackground;

      if (isSystemDefault) {
        backgroundColor = theme.colorScheme.surface;
        onBackground = theme.colorScheme.onSurface;
      } else {
        final scheme = ColorScheme.fromSeed(
          seedColor: Color(color),
          brightness: theme.brightness,
        );
        backgroundColor = scheme.surfaceContainerHigh;
        onBackground = scheme.onSurface;
      }

      final textColor = onBackground;
      final hintColor = onBackground.withValues(alpha: 0.6);

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          try {
            await saveNote();
          } catch (e) {
            debugPrint('Error saving note on pop: $e');
          } finally {
            if (context.mounted) Navigator.pop(context, true);
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
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
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        Container(
                          height: 32,
                          width: 1,
                          color: textColor.withValues(alpha: 0.2),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        QuillToolbarHistoryButton(
                          isUndo: true,
                          controller: _quillController,
                          options: QuillToolbarHistoryButtonOptions(
                              iconTheme: QuillIconTheme(
                                  iconButtonUnselectedData: IconButtonData(
                                      style: IconButton.styleFrom(
                                          foregroundColor: textColor)))),
                        ),
                        QuillToolbarHistoryButton(
                          isUndo: false,
                          controller: _quillController,
                          options: QuillToolbarHistoryButtonOptions(
                              iconTheme: QuillIconTheme(
                                  iconButtonUnselectedData: IconButtonData(
                                      style: IconButton.styleFrom(
                                          foregroundColor: textColor)))),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.label_outline),
                          tooltip: 'Tags',
                          color: textColor,
                          onPressed: _showTagPicker,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                          color: textColor,
                          onPressed: _deleteNote,
                        ),
                        IconButton(
                          icon: const Icon(Icons.check),
                          tooltip: 'Done',
                          color: textColor,
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ],
                    ),
                  ),
                ),
                // Editor Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _titleController,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                          decoration: InputDecoration(
                            hintText: 'Title',
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: hintColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          maxLines: null,
                        ),
                        if (tags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Wrap(
                              spacing: 8,
                              children: tags.map((tag) {
                                final tagColorValue = _tagColors[tag];
                                final tagColor =
                                    tagColorValue != null && tagColorValue != 0
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
                                      style: TextStyle(color: chipLabelColor)),
                                  backgroundColor: chipBgColor,
                                  shape: const StadiumBorder(),
                                  side: BorderSide.none,
                                  onDeleted: () {
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
                        Expanded(
                          child: QuillEditor.basic(
                            controller: _quillController,
                            focusNode: _focusNode,
                            config: QuillEditorConfig(
                              padding: const EdgeInsets.only(bottom: 16),
                              autoFocus: false,
                              expands: false,
                              scrollable: true,
                              placeholder: 'Start typing...',
                              embedBuilders:
                                  FlutterQuillEmbeds.editorBuilders(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Toolbar (Pill)
                SafeArea(
                  top: false,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          // Basic Formatting
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.bold,
                            controller: _quillController,
                            options: QuillToolbarToggleStyleButtonOptions(
                                iconData: Icons.format_bold,
                                iconTheme: QuillIconTheme(
                                    iconButtonUnselectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor: textColor)),
                                    iconButtonSelectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.onPrimary)))),
                          ),
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.italic,
                            controller: _quillController,
                            options: QuillToolbarToggleStyleButtonOptions(
                                iconData: Icons.format_italic,
                                iconTheme: QuillIconTheme(
                                    iconButtonUnselectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor: textColor)),
                                    iconButtonSelectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.onPrimary)))),
                          ),
                          const SizedBox(width: 8),
                          // Lists & Indent
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.ol,
                            controller: _quillController,
                            options: QuillToolbarToggleStyleButtonOptions(
                                iconData: Icons.format_list_numbered,
                                iconTheme: QuillIconTheme(
                                    iconButtonUnselectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor: textColor)),
                                    iconButtonSelectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.onPrimary)))),
                          ),
                          QuillToolbarToggleStyleButton(
                            attribute: Attribute.ul,
                            controller: _quillController,
                            options: QuillToolbarToggleStyleButtonOptions(
                                iconData: Icons.format_list_bulleted,
                                iconTheme: QuillIconTheme(
                                    iconButtonUnselectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor: textColor)),
                                    iconButtonSelectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.onPrimary)))),
                          ),
                          QuillToolbarToggleCheckListButton(
                            controller: _quillController,
                            options: QuillToolbarToggleCheckListButtonOptions(
                                iconData: Icons.check_box,
                                iconTheme: QuillIconTheme(
                                    iconButtonUnselectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor: textColor)),
                                    iconButtonSelectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor:
                                                theme.colorScheme.onPrimary)))),
                          ),
                          const SizedBox(width: 8),
                          // Link & Attachment
                          QuillToolbarLinkStyleButton(
                            controller: _quillController,
                            options: QuillToolbarLinkStyleButtonOptions(
                                iconData: Icons.link,
                                iconTheme: QuillIconTheme(
                                    iconButtonUnselectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor: textColor)))),
                          ),
                          QuillToolbarImageButton(
                            controller: _quillController,
                            options: QuillToolbarImageButtonOptions(
                                iconData: Icons.attach_file, // Attachment icon
                                iconTheme: QuillIconTheme(
                                    iconButtonUnselectedData: IconButtonData(
                                        style: IconButton.styleFrom(
                                            foregroundColor: textColor)))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
