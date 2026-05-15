import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/note_model.dart';

class NoteProvider extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _selectedTag = 'All';
  List<String> _allTags = ['All'];
  Set<String> _selectedNoteIds = {};
  bool _isSelectionMode = false;
  Map<String, int> _tagColors = {};

  final int _pageSize = 20;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreNotes = true;

  // Getters
  List<Note> get notes => _notes;
  List<Note> get filteredNotes => _filteredNotes;
  bool get isLoading => _isLoading;
  String get selectedTag => _selectedTag;
  List<String> get allTags => _allTags;
  Set<String> get selectedNoteIds => _selectedNoteIds;
  bool get isSelectionMode => _isSelectionMode;
  Map<String, int> get tagColors => _tagColors;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreNotes => _hasMoreNotes;

  NoteProvider() {
    refreshNotes();
  }

  Future<void> refreshNotes() async {
    _isLoading = true;
    _currentPage = 0;
    _hasMoreNotes = true;
    notifyListeners();

    try {
      final tags = await DatabaseHelper.instance.getAllTags();
      final colors = await DatabaseHelper.instance.getAllTagColors();

      final fetchedNotes = await DatabaseHelper.instance.readAllNotes(
        limit: _pageSize,
        offset: 0,
      );

      _allTags = ['All', ...tags];
      if (!_allTags.contains(_selectedTag)) {
        _selectedTag = 'All';
      }

      _tagColors = colors;
      _notes = fetchedNotes;
      _filterNotes();
      
      _isLoading = false;
      if (fetchedNotes.length < _pageSize) {
        _hasMoreNotes = false;
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error refreshing notes: $e');
    }
  }

  void _filterNotes() {
    if (_selectedTag == 'All') {
      _filteredNotes = _notes.where((n) => !n.isArchived && n.deletedAt == null).toList();
    } else if (_selectedTag == 'Archived') {
      _filteredNotes = _notes.where((n) => n.isArchived && n.deletedAt == null).toList();
    } else if (_selectedTag == 'Trash') {
      _filteredNotes = _notes.where((n) => n.deletedAt != null).toList();
    } else {
      _filteredNotes = _notes
          .where((note) =>
              note.tags.contains(_selectedTag) &&
              !note.isArchived &&
              note.deletedAt == null)
          .toList();
    }
    
    _filteredNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.dateModified.compareTo(a.dateModified);
    });
  }

  void setTag(String tag) {
    _selectedTag = tag;
    _filterNotes();
    notifyListeners();
  }

  Future<void> loadMoreNotes() async {
    if (_isLoadingMore || !_hasMoreNotes) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final moreNotes = await DatabaseHelper.instance.readAllNotes(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (moreNotes.length < _pageSize) {
        _hasMoreNotes = false;
      }

      // Avoid duplicates
      final existingIds = _notes.map((n) => n.id).toSet();
      final newNotes = moreNotes.where((n) => !existingIds.contains(n.id)).toList();
      
      _notes.addAll(newNotes);
      _filterNotes();
    } catch (e) {
      debugPrint('Error loading more notes: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Selection Logic
  void toggleSelection(String id) {
    if (_selectedNoteIds.contains(id)) {
      _selectedNoteIds.remove(id);
    } else {
      _selectedNoteIds.add(id);
    }
    _isSelectionMode = _selectedNoteIds.isNotEmpty;
    notifyListeners();
  }

  void clearSelection() {
    _selectedNoteIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  // Bulk Actions
  Future<void> bulkArchive() async {
    for (String id in _selectedNoteIds) {
      final noteIndex = _notes.indexWhere((n) => n.id == id);
      if (noteIndex != -1) {
        final note = _notes[noteIndex];
        final updatedNote = note.copyWith(isArchived: true);
        await DatabaseHelper.instance.updateNote(updatedNote);
      }
    }
    clearSelection();
    await refreshNotes();
  }

  Future<void> bulkDelete() async {
    for (String id in _selectedNoteIds) {
      final noteIndex = _notes.indexWhere((n) => n.id == id);
      if (noteIndex != -1) {
        final note = _notes[noteIndex];
        final updatedNote = note.copyWith(deletedAt: DateTime.now());
        await DatabaseHelper.instance.updateNote(updatedNote);
      }
    }
    clearSelection();
    await refreshNotes();
  }

  Future<void> bulkTag(List<String> selectedTags) async {
    for (String id in _selectedNoteIds) {
      final noteIndex = _notes.indexWhere((n) => n.id == id);
      if (noteIndex != -1) {
        final note = _notes[noteIndex];
        Set<String> mergedTags = {...note.tags, ...selectedTags};
        final updatedNote = note.copyWith(tags: mergedTags.toList());
        await DatabaseHelper.instance.updateNote(updatedNote);
      }
    }
    clearSelection();
    await refreshNotes();
  }

  // Tag Management
  Future<void> editTag(String oldTag, String newTag) async {
    if (newTag.isEmpty || newTag == oldTag || newTag.toLowerCase() == 'all') return;

    try {
      await DatabaseHelper.instance.renameTag(oldTag, newTag);
      if (_selectedTag == oldTag) {
        _selectedTag = newTag;
      }
      await refreshNotes();
    } catch (e) {
      debugPrint('Error renaming tag: $e');
    }
  }

  Future<void> deleteTag(String tag) async {
    try {
      await DatabaseHelper.instance.deleteTag(tag);
      if (_selectedTag == tag) {
        _selectedTag = 'All';
      }
      await refreshNotes();
    } catch (e) {
      debugPrint('Error deleting tag: $e');
    }
  }
}
