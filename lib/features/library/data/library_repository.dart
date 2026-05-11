import '../../auth/data/local_insight_shelf_backend.dart';
import '../../library/domain/book.dart';
import '../../reader/domain/reading_models.dart';

class LibraryRepository {
  const LibraryRepository(this._api);

  final LocalInsightShelfBackend _api;

  bool get isOnline => _api.isOnline;
  Future<int> get pendingSyncCount => _api.pendingSyncCount;
  String get ollamaEndpoint => _api.ollamaEndpoint;
  String get ollamaModel => _api.ollamaModel;

  Future<List<Book>> fetchPurchasedBooks() => _api.fetchPurchasedBooks();

  Future<Book> downloadBook(String bookId) => _api.downloadBook(bookId);

  Future<ReaderPayload> loadReaderPayload(String bookId) {
    return _api.loadReaderPayload(bookId);
  }

  Future<void> saveProgress(ReadingProgress progress) {
    return _api.saveProgress(progress);
  }

  Future<void> saveBookmark(Bookmark bookmark) => _api.saveBookmark(bookmark);

  Future<void> deleteBookmark(String bookId, String bookmarkId) {
    return _api.deleteBookmark(bookId, bookmarkId);
  }

  Future<void> saveHighlight(Highlight highlight) =>
      _api.saveHighlight(highlight);

  Future<void> deleteHighlight(String bookId, String highlightId) {
    return _api.deleteHighlight(bookId, highlightId);
  }

  Future<void> saveNote(Note note) => _api.saveNote(note);

  Future<void> deleteNote(String bookId, String noteId) {
    return _api.deleteNote(bookId, noteId);
  }

  Future<InsightCard> generateInsight({
    required String bookId,
    required int chapterIndex,
    required String selectedText,
    required InsightType type,
  }) {
    return _api.generateInsight(
      bookId: bookId,
      chapterIndex: chapterIndex,
      selectedText: selectedText,
      type: type,
    );
  }

  Future<void> setOnline(bool value) => _api.setOnline(value);

  Future<int> syncPendingActions() => _api.syncPendingActions();

  Future<void> updateOllamaSettings({
    required String endpoint,
    required String model,
  }) {
    return _api.updateOllamaSettings(endpoint: endpoint, model: model);
  }

  Future<String> testOllama() => _api.testOllama();
}
