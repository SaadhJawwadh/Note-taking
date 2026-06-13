import 'package:flutter/material.dart';
import '../data/repositories/note_repository.dart';
import '../data/note_model.dart';

class NoteProvider extends ChangeNotifier {
  final NoteRepository _noteRepository = NoteRepository();
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _selectedTag = 'All';
  List<String> _allTags = ['All'];
  final Set<String> _selectedNoteIds = {};
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
      await _noteRepository.clearOldTrash();
      final tags = await _noteRepository.getAllTags();
      final colors = await _noteRepository.getAllTagColors();

      final fetchedNotes = await _noteRepository.readAllNotes(
        limit: _pageSize,
        offset: 0,
        tag: _selectedTag == 'All' || _selectedTag == 'Archived' || _selectedTag == 'Trash' ? null : _selectedTag,
        isArchived: _selectedTag == 'Archived',
        isTrashed: _selectedTag == 'Trash',
      );

      _allTags = ['All', ...tags];
      if (!_allTags.contains(_selectedTag)) {
        _selectedTag = 'All';
      }

      _tagColors = colors;
      _notes = fetchedNotes;
      _filteredNotes = List.from(_notes);
      
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

  void setTag(String tag) {
    _selectedTag = tag;
    refreshNotes();
  }

  Future<void> loadMoreNotes() async {
    if (_isLoadingMore || !_hasMoreNotes) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final moreNotes = await _noteRepository.readAllNotes(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        tag: _selectedTag == 'All' || _selectedTag == 'Archived' || _selectedTag == 'Trash' ? null : _selectedTag,
        isArchived: _selectedTag == 'Archived',
        isTrashed: _selectedTag == 'Trash',
      );

      if (moreNotes.length < _pageSize) {
        _hasMoreNotes = false;
      }

      // Avoid duplicates
      final existingIds = _notes.map((n) => n.id).toSet();
      final newNotes = moreNotes.where((n) => !existingIds.contains(n.id)).toList();
      
      _notes.addAll(newNotes);
      _filteredNotes = List.from(_notes);
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
    await _noteRepository.bulkArchive(_selectedNoteIds.toList(), true);
    clearSelection();
    await refreshNotes();
  }

  Future<void> bulkDelete() async {
    await _noteRepository.bulkDelete(_selectedNoteIds.toList());
    clearSelection();
    await refreshNotes();
  }

  Future<void> bulkTag(List<String> selectedTags) async {
    await _noteRepository.bulkTag(_selectedNoteIds.toList(), selectedTags);
    clearSelection();
    await refreshNotes();
  }

  // Tag Management
  Future<void> editTag(String oldTag, String newTag) async {
    if (newTag.isEmpty || newTag == oldTag || newTag.toLowerCase() == 'all') return;

    try {
      await _noteRepository.renameTag(oldTag, newTag);
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
      await _noteRepository.deleteTag(tag);
      if (_selectedTag == tag) {
        _selectedTag = 'All';
      }
      await refreshNotes();
    } catch (e) {
      debugPrint('Error deleting tag: $e');
    }
  }
}
