import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'app_lock_screen.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'dart:async';
import '../data/repositories/note_repository.dart';
import '../data/note_model.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../data/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/rich_text_utils.dart';
import '../utils/quill_checklist_helper.dart';
import 'dart:io';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:local_auth/local_auth.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:intl/intl.dart';
import '../services/local_ai_service.dart';
import '../services/offline_ai_fallback_service.dart';
import '../services/notification_service.dart';
import '../providers/note_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/app_globals.dart';
import 'package:flutter/services.dart';
import '../theme/app_layout.dart';

import '../widgets/editor/editor_table_dialog.dart';
import '../widgets/editor/editor_note_details_sheet.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  /// Text shared into the app (share sheet / text-selection menu) to prefill a new note.
  final String? initialSharedText;

  /// Image paths shared into the app to embed into a new note.
  final List<String>? initialSharedImagePaths;

  /// Starting title/content (Delta JSON) when creating from a template.
  final String? templateTitle;
  final String? templateContent;
  final String? initialFolder;

  const NoteEditorScreen({
    super.key,
    this.note,
    this.initialSharedText,
    this.initialSharedImagePaths,
    this.templateTitle,
    this.templateContent,
    this.initialFolder,
  });

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
  bool _isImageSelected = false;
  List<String> _noteUrls = [];
  DateTime? _reminderAt;
  bool _isNoteLocked = false;
  DateTime? _lastScheduledReminder;
  String _folder = 'All Notes';

  // Voice dictation
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  int _dictationBaseOffset = 0;
  String _lastDictation = '';

  /// True once the user has authenticated to view a locked note this session.
  bool _lockAuthPassed = false;

  // AI summary and selection states
  String? _aiSummary;
  final Set<String> _dismissedUrls = {};
  bool _isUpdatingProgrammatically = false;
  StreamSubscription? _docSubscription;

  // Search and formatting panel state
  bool _showFormattingBar = false;
  bool _isSearching = false;
  bool _isCaseSensitive = false;
  List<int> _searchOffsets = [];
  int _currentSearchIndex = -1;
  bool _isEditingTableCell = false;

  // Slash commands state
  bool _showSlashMenu = false;
  String _slashQuery = '';
  int _slashLineStart = 0;

  static final List<({String label, String command, IconData icon, String description})> _slashCommands = [
    (label: 'AI Assist', command: 'ai', icon: Icons.auto_awesome, description: 'Launch Gemini AI tools'),
    (label: 'Checklist', command: 'todo', icon: Icons.check_box_outlined, description: 'Interactive to-do checkbox'),
    (label: 'Table', command: 'table', icon: Icons.table_chart_outlined, description: 'Insert 3x3 data grid'),
    (label: 'Code Block', command: 'code', icon: Icons.code, description: 'Monospace code container'),
    (label: 'Heading 1', command: 'h1', icon: Icons.title, description: 'Large main heading'),
    (label: 'Heading 2', command: 'h2', icon: Icons.text_fields, description: 'Medium section heading'),
    (label: 'Quote', command: 'quote', icon: Icons.format_quote, description: 'Callout blockquote'),
    (label: 'Bullet List', command: 'bullet', icon: Icons.format_list_bulleted, description: 'Unordered bullet points'),
    (label: 'Numbered List', command: 'number', icon: Icons.format_list_numbered, description: 'Sequential numbered list'),
  ];

  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _noteId = widget.note?.id ?? const Uuid().v4();
    _dateCreated = widget.note?.dateCreated ?? DateTime.now();
    _titleController = TextEditingController(
        text: widget.note?.title ?? widget.templateTitle ?? '');

    // Convert Markdown to Delta for Quill
    final initialContent = widget.note?.content ?? '';
    var delta = RichTextUtils.contentToDelta(initialContent);
    if (widget.note == null) {
      delta = _buildSharedContentDelta() ??
          (widget.templateContent != null
              ? RichTextUtils.contentToDelta(widget.templateContent!)
              : delta);
    }
    _quillController = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    isPinned = widget.note?.isPinned ?? false;
    isArchived = widget.note?.isArchived ?? false;
    color = widget.note?.color ?? 0;
    tags = List.from(widget.note?.tags ?? []);
    _reminderAt = widget.note?.reminderAt;
    _isNoteLocked = widget.note?.isLocked ?? false;
    _folder = widget.note?.category ?? widget.initialFolder ?? 'All Notes';
    _lastScheduledReminder = _reminderAt;
    _lockAuthPassed = !_isNoteLocked;
    if (!_lockAuthPassed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _authenticateForLockedNote();
      });
    } else if (widget.note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
    _loadTags();

    _noteUrls = _extractUrls();

    // Initial checklist sync
    QuillChecklistHelper.syncChecklists(_quillController);

    // Auto-save listeners
    _titleController.addListener(_onContentChanged);
    _quillController.addListener(_onContentChanged);
    _quillController.addListener(_onSelectionChanged); // Add selection listener

    _docSubscription = _quillController.document.changes.listen((event) {
      if (_isUpdatingProgrammatically) return;
      _isUpdatingProgrammatically = true;
      try {
        QuillChecklistHelper.syncChecklists(_quillController);
      } catch (e) {
        debugPrint('Error syncing checklists: $e');
      } finally {
        _isUpdatingProgrammatically = false;
      }
    });
  }

  /// Builds the starting document for a note created from shared content
  /// (share sheet text/links/images or the text-selection context menu).
  /// Returns null when nothing was shared.
  Delta? _buildSharedContentDelta() {
    final sharedText = widget.initialSharedText?.trim();
    final imagePaths = widget.initialSharedImagePaths ?? const [];
    if ((sharedText == null || sharedText.isEmpty) && imagePaths.isEmpty) {
      return null;
    }

    final delta = Delta();
    if (sharedText != null && sharedText.isNotEmpty) {
      delta.insert('$sharedText\n');
    }
    for (final path in imagePaths) {
      delta.insert({'image': path});
      delta.insert('\n');
    }
    return delta;
  }

  void _onSelectionChanged() {
    final selection = _quillController.selection;
    if (mounted) {
      setState(() {
        _isImageSelected = _checkIfImageSelected();
        _showFormattingBar = !selection.isCollapsed;
      });
    }
  }

  bool _checkIfImageSelected() {
    final index = _quillController.selection.baseOffset;
    if (index < 0 || index >= _quillController.document.length) return false;

    // This is valid for many versions of Quill where images are embeds
    final leaf = _quillController.document.querySegmentLeafNode(index).leaf;
    if (leaf != null && leaf.value is BlockEmbed) {
      return (leaf.value as BlockEmbed).type == 'image';
    }
    return false;
  }

  Future<void> _loadTags() async {
    final t = await NoteRepository.instance.getAllTags();
    final c = await NoteRepository.instance.getAllTagColors();
    if (mounted) {
      setState(() {
        _allTags = t;
        _tagColors = c;
      });
    }
  }

  /// Up to three distinct links in the note, for rich preview cards.
  List<String> _extractUrls() {
    final plainText = _quillController.document.toPlainText();
    final urlRegExp = RegExp(r'https?:\/\/[^\s]+');
    final urls = <String>[];
    for (final match in urlRegExp.allMatches(plainText)) {
      var url = match.group(0)!;
      if (RegExp(r'[.,;:)\]]+$').hasMatch(url)) {
        url = url.replaceAll(RegExp(r'[.,;:)\]]+$'), '');
      }
      if (url.isNotEmpty && !urls.contains(url) && !_dismissedUrls.contains(url)) {
        urls.add(url);
      }
      if (urls.length >= 3) break;
    }
    return urls;
  }

  void _onContentChanged() {
    _checkSlashCommands();

    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(seconds: 2), () {
      final urls = _extractUrls();
      if (!listEquals(urls, _noteUrls)) {
        if (mounted) setState(() => _noteUrls = urls);
      }
      saveNote();
    });
  }

  void _checkSlashCommands() {
    final selection = _quillController.selection;
    if (selection.isCollapsed && selection.baseOffset > 0) {
      final plainText = _quillController.document.toPlainText();
      final cursor = selection.baseOffset;
      if (cursor <= plainText.length) {
        final lineStart = plainText.lastIndexOf('\n', cursor - 1) + 1;
        final linePrefix = plainText.substring(lineStart, cursor);
        if (linePrefix.startsWith('/')) {
          final query = linePrefix.substring(1).toLowerCase();
          if (!_showSlashMenu || _slashQuery != query) {
            setState(() {
              _showSlashMenu = true;
              _slashQuery = query;
              _slashLineStart = lineStart;
            });
          }
          return;
        }
      }
    }
    if (_showSlashMenu) {
      setState(() {
        _showSlashMenu = false;
      });
    }
  }

  void _executeSlashCommand(String command) {
    HapticFeedback.lightImpact();
    final currentCursor = _quillController.selection.baseOffset;
    final deleteLength = currentCursor - _slashLineStart;
    if (deleteLength > 0 && deleteLength <= currentCursor) {
      _quillController.replaceText(
        _slashLineStart,
        deleteLength,
        '',
        TextSelection.collapsed(offset: _slashLineStart),
      );
    }
    setState(() => _showSlashMenu = false);

    switch (command) {
      case 'ai':
        _showAiOptionsSheet();
        break;
      case 'todo':
        _quillController.formatSelection(Attribute.unchecked);
        break;
      case 'table':
        _insertTableDirect();
        break;
      case 'code':
        _quillController.formatSelection(Attribute.codeBlock);
        break;
      case 'h1':
        _quillController.formatSelection(Attribute.h1);
        break;
      case 'h2':
        _quillController.formatSelection(Attribute.h2);
        break;
      case 'quote':
        _quillController.formatSelection(Attribute.blockQuote);
        break;
      case 'bullet':
        _quillController.formatSelection(Attribute.ul);
        break;
      case 'number':
        _quillController.formatSelection(Attribute.ol);
        break;
    }
  }

  void _insertTableDirect({int rows = 3, int cols = 3}) {
    final rowsList = List.generate(
      rows,
      (rIndex) => List.generate(
        cols,
        (cIndex) => rIndex == 0 ? 'Header ${cIndex + 1}' : 'Cell',
      ),
    );
    final jsonStr = jsonEncode(rowsList);

    final index = _quillController.selection.baseOffset;
    final length = _quillController.selection.extentOffset - index;

    _quillController.replaceText(
      index,
      length < 0 ? 0 : length,
      TableBlockEmbed(jsonStr),
      null,
    );

    _quillController.updateSelection(
      TextSelection.collapsed(offset: index + 1),
      ChangeSource.local,
    );
  }



  @override
  void dispose() {
    _titleController.removeListener(_onContentChanged);
    _quillController.removeListener(_onContentChanged);
    _quillController.removeListener(_onSelectionChanged);
    _speech.cancel();
    _docSubscription?.cancel();
    _debounce?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
                              await NoteRepository.instance
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
                      ...AppTheme.noteColors.map((c) {
                        final bool isSystem = c.toARGB32() == 0;
                        final bool isSelected =
                            !isSystem && newTagColor == c.toARGB32();
                        return Semantics(
                          label: isSystem ? 'Random Color' : 'Color option',
                          selected: isSelected,
                          button: true,
                          child: GestureDetector(
                            onTap: () {
                              if (isSystem) {
                                final nonZeroColors = AppTheme.noteColors
                                    .where((color) => color.toARGB32() != 0)
                                    .toList();
                                final randomColor =
                                    (nonZeroColors..shuffle()).first;
                                setModalState(
                                    () => newTagColor = randomColor.toARGB32());
                              } else {
                                setModalState(() => newTagColor = c.toARGB32());
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
                                      : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
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
                          ),
                        );
                      }),
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      AppLockScreen.ignoreNextResumeLock();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        final index = _quillController.selection.baseOffset;
        final length = _quillController.selection.extentOffset - index;
        _quillController.replaceText(
            index, length, BlockEmbed.image(pickedFile.path), null);
        if (mounted) {
          Navigator.pop(context); // Close the modal
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) Navigator.pop(context); // Ensure modal closes on error
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final textColor = Theme.of(context).colorScheme.onSurface;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: textColor),
                title: Text('Gallery', style: TextStyle(color: textColor)),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: textColor),
                title: Text('Camera', style: TextStyle(color: textColor)),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future saveNote() async {
    final title = _titleController.text.trim();
    final delta = _quillController.document.toDelta();
    final content = RichTextUtils.deltaToJson(delta);
    final plainText = _quillController.document.toPlainText().trim();
    final isEmpty = title.isEmpty && plainText.isEmpty && tags.isEmpty;
    final exists = widget.note != null || isNoteSaved;

    if (isEmpty) {
      if (exists) {
        await NoteRepository.instance.deleteNote(_noteId);
      }
      return;
    }

    final initialNote = widget.note;
    bool hasChanges = false;
    if (initialNote == null) {
      hasChanges = true;
    } else {
      final titleChanged = title != initialNote.title;
      final contentChanged = content != initialNote.content;
      final pinnedChanged = isPinned != initialNote.isPinned;
      final archivedChanged = isArchived != initialNote.isArchived;
      final colorChanged = color != initialNote.color;
      final tagsChanged = !listEquals(tags, initialNote.tags);
      final reminderChanged = _reminderAt != initialNote.reminderAt;
      final lockChanged = _isNoteLocked != initialNote.isLocked;
      final folderChanged = _folder != initialNote.category;
      hasChanges = titleChanged ||
          contentChanged ||
          pinnedChanged ||
          archivedChanged ||
          colorChanged ||
          tagsChanged ||
          reminderChanged ||
          lockChanged ||
          folderChanged;
    }

    if (!hasChanges) {
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
      category: _folder,
      tags: tags,
      reminderAt: _reminderAt,
      isLocked: _isNoteLocked,
    );

    if (exists) {
      await NoteRepository.instance.updateNote(note);
    } else {
      await NoteRepository.instance.createNote(note);
      isNoteSaved = true;
    }

    // Keep the scheduled notification in sync (only when it actually changed
    // — this runs on every autosave debounce).
    if (_lastScheduledReminder != _reminderAt) {
      _lastScheduledReminder = _reminderAt;
      if (_reminderAt != null) {
        await NotificationService.scheduleNoteReminder(
          noteId: _noteId,
          noteTitle: title,
          when: _reminderAt!,
        );
      } else {
        await NotificationService.cancelNoteReminder(_noteId);
      }
    }
  }

  /// Authenticates before revealing a locked note's content.
  Future<void> _authenticateForLockedNote() async {
    try {
      AppLockScreen.ignoreNextResumeLock();
      final didAuthenticate = await LocalAuthentication().authenticate(
        localizedReason: 'This note is locked',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (!mounted) return;
      if (didAuthenticate) {
        setState(() => _lockAuthPassed = true);
      }
    } catch (e) {
      debugPrint('Locked-note auth error: $e');
    }
  }

  Future<void> _pickReminder() async {
    await HapticFeedback.selectionClick();
    final now = DateTime.now();
    final initial = _reminderAt ?? now.add(const Duration(hours: 1));

    if (!mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      helpText: 'Remind me about this note',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!picked.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder time must be in the future')),
      );
      return;
    }

    setState(() => _reminderAt = picked);
    _onContentChanged(); // persist through the normal autosave path
  }

  void _clearReminder() {
    HapticFeedback.selectionClick();
    setState(() => _reminderAt = null);
    _onContentChanged();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchOffsets = [];
        _currentSearchIndex = -1;
      });
      return;
    }

    final text = _quillController.document.toPlainText();
    final escapedQuery = RegExp.escape(query);
    final matches = RegExp(escapedQuery, caseSensitive: _isCaseSensitive).allMatches(text);
    
    final offsets = matches.map((m) => m.start).toList();
    
    setState(() {
      _searchOffsets = offsets;
      if (offsets.isNotEmpty) {
        _currentSearchIndex = 0;
        _jumpToMatch(offsets[0], query.length);
      } else {
        _currentSearchIndex = -1;
      }
    });
  }

  void _toggleCaseSensitive() {
    HapticFeedback.selectionClick();
    setState(() {
      _isCaseSensitive = !_isCaseSensitive;
    });
    _performSearch(_searchController.text);
  }

  void _jumpToMatch(int offset, int length) {
    _quillController.updateSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + length),
      ChangeSource.local,
    );
  }

  void _nextSearchMatch() {
    if (_searchOffsets.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentSearchIndex = (_currentSearchIndex + 1) % _searchOffsets.length;
      _jumpToMatch(_searchOffsets[_currentSearchIndex], _searchController.text.length);
    });
  }

  void _previousSearchMatch() {
    if (_searchOffsets.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentSearchIndex = (_currentSearchIndex - 1 + _searchOffsets.length) % _searchOffsets.length;
      _jumpToMatch(_searchOffsets[_currentSearchIndex], _searchController.text.length);
    });
  }

  void _closeSearch() {
    HapticFeedback.selectionClick();
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchOffsets = [];
      _currentSearchIndex = -1;
    });
    final sel = _quillController.selection;
    if (sel.isValid) {
      _quillController.updateSelection(
        TextSelection.collapsed(offset: sel.extentOffset),
        ChangeSource.local,
      );
    }
  }

  Future<void> _showTableInsertionDialog() async {
    final result = await EditorTableDialog.show(context);

    if (result != null) {
      final rowsList = List.generate(
        result.rows,
        (rIndex) => List.generate(
          result.cols,
          (cIndex) => rIndex == 0 ? 'Header ${cIndex + 1}' : 'Cell',
        ),
      );
      final jsonStr = jsonEncode(rowsList);

      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      
      _quillController.replaceText(
        index,
        length,
        TableBlockEmbed(jsonStr),
        null,
      );
      
      _quillController.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        ChangeSource.local,
      );
    }
  }

  /// Starts/stops on-device speech dictation, streaming recognized words
  /// into the note at the cursor position.
  Future<void> _toggleDictation() async {
    await HapticFeedback.selectionClick();
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    // Mic permission dialog backgrounds the app briefly.
    AppLockScreen.ignoreNextResumeLock();
    final available = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (e) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Speech recognition is unavailable — check the microphone permission.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final sel = _quillController.selection;
    final docLength = _quillController.document.length;
    _dictationBaseOffset =
        sel.isValid ? sel.end.clamp(0, docLength - 1) : docLength - 1;
    _lastDictation = '';
    if (mounted) setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        if (words.isEmpty) return;
        // Replace the previous partial with the newer, fuller transcript.
        _quillController.replaceText(
          _dictationBaseOffset,
          _lastDictation.length,
          words,
          TextSelection.collapsed(offset: _dictationBaseOffset + words.length),
        );
        _lastDictation = words;
      },
    );
  }



  /// Jump-to-heading navigation for long notes.
  /// Displays word count, character count, reading time, and note timestamps.
  void _showNoteDetailsSheet() {
    HapticFeedback.lightImpact();
    final plainText = _quillController.document.toPlainText();
    EditorNoteDetailsSheet.show(
      context,
      plainText: plainText,
      folder: _folder,
      createdAt: widget.note?.dateCreated,
      updatedAt: widget.note?.dateModified,
    );
  }

  /// Displays sharing options for exporting plain text, markdown, or copying to clipboard.
  void _showShareExportSheet() {
    HapticFeedback.lightImpact();
    final title = _titleController.text.trim();
    final delta = _quillController.document.toDelta();
    final markdown = RichTextUtils.deltaToMarkdown(delta);
    final plainText = _quillController.document.toPlainText().trim();
    final shareContent = title.isEmpty ? plainText : '$title\n\n$plainText';

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.share_outlined, color: colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Share & Export Note',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.text_snippet_outlined),
                  title: const Text('Share as Plain Text'),
                  subtitle: const Text('Send text to other apps or messaging'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppLayout.radiusM),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (shareContent.isNotEmpty) {
                      Share.share(shareContent, subject: title.isEmpty ? 'Note' : title);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code_outlined),
                  title: const Text('Share as Markdown'),
                  subtitle: const Text('Preserve bold, lists, and headers formatting'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppLayout.radiusM),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    final mdContent = title.isEmpty ? markdown : '# $title\n\n$markdown';
                    if (mdContent.isNotEmpty) {
                      Share.share(mdContent, subject: title.isEmpty ? 'Note' : title);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('Copy to Clipboard'),
                  subtitle: const Text('Copy note content to clipboard'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppLayout.radiusM),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (shareContent.isNotEmpty) {
                      await Clipboard.setData(ClipboardData(text: shareContent));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note copied to clipboard')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Lets the user file the note into a folder (or create a new one).
  Future<void> _pickFolder() async {
    await HapticFeedback.selectionClick();
    final folders = await NoteRepository.instance.getAllFolders();
    if (!mounted) return;

    final controller = TextEditingController();
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to folder'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notes_outlined),
                      title: const Text('All Notes'),
                      selected: _folder == 'All Notes',
                      onTap: () => Navigator.pop(ctx, 'All Notes'),
                    ),
                    ...folders.map(
                      (f) => ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(f),
                        selected: _folder == f,
                        onTap: () => Navigator.pop(ctx, f),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'New folder name',
                  prefixIcon: Icon(Icons.create_new_folder_outlined),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            child: const Text('Create & Move'),
          ),
        ],
      ),
    );

    if (chosen == null || chosen == _folder || !mounted) return;
    setState(() => _folder = chosen);
    _onContentChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(chosen == 'All Notes'
            ? 'Removed from folder'
            : 'Moved to "$chosen"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Toggles the per-note biometric lock; toggling in either direction
  /// requires device authentication so a bystander can't unlock a note.
  Future<void> _toggleNoteLock() async {
    await HapticFeedback.selectionClick();
    try {
      AppLockScreen.ignoreNextResumeLock();
      final didAuthenticate = await LocalAuthentication().authenticate(
        localizedReason: _isNoteLocked ? 'Unlock this note' : 'Lock this note',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (!didAuthenticate || !mounted) return;
      setState(() => _isNoteLocked = !_isNoteLocked);
      _onContentChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isNoteLocked
              ? 'Note locked — it will require authentication to open'
              : 'Note unlocked'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Set up a device screen lock or biometrics to lock notes'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: const Text('This note will be moved to Trash.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NoteRepository.instance.softDeleteNote(_noteId);
      if (mounted) Navigator.pop(context, true);

      // The editor is gone after the pop, so surface the undo on the
      // app-level messenger.
      final noteId = _noteId;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('Note moved to Trash'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await NoteRepository.instance.restoreNote(noteId);
              final ctx = appScaffoldMessengerKey.currentContext;
              if (ctx != null && ctx.mounted) {
                await Provider.of<NoteProvider>(ctx, listen: false)
                    .refreshNotes();
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _showAiResultSheet({
    required BuildContext context,
    required String title,
    required String resultText,
    required bool isSelection,
    required TextSelection? selection,
  }) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 240),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppLayout.radiusM),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      resultText,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: const Text('Copy'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: resultText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied result to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        Navigator.of(ctx).pop();
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.post_add_outlined, size: 18),
                      label: const Text('Insert Below'),
                      onPressed: () {
                        final docLen = _quillController.document.length;
                        final safeLen = docLen > 0 ? docLen - 1 : 0;
                        final insertPos = isSelection && selection != null
                            ? selection.end.clamp(0, safeLen)
                            : safeLen;
                        _quillController.replaceText(
                          insertPos,
                          0,
                          '\n$resultText',
                          null,
                        );
                        _onContentChanged();
                        saveNote();
                        Navigator.of(ctx).pop();
                      },
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(isSelection ? 'Replace Selection' : 'Replace All'),
                      onPressed: () {
                        final docLen = _quillController.document.length;
                        final safeLen = docLen > 0 ? docLen - 1 : 0;
                        if (isSelection && selection != null) {
                          final start = selection.start.clamp(0, safeLen);
                          final end = selection.end.clamp(start, safeLen);
                          _quillController.replaceText(
                            start,
                            end - start,
                            resultText,
                            null,
                          );
                        } else {
                          _quillController.replaceText(
                            0,
                            safeLen,
                            resultText,
                            null,
                          );
                        }
                        _onContentChanged();
                        saveNote();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAiOptionsSheet() {
    final aiService = Provider.of<LocalAiService>(context, listen: false);
    bool isLoading = false;
    String? statusText;

    final sel = _quillController.selection;
    final bool isSelection = sel.isValid && !sel.isCollapsed;
    final String targetText = isSelection
        ? _quillController.document.getPlainText(sel.start, sel.end - sel.start).trim()
        : _quillController.document.toPlainText().trim();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final theme = Theme.of(sheetContext);
            final colorScheme = theme.colorScheme;

            Widget buildSectionHeader(String title, IconData icon) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(2, 10, 2, 4),
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      title.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.7,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Avatar Ring
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 20,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'On-Device Gemini AI',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Powered by Android AI Core • 100% Offline & Private',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Context Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelection
                                  ? colorScheme.primaryContainer.withValues(alpha: 0.7)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                              border: Border.all(
                                color: isSelection
                                    ? colorScheme.primary.withValues(alpha: 0.3)
                                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelection ? Icons.select_all_rounded : Icons.description_outlined,
                                  size: 13,
                                  color: isSelection
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSelection
                                      ? 'Targeting selected text (${targetText.length} chars)'
                                      : 'Targeting entire note content',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isSelection
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        if (statusText != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            statusText!,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        if (isLoading) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppLayout.radiusM),
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                LinearProgressIndicator(
                                  backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(AppLayout.radiusMAX),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  statusText ?? 'Processing with Gemini Nano…',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Section 1: Refine & Rewrite
                          buildSectionHeader('Refine & Rewrite', Icons.edit_note_rounded),
                          _buildAiTile(
                            context: context,
                            icon: Icons.check_box_outlined,
                            title: 'Extract Action Items',
                            subtitle: isSelection
                                ? 'Find to-dos in selection and create checkboxes'
                                : 'Find to-dos in note and create checkboxes',
                            onTap: () async {
                              final editorContext = context;
                              final navigator = Navigator.of(editorContext);
                              if (targetText.isEmpty) {
                                setModalState(() {
                                  statusText = 'No text to analyze.';
                                });
                                return;
                              }
                              setModalState(() {
                                isLoading = true;
                                statusText = 'Extracting tasks...';
                              });
                              final prompt =
                                  "Extract all actionable tasks, to-dos, or action items from the following text. Format each item on a new line prefixed with '☐ '. Respond ONLY with the list of items:\n\n$targetText";
                              String actionItemsText = await aiService.generateText(prompt) ?? '';
                              if (actionItemsText.trim().isEmpty) {
                                actionItemsText = OfflineAiFallbackService.extractActionItems(targetText);
                              }
                              if (actionItemsText.trim().isNotEmpty) {
                                navigator.pop();
                                if (mounted) {
                                  await _showAiResultSheet(
                                    context: context,
                                    title: 'Extracted Action Items',
                                    resultText: actionItemsText.trim(),
                                    isSelection: isSelection,
                                    selection: isSelection ? sel : null,
                                  );
                                }
                              } else {
                                setModalState(() {
                                  isLoading = false;
                                  statusText = 'No action items found.';
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 6),
                          _buildAiTile(
                            context: context,
                            icon: Icons.auto_fix_high_rounded,
                            title: 'Proofread & Polish',
                            subtitle: 'Correct grammar, spelling, and style',
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              if (targetText.isEmpty) {
                                setModalState(() {
                                  statusText = 'No text to polish.';
                                });
                                return;
                              }
                              setModalState(() {
                                isLoading = true;
                                statusText = 'Polishing grammar...';
                              });
                              final res = await aiService.refineText(targetText, 'polish');
                              if (res != null && res.trim().isNotEmpty) {
                                navigator.pop();
                                if (mounted) {
                                  await _showAiResultSheet(
                                    context: context,
                                    title: 'Polished Text',
                                    resultText: res.trim(),
                                    isSelection: isSelection,
                                    selection: isSelection ? sel : null,
                                  );
                                }
                              } else {
                                setModalState(() {
                                  isLoading = false;
                                  statusText = 'Failed to polish text.';
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 6),
                          _buildAiTile(
                            context: context,
                            icon: Icons.compress_rounded,
                            title: 'Make Shorter / Simplify',
                            subtitle: 'Condense into clear, direct key points',
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              if (targetText.isEmpty) {
                                setModalState(() {
                                  statusText = 'No text to shorten.';
                                });
                                return;
                              }
                              setModalState(() {
                                isLoading = true;
                                statusText = 'Simplifying text...';
                              });
                              final res = await aiService.refineText(targetText, 'shorten');
                              if (res != null && res.trim().isNotEmpty) {
                                navigator.pop();
                                if (mounted) {
                                  await _showAiResultSheet(
                                    context: context,
                                    title: 'Simplified Text',
                                    resultText: res.trim(),
                                    isSelection: isSelection,
                                    selection: isSelection ? sel : null,
                                  );
                                }
                              } else {
                                setModalState(() {
                                  isLoading = false;
                                  statusText = 'Failed to shorten text.';
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 6),
                          _buildAiTile(
                            context: context,
                            icon: Icons.unfold_more_rounded,
                            title: 'Elaborate & Expand',
                            subtitle: 'Flesh out quick notes into structured paragraphs',
                            onTap: () async {
                              final navigator = Navigator.of(context);
                              if (targetText.isEmpty) {
                                setModalState(() {
                                  statusText = 'No text to expand.';
                                });
                                return;
                              }
                              setModalState(() {
                                isLoading = true;
                                statusText = 'Expanding text...';
                              });
                              final res = await aiService.refineText(targetText, 'expand');
                              if (res != null && res.trim().isNotEmpty) {
                                navigator.pop();
                                if (mounted) {
                                  await _showAiResultSheet(
                                    context: context,
                                    title: 'Expanded Text',
                                    resultText: res.trim(),
                                    isSelection: isSelection,
                                    selection: isSelection ? sel : null,
                                  );
                                }
                              } else {
                                setModalState(() {
                                  isLoading = false;
                                  statusText = 'Failed to expand text.';
                                });
                              }
                            },
                          ),

                          // Section 2: Smart Metadata & Organization
                          if (!isSelection) ...[
                            buildSectionHeader('Smart Metadata & Organization', Icons.auto_awesome_mosaic_rounded),
                            _buildAiTile(
                              context: context,
                              icon: Icons.title_rounded,
                              title: 'Suggest Title',
                              subtitle: 'Generate a clean title from note content',
                              onTap: () async {
                                final navigator = Navigator.of(context);
                                if (targetText.isEmpty) {
                                  setModalState(() {
                                    statusText = 'Note is empty.';
                                  });
                                  return;
                                }
                                setModalState(() {
                                  isLoading = true;
                                  statusText = 'Analyzing content...';
                                });
                                final prompt =
                                    "Generate a short, concise title (maximum 4-5 words) for the following text. Respond ONLY with the title:\n\n$targetText";
                                String? suggested = await aiService.generateText(prompt);
                                if (suggested == null || suggested.trim().isEmpty) {
                                  final lines = targetText.split(RegExp(r'\r?\n|\.'));
                                  final firstLine = lines.firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
                                  if (firstLine.trim().isNotEmpty) {
                                    final clean = firstLine.trim().replaceAll(RegExp(r'^[•\-\*\d+\.\s]+'), '');
                                    suggested = clean.length > 35 ? '${clean.substring(0, 35)}…' : clean;
                                  }
                                }
                                if (suggested != null && suggested.trim().isNotEmpty) {
                                  if (mounted) {
                                    setState(() {
                                      _titleController.text = suggested!.trim().replaceAll('"', '');
                                    });
                                    _onContentChanged();
                                    await saveNote();
                                    navigator.pop();
                                  }
                                } else {
                                  setModalState(() {
                                    isLoading = false;
                                    statusText = 'Failed to generate title.';
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 6),
                            _buildAiTile(
                              context: context,
                              icon: Icons.label_outline_rounded,
                              title: 'Suggest Tags',
                              subtitle: 'Auto-detect topics and apply tags',
                              onTap: () async {
                                final navigator = Navigator.of(context);
                                if (targetText.isEmpty) {
                                  setModalState(() {
                                    statusText = 'Note is empty.';
                                  });
                                  return;
                                }
                                setModalState(() {
                                  isLoading = true;
                                  statusText = 'Identifying topics...';
                                });
                                final suggested = await aiService.suggestTags(targetText, _allTags);
                                if (suggested.isNotEmpty) {
                                  if (mounted) {
                                    setState(() {
                                      for (final tag in suggested) {
                                        if (!tags.contains(tag)) {
                                          tags.add(tag);
                                        }
                                      }
                                      _updateColorFromTags();
                                    });
                                    _onContentChanged();
                                    await saveNote();
                                    navigator.pop();
                                  }
                                } else {
                                  setModalState(() {
                                    isLoading = false;
                                    statusText = 'No new tags suggested.';
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 6),
                            _buildAiTile(
                              context: context,
                              icon: Icons.short_text_rounded,
                              title: 'Summarize Note',
                              subtitle: 'Append a bulleted summary to the note',
                              onTap: () async {
                                final navigator = Navigator.of(context);
                                if (targetText.isEmpty) {
                                  setModalState(() {
                                    statusText = 'Note is empty.';
                                  });
                                  return;
                                }
                                setModalState(() {
                                  isLoading = true;
                                  statusText = 'Generating summary...';
                                });
                                final summary = await aiService.summarize(targetText);
                                if (summary != null && summary.trim().isNotEmpty) {
                                  if (mounted) {
                                    setState(() {
                                      _aiSummary = summary.trim();
                                    });
                                    navigator.pop();
                                  }
                                } else {
                                  setModalState(() {
                                    isLoading = false;
                                    statusText = 'Failed to generate summary.';
                                  });
                                }
                              },
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAiTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppLayout.radiusM),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppLayout.radiusM)),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppLayout.radiusS),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            fontSize: 13.5,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11.5,
            height: 1.15,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            size: 18, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }

  Widget _buildSlashMenuOverlay(ThemeData theme, ColorScheme colorScheme) {
    final filteredCommands = _slashCommands
        .where((cmd) =>
            cmd.command.startsWith(_slashQuery) ||
            cmd.label.toLowerCase().contains(_slashQuery))
        .toList();

    if (filteredCommands.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: AppLayout.animShort,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppLayout.radiusXL),
        boxShadow: AppLayout.softShadow(context),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppLayout.radiusXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Icon(Icons.bolt, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Slash Commands',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Type to filter',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filteredCommands.length,
                  itemBuilder: (context, index) {
                    final cmd = filteredCommands[index];
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppLayout.radiusS),
                        ),
                        child: Icon(cmd.icon, size: 18, color: colorScheme.primary),
                      ),
                      title: Row(
                        children: [
                          Text(
                            cmd.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(AppLayout.radiusS),
                            ),
                            child: Text(
                              '/${cmd.command}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontFamily: 'monospace',
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        cmd.description,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => _executeSlashCommand(cmd.command),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_lockAuthPassed) {
      final cs = Theme.of(context).colorScheme;
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surface,
                cs.surfaceContainerHigh,
                cs.surfaceContainerHighest,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.tertiary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 600),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: child,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.lock_outline, size: 48, color: cs.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'This note is locked',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Authenticate to view its content',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  FilledButton.icon(
                                    onPressed: _authenticateForLockedNote,
                                    icon: const Icon(Icons.fingerprint),
                                    label: const Text('Unlock Note'),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 54),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      final theme = Theme.of(context);
      final isSystemDefault = color == 0;

      Color backgroundColor;
      Color onBackground;

      ColorScheme noteScheme;

      if (isSystemDefault) {
        noteScheme = theme.colorScheme;
        backgroundColor = theme.colorScheme.surface;
        onBackground = theme.colorScheme.onSurface;
      } else {
        noteScheme = ColorScheme.fromSeed(
          seedColor: Color(color),
          brightness: theme.brightness,
        );
        backgroundColor = noteScheme.surfaceContainerHigh;
        onBackground = noteScheme.onSurface;
      }

      final textColor = onBackground;
      final hintColor = onBackground.withValues(alpha: 0.6);

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          try {
            _debounce?.cancel();
            await saveNote();
          } catch (e) {
            debugPrint('Error saving note on pop: $e');
          } finally {
            if (context.mounted) Navigator.pop(context, true);
          }
        },
        child: Scaffold(
          // The AnimatedContainer below owns the color so switching note
          // colors eases instead of snapping.
          backgroundColor: Colors.transparent,
          body: AnimatedContainer(
            duration: AppLayout.animLong,
            curve: Curves.easeOutCubic,
            color: backgroundColor,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSystemDefault
                                ? theme.colorScheme.surfaceContainerHighest
                                : ColorScheme.fromSeed(
                                        seedColor: Color(color),
                                        brightness: theme.brightness)
                                    .surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(AppLayout.radiusMAX),
                            boxShadow: AppLayout.softShadow(context),
                          ),
                          child: _isSearching
                              ? CallbackShortcuts(
                                  bindings: <ShortcutActivator, VoidCallback>{
                                    const SingleActivator(LogicalKeyboardKey.escape): _closeSearch,
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.arrow_back),
                                          color: theme.colorScheme.onSurfaceVariant,
                                          tooltip: 'Close search',
                                          onPressed: _closeSearch,
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            focusNode: _searchFocusNode,
                                            style: TextStyle(color: theme.colorScheme.onSurface),
                                            decoration: InputDecoration(
                                              hintText: 'Search in note...',
                                              hintStyle: TextStyle(
                                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                              ),
                                              filled: false,
                                              fillColor: Colors.transparent,
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                              isDense: true,
                                            ),
                                            onChanged: _performSearch,
                                            onSubmitted: (_) => _nextSearchMatch(),
                                          ),
                                        ),
                                        Tooltip(
                                          message: 'Match case',
                                          child: InkWell(
                                            onTap: _toggleCaseSensitive,
                                            borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 150),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _isCaseSensitive
                                                    ? theme.colorScheme.primaryContainer
                                                    : Colors.transparent,
                                                borderRadius: BorderRadius.circular(AppLayout.radiusS),
                                                border: Border.all(
                                                  color: _isCaseSensitive
                                                      ? theme.colorScheme.primary
                                                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Text(
                                                'Aa',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: _isCaseSensitive ? FontWeight.bold : FontWeight.normal,
                                                  color: _isCaseSensitive
                                                      ? theme.colorScheme.onPrimaryContainer
                                                      : theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        if (_searchController.text.isNotEmpty)
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            margin: const EdgeInsets.symmetric(horizontal: 2),
                                            decoration: BoxDecoration(
                                              color: _searchOffsets.isNotEmpty
                                                  ? theme.colorScheme.secondaryContainer
                                                  : theme.colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(AppLayout.radiusM),
                                            ),
                                            child: Text(
                                              _searchOffsets.isNotEmpty
                                                  ? '${_currentSearchIndex + 1}/${_searchOffsets.length}'
                                                  : '0/0',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: _searchOffsets.isNotEmpty
                                                    ? theme.colorScheme.onSecondaryContainer
                                                    : theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        if (_searchOffsets.isNotEmpty) ...[
                                          IconButton(
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                            color: theme.colorScheme.onSurfaceVariant,
                                            tooltip: 'Previous match',
                                            onPressed: _previousSearchMatch,
                                          ),
                                          IconButton(
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                            color: theme.colorScheme.onSurfaceVariant,
                                            tooltip: 'Next match',
                                            onPressed: _nextSearchMatch,
                                          ),
                                        ],
                                        if (_searchController.text.isNotEmpty)
                                          IconButton(
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.close, size: 20),
                                            color: theme.colorScheme.onSurfaceVariant,
                                            tooltip: 'Clear search text',
                                            onPressed: () {
                                              HapticFeedback.selectionClick();
                                              _searchController.clear();
                                              _performSearch('');
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                )
                              : Row(
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
                                      margin:
                                          const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    QuillToolbarHistoryButton(
                                      isUndo: true,
                                      controller: _quillController,
                                      options: QuillToolbarHistoryButtonOptions(
                                          iconTheme: QuillIconTheme(
                                              iconButtonUnselectedData:
                                                  IconButtonData(
                                                      style: IconButton.styleFrom(
                                                          foregroundColor:
                                                              textColor)))),
                                    ),
                                    QuillToolbarHistoryButton(
                                      isUndo: false,
                                      controller: _quillController,
                                      options: QuillToolbarHistoryButtonOptions(
                                          iconTheme: QuillIconTheme(
                                              iconButtonUnselectedData:
                                                  IconButtonData(
                                                      style: IconButton.styleFrom(
                                                          foregroundColor:
                                                              textColor)))),
                                    ),
                                    const Spacer(),
                                    if (settings.useOnDeviceAi)
                                      IconButton(
                                        icon: const Icon(Icons.auto_awesome_outlined),
                                        tooltip: 'Gemini AI',
                                        color: textColor,
                                        onPressed: _showAiOptionsSheet,
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.label_outline),
                                      tooltip: 'Tags',
                                      color: textColor,
                                      onPressed: _showTagPicker,
                                    ),

                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert, color: textColor),
                                      tooltip: 'More',
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'reminder':
                                            _pickReminder();
                                            break;
                                          case 'clear_reminder':
                                            _clearReminder();
                                            break;
                                          case 'folder':
                                            _pickFolder();
                                            break;
                                          case 'details':
                                            _showNoteDetailsSheet();
                                            break;
                                          case 'share':
                                            _showShareExportSheet();
                                            break;
                                          case 'lock':
                                            _toggleNoteLock();
                                            break;
                                          case 'delete':
                                            _deleteNote();
                                            break;
                                          case 'search':
                                            setState(() {
                                              _isSearching = true;
                                            });
                                            _searchFocusNode.requestFocus();
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'search',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(Icons.search),
                                            title: Text('Find in Note'),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'reminder',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(_reminderAt != null
                                                ? Icons.alarm_on
                                                : Icons.alarm_add_outlined),
                                            title: Text(_reminderAt != null
                                                ? 'Change reminder'
                                                : 'Set reminder'),
                                          ),
                                        ),
                                        if (_reminderAt != null)
                                          const PopupMenuItem(
                                            value: 'clear_reminder',
                                            child: ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: Icon(Icons.alarm_off_outlined),
                                              title: Text('Remove reminder'),
                                            ),
                                          ),
                                        const PopupMenuItem(
                                          value: 'folder',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(Icons.folder_outlined),
                                            title: Text('Move to folder'),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'details',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(Icons.info_outline),
                                            title: Text('Note Details & Stats'),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'share',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(Icons.share_outlined),
                                            title: Text('Share & Export'),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'lock',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(_isNoteLocked
                                                ? Icons.lock_open_outlined
                                                : Icons.lock_outline),
                                            title: Text(_isNoteLocked
                                                ? 'Unlock note'
                                                : 'Lock note'),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(Icons.delete_outline),
                                            title: Text('Move to Trash'),
                                          ),
                                        ),
                                      ],
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
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
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
                              if (_reminderAt != null || _isNoteLocked || _folder != 'All Notes')
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Wrap(
                                    spacing: 8,
                                    children: [
                                      if (_reminderAt != null)
                                        InputChip(
                                          avatar: Icon(Icons.alarm,
                                              size: 16, color: textColor),
                                          label: Text(
                                            DateFormat('EEE, d MMM • h:mm a')
                                                .format(_reminderAt!),
                                            style: TextStyle(
                                                color: textColor, fontSize: 12),
                                          ),
                                          onPressed: _pickReminder,
                                          onDeleted: _clearReminder,
                                          deleteIconColor: textColor,
                                        ),
                                      if (_isNoteLocked)
                                        Chip(
                                          avatar: Icon(Icons.lock,
                                              size: 16, color: textColor),
                                          label: Text(
                                            'Locked',
                                            style: TextStyle(
                                                color: textColor, fontSize: 12),
                                          ),
                                        ),
                                      if (_folder != 'All Notes')
                                        InputChip(
                                          avatar: Icon(Icons.folder_outlined,
                                              size: 16, color: textColor),
                                          label: Text(
                                            _folder,
                                            style: TextStyle(
                                                color: textColor, fontSize: 12),
                                          ),
                                          onPressed: _pickFolder,
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
                                          brightness:
                                              Theme.of(context).brightness,
                                        );
                                        chipBgColor = scheme.primaryContainer;
                                        chipLabelColor =
                                            scheme.onPrimaryContainer;
                                      }
                                      return Chip(
                                        label: Text(tag,
                                            style: TextStyle(
                                                color: chipLabelColor)),
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
                                 child: NotificationListener<UserScrollNotification>(
                                   onNotification: (scrollNotification) {
                                     if (scrollNotification.direction ==
                                             ScrollDirection.reverse &&
                                         _focusNode.hasFocus) {
                                       FocusScope.of(context).unfocus();
                                     }
                                     return false;
                                   },
                                   child: NotificationListener<TableCellFocusNotification>(
                                     onNotification: (notification) {
                                       setState(() {
                                         _isEditingTableCell = notification.isFocused;
                                       });
                                       return true;
                                     },
                                     child: QuillEditor.basic(
                                       controller: _quillController,
                                       focusNode: _focusNode,
                                       config: QuillEditorConfig(
                                         padding: const EdgeInsets.only(bottom: 16),
                                         autoFocus: false,
                                         showCursor: !_isEditingTableCell,
                                       // Markdown-style typing: '- ', '1. ',
                                       // '# ', '**bold**', and '[] ' for a
                                       // checklist item.
                                       // ignore: experimental_member_use
                                       characterShortcutEvents:
                                           standardCharactersShortcutEvents,
                                       // ignore: experimental_member_use
                                       spaceShortcutEvents: [
                                         ...standardSpaceShorcutEvents,
                                         // ignore: experimental_member_use
                                         SpaceShortcutEvent(
                                           character: '[]',
                                           handler: (node, controller) {
                                             // package uses internally for
                                          // '- ' → bullet, via public APIs.
                                          controller.replaceText(
                                              controller
                                                      .selection.baseOffset -
                                                  2,
                                              2,
                                              '\n',
                                              null);
                                          final base = controller
                                                  .selection.baseOffset -
                                              2;
                                          controller.updateSelection(
                                            controller.selection.copyWith(
                                              baseOffset: base,
                                              extentOffset: base,
                                            ),
                                            ChangeSource.local,
                                          );
                                          controller
                                            ..formatSelection(
                                                Attribute.unchecked)
                                            ..replaceText(
                                                controller.selection
                                                        .baseOffset +
                                                    1,
                                                1,
                                                '',
                                                null);
                                          return true;
                                        },
                                      ),
                                    ],
                                    expands: false,
                                    scrollable: true,
                                    placeholder: 'Start typing...',
                                    embedBuilders: [
                                      const RoundedImageEmbedBuilder(),
                                      const TableEmbedBuilder(),
                                      ...FlutterQuillEmbeds.editorBuilders(),
                                    ],
                                    customStyles: DefaultStyles(
                                      inlineCode: InlineCodeStyle(
                                        style: TextStyle(
                                          color: noteScheme.onSurface,
                                          backgroundColor: noteScheme.onSurface
                                              .withValues(alpha: 0.15),
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      h1: DefaultTextBlockStyle(
                                        theme.textTheme.displaySmall!.copyWith(
                                          color: noteScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        const HorizontalSpacing(0, 0),
                                        const VerticalSpacing(16, 0),
                                        const VerticalSpacing(0, 0),
                                        null,
                                      ),
                                      h2: DefaultTextBlockStyle(
                                        theme.textTheme.headlineMedium!
                                            .copyWith(
                                          color: noteScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        const HorizontalSpacing(0, 0),
                                        const VerticalSpacing(14, 0),
                                        const VerticalSpacing(0, 0),
                                        null,
                                      ),
                                      h3: DefaultTextBlockStyle(
                                        theme.textTheme.headlineSmall!.copyWith(
                                          color: noteScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        const HorizontalSpacing(0, 0),
                                        const VerticalSpacing(12, 0),
                                        const VerticalSpacing(0, 0),
                                        null,
                                      ),
                                      quote: DefaultTextBlockStyle(
                                        TextStyle(
                                          color: noteScheme.onSurface
                                              .withValues(alpha: 0.7),
                                          fontStyle: FontStyle.italic,
                                          fontSize: 16,
                                        ),
                                        const HorizontalSpacing(16, 0),
                                        const VerticalSpacing(8, 8),
                                        const VerticalSpacing(0, 0),
                                        BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              width: 4,
                                              color: noteScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      code: DefaultTextBlockStyle(
                                        TextStyle(
                                          color: noteScheme.onSurface,
                                          fontFamily: 'monospace',
                                          fontSize: 13.5,
                                          height: 1.4,
                                        ),
                                        const HorizontalSpacing(12, 12),
                                        const VerticalSpacing(8, 8),
                                        const VerticalSpacing(0, 0),
                                        BoxDecoration(
                                          color: noteScheme.surfaceContainerHighest
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(AppLayout.radiusM),
                                          border: Border.all(
                                            color: noteScheme.outlineVariant
                                                .withValues(alpha: 0.4),
                                            width: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                               ),
                             ),
                           ),
                               ..._noteUrls.map(
                                (url) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Stack(
                                    children: [
                                      AnyLinkPreview(
                                        link: url,
                                        displayDirection:
                                            UIDirection.uiDirectionHorizontal,
                                        cache: const Duration(hours: 1),
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainer,
                                        errorWidget: const SizedBox.shrink(),
                                        errorImage:
                                            "https://via.placeholder.com/150",
                                        removeElevation: true,
                                        borderRadius: 12,
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Tooltip(
                                          message: 'Remove Link Preview',
                                          child: Material(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.9),
                                            shape: const CircleBorder(),
                                            elevation: 2,
                                            child: InkWell(
                                              customBorder:
                                                  const CircleBorder(),
                                              onTap: () async {
                                                await HapticFeedback
                                                    .lightImpact();
                                                setState(() {
                                                  _dismissedUrls.add(url);
                                                  _noteUrls.remove(url);
                                                });
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                      // Slash Commands Overlay Card
                      if (_showSlashMenu && !_isImageSelected)
                        _buildSlashMenuOverlay(theme, noteScheme),

                      // Secondary Floating Glassmorphism Formatting Bar
                      if (_showFormattingBar && !_isImageSelected)
                        SafeArea(
                          top: false,
                          bottom: false,
                          child: AnimatedContainer(
                            duration: AppLayout.animShort,
                            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            decoration: BoxDecoration(
                              color: (isSystemDefault
                                      ? theme.colorScheme.surfaceContainerHigh
                                      : ColorScheme.fromSeed(
                                              seedColor: Color(color),
                                              brightness: theme.brightness)
                                          .surfaceContainerHigh)
                                  .withValues(alpha: 0.90),
                              borderRadius:
                                  BorderRadius.circular(AppLayout.radiusMAX),
                              boxShadow: AppLayout.softShadow(context),
                              border: Border.all(
                                color: noteScheme.outlineVariant.withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppLayout.radiusMAX),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 2),
                                        child: IconButton.filledTonal(
                                          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                                          tooltip: 'Gemini AI Assist',
                                          onPressed: _showAiOptionsSheet,
                                          style: IconButton.styleFrom(
                                            backgroundColor: noteScheme.primaryContainer,
                                            foregroundColor: noteScheme.onPrimaryContainer,
                                            padding: const EdgeInsets.all(6),
                                            minimumSize: const Size(34, 34),
                                            maximumSize: const Size(34, 34),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 20,
                                        child: VerticalDivider(
                                          width: 12,
                                          thickness: 1,
                                          color: noteScheme.outlineVariant.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      QuillToolbarToggleStyleButton(
                                        attribute: Attribute.bold,
                                        controller: _quillController,
                                        options: QuillToolbarToggleStyleButtonOptions(
                                            iconData: Icons.format_bold,
                                            iconTheme: QuillIconTheme(
                                                iconButtonUnselectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor:
                                                                textColor)),
                                                iconButtonSelectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor: theme
                                                                .colorScheme
                                                                .onPrimary)))),
                                      ),
                                      QuillToolbarToggleStyleButton(
                                        attribute: Attribute.italic,
                                        controller: _quillController,
                                        options: QuillToolbarToggleStyleButtonOptions(
                                            iconData: Icons.format_italic,
                                            iconTheme: QuillIconTheme(
                                                iconButtonUnselectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor:
                                                                textColor)),
                                                iconButtonSelectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor: theme
                                                                .colorScheme
                                                                .onPrimary)))),
                                      ),
                                      QuillToolbarToggleStyleButton(
                                        attribute: Attribute.ol,
                                        controller: _quillController,
                                        options: QuillToolbarToggleStyleButtonOptions(
                                            iconData: Icons.format_list_numbered,
                                            iconTheme: QuillIconTheme(
                                                iconButtonUnselectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor:
                                                                textColor)),
                                                iconButtonSelectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor: theme
                                                                .colorScheme
                                                                .onPrimary)))),
                                      ),
                                      QuillToolbarToggleStyleButton(
                                        attribute: Attribute.ul,
                                        controller: _quillController,
                                        options: QuillToolbarToggleStyleButtonOptions(
                                            iconData: Icons.format_list_bulleted,
                                            iconTheme: QuillIconTheme(
                                                iconButtonUnselectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor:
                                                                textColor)),
                                                iconButtonSelectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor: theme
                                                                .colorScheme
                                                                .onPrimary)))),
                                      ),
                                      QuillToolbarToggleStyleButton(
                                        attribute: Attribute.blockQuote,
                                        controller: _quillController,
                                        options: QuillToolbarToggleStyleButtonOptions(
                                            iconData: Icons.format_quote,
                                            iconTheme: QuillIconTheme(
                                                iconButtonUnselectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor:
                                                                textColor)),
                                                iconButtonSelectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor: theme
                                                                .colorScheme
                                                                .onPrimary)))),
                                      ),
                                      QuillToolbarToggleStyleButton(
                                        attribute: Attribute.codeBlock,
                                        controller: _quillController,
                                        options: QuillToolbarToggleStyleButtonOptions(
                                            iconData: Icons.code,
                                            iconTheme: QuillIconTheme(
                                                iconButtonUnselectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor:
                                                                textColor)),
                                                iconButtonSelectedData:
                                                    IconButtonData(
                                                        style: IconButton.styleFrom(
                                                            foregroundColor: theme
                                                                .colorScheme
                                                                .onPrimary)))),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.table_chart_outlined),
                                        tooltip: 'Insert Table',
                                        onPressed: _showTableInsertionDialog,
                                        style: IconButton.styleFrom(
                                          foregroundColor: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Bottom Toolbar (Pill)
                      Visibility(
                        visible: !_isImageSelected,
                        child: SafeArea(
                          top: false,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSystemDefault
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : ColorScheme.fromSeed(
                                          seedColor: Color(color),
                                          brightness: theme.brightness)
                                      .surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(AppLayout.radiusMAX),
                              boxShadow: AppLayout.softShadow(context),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: Icon(_showFormattingBar
                                        ? Icons.keyboard_hide_outlined
                                        : Icons.text_fields),
                                    tooltip: 'Formatting',
                                    onPressed: () {
                                      setState(() {
                                        _showFormattingBar = !_showFormattingBar;
                                      });
                                    },
                                    style: IconButton.styleFrom(
                                      foregroundColor: _showFormattingBar
                                          ? theme.colorScheme.primary
                                          : textColor,
                                    ),
                                  ),
                                  QuillToolbarToggleCheckListButton(
                                    controller: _quillController,
                                    options: QuillToolbarToggleCheckListButtonOptions(
                                        iconData: Icons.check_box_outlined,
                                        iconTheme: QuillIconTheme(
                                            iconButtonUnselectedData:
                                                IconButtonData(
                                                    style: IconButton.styleFrom(
                                                        foregroundColor:
                                                            textColor)),
                                            iconButtonSelectedData:
                                                IconButtonData(
                                                    style: IconButton.styleFrom(
                                                        foregroundColor: theme
                                                            .colorScheme
                                                            .onPrimary)))),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.image_outlined),
                                    tooltip: 'Attach Image',
                                    onPressed: _showImageOptions,
                                    style: IconButton.styleFrom(
                                      foregroundColor: textColor,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(_isListening
                                        ? Icons.mic
                                        : Icons.mic_none),
                                    tooltip: _isListening
                                        ? 'Stop dictation'
                                        : 'Dictate',
                                    onPressed: _toggleDictation,
                                    style: IconButton.styleFrom(
                                      foregroundColor: _isListening
                                          ? theme.colorScheme.error
                                          : textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // AI Summary Panel Overlay
                  if (_aiSummary != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 80, // Elevated above bottom formatting bar
                      child: Card(
                        color: noteScheme.surfaceContainerHigh,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppLayout.radiusXXL),
                          side: BorderSide(
                            color: noteScheme.outlineVariant
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome,
                                      color: noteScheme.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Summary',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () =>
                                        setState(() => _aiSummary = null),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 120),
                                child: SingleChildScrollView(
                                  child: Text(
                                    _aiSummary!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                      color: noteScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Copy'),
                                    onPressed: () async {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      await HapticFeedback.lightImpact();
                                      await Clipboard.setData(
                                          ClipboardData(text: _aiSummary!));
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Summary copied to clipboard'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Append'),
                                    onPressed: () async {
                                      await HapticFeedback.lightImpact();
                                      final currentLength =
                                          _quillController.document.length;
                                      _quillController.replaceText(
                                        currentLength - 1,
                                        0,
                                        '\n\n=== AI SUMMARY ===\n${_aiSummary!.trim()}\n',
                                        null,
                                      );
                                      _onContentChanged();
                                      setState(() => _aiSummary = null);
                                    },
                                  ),
                                ],
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
        ),
      );
    });
  }
}

class RoundedImageEmbedBuilder extends EmbedBuilder {
  const RoundedImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final controller = embedContext.controller;

    final imageUrl = node.value.data;
    final isUrl = imageUrl.startsWith('http');
    final file = isUrl ? null : File(imageUrl);

    Widget imageWidget = isUrl
        ? Image.network(imageUrl,
            fit: BoxFit.cover, alignment: Alignment.topCenter)
        : Image.file(file!, fit: BoxFit.cover, alignment: Alignment.topCenter);

    return GestureDetector(
      onTap: () {
        // View Full Image
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _FullScreenImageViewer(
              imageProvider: isUrl
                  ? NetworkImage(imageUrl)
                  : FileImage(file!) as ImageProvider,
            ),
          ),
        );
      },
      onLongPress: () async {
        if (!embedContext.readOnly) {
          await HapticFeedback.mediumImpact();
          if (context.mounted) {
            _showImageActions(context, controller, node, imageUrl, isUrl, file);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: double.infinity, // Mobile friendly: use full width
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppLayout.radiusL),
          child: imageWidget,
        ),
      ),
    );
  }

  void _showImageActions(
      BuildContext context,
      QuillController controller,
      Embed node,
      String imageUrl,
      bool isUrl,
      File? file) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.fullscreen),
                title: const Text('View Full Image'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _FullScreenImageViewer(
                        imageProvider: isUrl
                            ? NetworkImage(imageUrl)
                            : FileImage(file!) as ImageProvider,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text('Remove Image',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  final offset = node.documentOffset;
                  controller.replaceText(offset, 1, '', null);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final ImageProvider imageProvider;
  const _FullScreenImageViewer({required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: InteractiveViewer(
        child: Center(
          child: Image(image: imageProvider),
        ),
      ),
    );
  }
}

class TableCellFocusNotification extends Notification {
  final bool isFocused;
  const TableCellFocusNotification(this.isFocused);
}

class TableEmbedBuilder extends EmbedBuilder {
  const TableEmbedBuilder();

  @override
  String get key => TableBlockEmbed.tableType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final controller = embedContext.controller;
    final readOnly = embedContext.readOnly;

    return TableWidget(
      node: node,
      rawData: node.value.data,
      controller: controller,
      readOnly: readOnly,
    );
  }
}

class TableWidget extends StatefulWidget {
  final Embed node;
  final String rawData;
  final QuillController controller;
  final bool readOnly;

  const TableWidget({
    super.key,
    required this.node,
    required this.rawData,
    required this.controller,
    required this.readOnly,
  });

  @override
  State<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  List<List<String>> _cells = [];
  List<List<TextEditingController>> _controllers = [];
  List<List<FocusNode>> _focusNodes = [];
  Timer? _debounce;

  static String _cleanText(String text) {
    return text
        .replaceAll('\uFFFC', '')
        .replaceAll('\uFFFD', '')
        .replaceAll('\uFEFF', '');
  }

  @override
  void initState() {
    super.initState();
    _parseData();
  }

  void _parseData() {
    try {
      final List<dynamic> outer = jsonDecode(widget.rawData);
      _cells = outer
          .map((r) => (r as List).map((c) => _cleanText(c.toString())).toList())
          .toList();
    } catch (e) {
      _cells = [
        ['Header 1', 'Header 2'],
        ['Cell 1', 'Cell 2']
      ];
    }
    _initControllers();
  }

  void _initControllers() {
    for (final row in _controllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final row in _focusNodes) {
      for (final node in row) {
        node.dispose();
      }
    }
    _controllers = _cells
        .map((row) => row
            .map((cellText) => TextEditingController(text: _cleanText(cellText)))
            .toList())
        .toList();
    _focusNodes = _cells
        .map((row) => row.map((_) {
              final node = FocusNode();
              node.addListener(() {
                if (!mounted) return;
                debugPrint("TABLE_CELL: node.hasFocus = ${node.hasFocus}");
                if (node.hasFocus) {
                  const TableCellFocusNotification(true).dispatch(context);
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final anyFocused =
                        _focusNodes.any((r) => r.any((n) => n.hasFocus));
                    debugPrint("TABLE_CELL: anyFocused = $anyFocused");
                    if (!anyFocused) {
                      const TableCellFocusNotification(false)
                          .dispatch(context);
                    }
                  });
                }
              });
              return node;
            }).toList())
        .toList();
  }

  @override
  void didUpdateWidget(covariant TableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawData != widget.rawData) {
      try {
        final List<dynamic> outer = jsonDecode(widget.rawData);
        final newCells = outer
            .map((r) => (r as List).map((c) => _cleanText(c.toString())).toList())
            .toList();
        if (!_areCellsEqual(_cells, newCells)) {
          _cells = newCells;
          _initControllers();
        }
      } catch (_) {}
    }
  }

  bool _areCellsEqual(List<List<String>> a, List<List<String>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].length != b[i].length) return false;
      for (int j = 0; j < a[i].length; j++) {
        if (a[i][j] != b[i][j]) return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final row in _controllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final row in _focusNodes) {
      for (final node in row) {
        node.dispose();
      }
    }
    super.dispose();
  }

  void _onCellChanged(int rowIndex, int colIndex, String text) {
    final cleaned = _cleanText(text);
    if (cleaned != text) {
      final controller = _controllers[rowIndex][colIndex];
      final currentSelection = controller.selection;
      final newOffset =
          currentSelection.baseOffset.clamp(0, cleaned.length);
      controller.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
    _cells[rowIndex][colIndex] = cleaned;
    _triggerSave();
  }

  void _triggerSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final cleanCells = _cells
          .map((r) => r.map((c) => _cleanText(c)).toList())
          .toList();
      final jsonStr = jsonEncode(cleanCells);
      final offset = widget.node.offset;
      widget.controller.replaceText(
        offset,
        1,
        TableBlockEmbed(jsonStr),
        null,
      );
    });
  }

  void _addRow() {
    setState(() {
      final colCount = _cells[0].length;
      _cells.add(List.generate(colCount, (_) => 'Cell'));
      _initControllers();
    });
    _triggerSave();
  }

  void _removeRow() {
    if (_cells.length <= 1) return;
    setState(() {
      _cells.removeLast();
      _initControllers();
    });
    _triggerSave();
  }

  void _addColumn() {
    setState(() {
      for (int i = 0; i < _cells.length; i++) {
        _cells[i].add(i == 0 ? 'Header ${_cells[i].length + 1}' : 'Cell');
      }
      _initControllers();
    });
    _triggerSave();
  }

  void _removeColumn() {
    if (_cells[0].length <= 1) return;
    setState(() {
      for (int i = 0; i < _cells.length; i++) {
        _cells[i].removeLast();
      }
      _initControllers();
    });
    _triggerSave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return TapRegion(
      onTapOutside: (event) {
        debugPrint("TABLE_CELL: onTapOutside triggered");
        for (final row in _focusNodes) {
          for (final node in row) {
            if (node.hasFocus) {
              debugPrint("TABLE_CELL: unfocusing node");
              node.unfocus();
            }
          }
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppLayout.radiusM),
                border: Border.all(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: borderColor),
                ),
                children: List.generate(_cells.length, (rIndex) {
                  final isHeader = rIndex == 0;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: isHeader
                          ? theme.colorScheme.surfaceContainerHigh
                          : (rIndex % 2 == 1
                              ? theme.colorScheme.surface
                              : theme.colorScheme.surfaceContainerLowest),
                    ),
                    children: List.generate(_cells[rIndex].length, (cIndex) {
                      return TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: TextField(
                            controller: _controllers[rIndex][cIndex],
                            focusNode: _focusNodes[rIndex][cIndex],
                            readOnly: widget.readOnly,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              fillColor: Colors.transparent,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            ),
                            onChanged: (text) => _onCellChanged(rIndex, cIndex, text),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
            if (!widget.readOnly)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppLayout.radiusL),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.playlist_add, size: 20),
                            tooltip: 'Add Row',
                            onPressed: _cells.length < 20 ? _addRow : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.playlist_remove, size: 20),
                            tooltip: 'Remove Row',
                            onPressed: _cells.length > 1 ? _removeRow : null,
                          ),
                          Container(
                            height: 16,
                            width: 1,
                            color: borderColor,
                          ),
                          IconButton(
                            icon: const Icon(Icons.view_column_outlined, size: 20),
                            tooltip: 'Add Column',
                            onPressed: _cells[0].length < 10 ? _addColumn : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.view_column, size: 20),
                            tooltip: 'Remove Column',
                            onPressed: _cells[0].length > 1 ? _removeColumn : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
