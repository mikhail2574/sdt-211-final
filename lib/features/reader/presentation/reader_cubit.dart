import 'package:flutter_bloc/flutter_bloc.dart';

import '../../library/data/library_repository.dart';
import '../../library/domain/book.dart';
import '../domain/reading_models.dart';

enum ReaderStatus { initial, loading, loaded, failure }

class ReaderState {
  const ReaderState({
    required this.status,
    this.book,
    this.chapterIndex = 0,
    this.preferences = const ReadingPreferences(),
    this.bookmarks = const [],
    this.highlights = const [],
    this.notes = const [],
    this.insights = const [],
    this.searchQuery = '',
    this.isGeneratingInsight = false,
    this.errorMessage,
  });

  const ReaderState.initial() : this(status: ReaderStatus.initial);

  final ReaderStatus status;
  final Book? book;
  final int chapterIndex;
  final ReadingPreferences preferences;
  final List<Bookmark> bookmarks;
  final List<Highlight> highlights;
  final List<Note> notes;
  final List<InsightCard> insights;
  final String searchQuery;
  final bool isGeneratingInsight;
  final String? errorMessage;

  BookChapter? get chapter => book?.chapters[chapterIndex];

  List<String> get searchResults {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty || book == null) {
      return const [];
    }
    return book!.chapters
        .expand((chapter) => chapter.paragraphs)
        .where((paragraph) => paragraph.toLowerCase().contains(query))
        .toList(growable: false);
  }

  ReaderState copyWith({
    ReaderStatus? status,
    Book? book,
    int? chapterIndex,
    ReadingPreferences? preferences,
    List<Bookmark>? bookmarks,
    List<Highlight>? highlights,
    List<Note>? notes,
    List<InsightCard>? insights,
    String? searchQuery,
    bool? isGeneratingInsight,
    String? errorMessage,
  }) {
    return ReaderState(
      status: status ?? this.status,
      book: book ?? this.book,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      preferences: preferences ?? this.preferences,
      bookmarks: bookmarks ?? this.bookmarks,
      highlights: highlights ?? this.highlights,
      notes: notes ?? this.notes,
      insights: insights ?? this.insights,
      searchQuery: searchQuery ?? this.searchQuery,
      isGeneratingInsight: isGeneratingInsight ?? this.isGeneratingInsight,
      errorMessage: errorMessage,
    );
  }
}

class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit(this._repository) : super(const ReaderState.initial());

  final LibraryRepository _repository;

  Future<void> loadBook(String bookId) async {
    emit(const ReaderState(status: ReaderStatus.loading));
    try {
      final payload = await _repository.loadReaderPayload(bookId);
      emit(
        ReaderState(
          status: ReaderStatus.loaded,
          book: payload.book,
          chapterIndex: payload.progress?.chapterIndex ?? 0,
          bookmarks: payload.bookmarks,
          highlights: payload.highlights,
          notes: payload.notes,
          insights: payload.insights,
        ),
      );
    } catch (error) {
      emit(ReaderState(status: ReaderStatus.failure, errorMessage: '$error'));
    }
  }

  Future<void> changeChapter(int chapterIndex) async {
    final book = state.book;
    if (book == null ||
        chapterIndex < 0 ||
        chapterIndex >= book.chapters.length) {
      return;
    }
    final percent = (chapterIndex + 1) / book.chapters.length;
    emit(
      state.copyWith(
        chapterIndex: chapterIndex,
        book: book.copyWith(progress: percent),
        errorMessage: null,
      ),
    );
    await _repository.saveProgress(
      ReadingProgress(
        bookId: book.id,
        chapterIndex: chapterIndex,
        percent: percent,
      ),
    );
  }

  Future<void> addBookmark() async {
    final book = state.book;
    final chapter = state.chapter;
    if (book == null || chapter == null) {
      return;
    }
    final bookmark = Bookmark(
      id: 'bookmark-${DateTime.now().microsecondsSinceEpoch}',
      bookId: book.id,
      chapterIndex: state.chapterIndex,
      label: chapter.title,
    );
    final updated = [...state.bookmarks, bookmark];
    emit(state.copyWith(bookmarks: updated));
    await _repository.saveBookmark(bookmark);
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    final book = state.book;
    if (book == null) {
      return;
    }
    final updated = state.bookmarks
        .where((item) => item.id != bookmarkId)
        .toList();
    emit(state.copyWith(bookmarks: updated));
    await _repository.deleteBookmark(book.id, bookmarkId);
  }

  Future<void> addHighlight(String text) async {
    final book = state.book;
    if (book == null || text.trim().isEmpty) {
      return;
    }
    final highlight = Highlight(
      id: 'highlight-${DateTime.now().microsecondsSinceEpoch}',
      bookId: book.id,
      chapterIndex: state.chapterIndex,
      text: text.trim(),
    );
    emit(state.copyWith(highlights: [highlight, ...state.highlights]));
    await _repository.saveHighlight(highlight);
  }

  Future<void> deleteHighlight(String highlightId) async {
    final book = state.book;
    if (book == null) {
      return;
    }
    final updated = state.highlights
        .where((item) => item.id != highlightId)
        .toList();
    emit(state.copyWith(highlights: updated));
    await _repository.deleteHighlight(book.id, highlightId);
  }

  Future<void> saveNote({
    String? noteId,
    required String text,
    required String body,
  }) async {
    final book = state.book;
    if (book == null || body.trim().isEmpty) {
      return;
    }
    final note = Note(
      id: noteId ?? 'note-${DateTime.now().microsecondsSinceEpoch}',
      bookId: book.id,
      chapterIndex: state.chapterIndex,
      text: text.trim().isEmpty
          ? state.chapter?.title ?? 'Chapter note'
          : text.trim(),
      body: body.trim(),
    );
    final updated = [note, ...state.notes.where((item) => item.id != note.id)];
    emit(state.copyWith(notes: updated));
    await _repository.saveNote(note);
  }

  Future<void> deleteNote(String noteId) async {
    final book = state.book;
    if (book == null) {
      return;
    }
    final updated = state.notes.where((item) => item.id != noteId).toList();
    emit(state.copyWith(notes: updated));
    await _repository.deleteNote(book.id, noteId);
  }

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void updatePreferences(ReadingPreferences preferences) {
    emit(state.copyWith(preferences: preferences));
  }

  Future<void> generateInsight(String selectedText, InsightType type) async {
    final book = state.book;
    if (book == null ||
        selectedText.trim().isEmpty ||
        !state.preferences.aiEnabled) {
      return;
    }
    emit(state.copyWith(isGeneratingInsight: true, errorMessage: null));
    try {
      final insight = await _repository.generateInsight(
        bookId: book.id,
        chapterIndex: state.chapterIndex,
        selectedText: selectedText.trim(),
        type: type,
      );
      emit(
        state.copyWith(
          insights: [insight, ...state.insights],
          isGeneratingInsight: false,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isGeneratingInsight: false, errorMessage: '$error'));
    }
  }
}
