import 'dart:async';

import '../../library/data/pdf_book_parser.dart';
import '../../library/data/purchased_books_catalog.dart';
import '../../library/data/reader_backend_store.dart';
import '../../library/domain/book.dart';
import '../../reader/data/ollama_insight_client.dart';
import '../../reader/domain/reading_models.dart';
import '../domain/user.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MockInsightShelfApi {
  MockInsightShelfApi({
    PdfBookParser pdfBookParser = const PdfBookParser(),
    PurchasedBooksCatalog purchasedBooksCatalog = const PurchasedBooksCatalog(),
    ReaderBackendStore? backendStore,
    OllamaInsightClient? ollamaInsightClient,
  }) : _pdfBookParser = pdfBookParser,
       _purchasedBooksCatalog = purchasedBooksCatalog,
       _backendStore = backendStore ?? ReaderBackendStore(),
       _ollamaInsightClient = ollamaInsightClient ?? OllamaInsightClient();

  final PdfBookParser _pdfBookParser;
  final PurchasedBooksCatalog _purchasedBooksCatalog;
  final ReaderBackendStore _backendStore;
  final OllamaInsightClient _ollamaInsightClient;

  User? _session;
  bool _online = true;
  List<Book>? _catalog;
  final Map<String, Book> _parsedBooks = {};

  bool get isOnline => _online;
  String get ollamaEndpoint => _ollamaInsightClient.endpoint;
  String get ollamaModel => _ollamaInsightClient.model;

  Future<int> get pendingSyncCount async {
    final snapshot = await _backendStore.load();
    return snapshot.pendingSyncActions.length;
  }

  Future<User?> restoreSession() async {
    await _latency();
    return _session;
  }

  Future<User> login(String email, String password) async {
    await _latency();
    if (!email.contains('@') || password.length < 4) {
      throw const ApiException(
        'Enter a valid email and at least 4 characters.',
      );
    }
    _session = User(
      id: 'user-1',
      name: 'Alex Reader',
      email: email.trim(),
      token: 'local-session-${DateTime.now().millisecondsSinceEpoch}',
    );
    return _session!;
  }

  Future<void> logout() async {
    await _latency();
    _session = null;
  }

  Future<List<Book>> fetchPurchasedBooks() async {
    await _networkRequired();
    final catalog = await _loadCatalog();
    final snapshot = await _backendStore.load();

    return catalog
        .map(
          (book) => book.copyWith(
            isDownloaded: snapshot.downloadedBookIds.contains(book.id),
            progress: snapshot.progress[book.id]?.percent ?? book.progress,
          ),
        )
        .toList(growable: false);
  }

  Future<Book> downloadBook(String bookId) async {
    await _networkRequired(milliseconds: 650);
    final parsed = await _parsedBook(bookId);
    final snapshot = await _backendStore.load();
    final downloadedBookIds = {...snapshot.downloadedBookIds, bookId};
    await _backendStore.save(
      snapshot.copyWith(downloadedBookIds: downloadedBookIds),
    );
    return parsed.copyWith(
      isDownloaded: true,
      progress: snapshot.progress[bookId]?.percent,
    );
  }

  Future<void> saveProgress(ReadingProgress progress) async {
    await _latency(milliseconds: 80);
    final snapshot = await _backendStore.load();
    await _backendStore.save(
      snapshot.copyWith(
        progress: {...snapshot.progress, progress.bookId: progress},
        pendingSyncActions: _queued(
          snapshot,
          'Progress for ${progress.bookId}',
        ),
      ),
    );
  }

  Future<void> saveBookmark(Bookmark bookmark) async {
    await _latency(milliseconds: 80);
    final snapshot = await _backendStore.load();
    final items = List<Bookmark>.from(
      snapshot.bookmarks[bookmark.bookId] ?? [],
    );
    items.removeWhere((item) => item.id == bookmark.id);
    items.add(bookmark);
    await _backendStore.save(
      snapshot.copyWith(
        bookmarks: {...snapshot.bookmarks, bookmark.bookId: items},
        pendingSyncActions: _queued(snapshot, 'Bookmark ${bookmark.id}'),
      ),
    );
  }

  Future<void> deleteBookmark(String bookId, String bookmarkId) async {
    await _latency(milliseconds: 80);
    final snapshot = await _backendStore.load();
    final items = (snapshot.bookmarks[bookId] ?? [])
        .where((item) => item.id != bookmarkId)
        .toList();
    await _backendStore.save(
      snapshot.copyWith(
        bookmarks: {...snapshot.bookmarks, bookId: items},
        pendingSyncActions: _queued(snapshot, 'Delete bookmark $bookmarkId'),
      ),
    );
  }

  Future<void> saveHighlight(Highlight highlight) async {
    await _latency(milliseconds: 80);
    final snapshot = await _backendStore.load();
    final items = List<Highlight>.from(
      snapshot.highlights[highlight.bookId] ?? [],
    );
    items.add(highlight);
    await _backendStore.save(
      snapshot.copyWith(
        highlights: {...snapshot.highlights, highlight.bookId: items},
        pendingSyncActions: _queued(snapshot, 'Highlight ${highlight.id}'),
      ),
    );
  }

  Future<void> deleteHighlight(String bookId, String highlightId) async {
    await _latency(milliseconds: 80);
    final snapshot = await _backendStore.load();
    final items = (snapshot.highlights[bookId] ?? [])
        .where((item) => item.id != highlightId)
        .toList();
    await _backendStore.save(
      snapshot.copyWith(
        highlights: {...snapshot.highlights, bookId: items},
        pendingSyncActions: _queued(snapshot, 'Delete highlight $highlightId'),
      ),
    );
  }

  Future<void> saveNote(Note note) async {
    await _latency(milliseconds: 80);
    final snapshot = await _backendStore.load();
    final items = List<Note>.from(snapshot.notes[note.bookId] ?? []);
    items.removeWhere((item) => item.id == note.id);
    items.add(note);
    await _backendStore.save(
      snapshot.copyWith(
        notes: {...snapshot.notes, note.bookId: items},
        pendingSyncActions: _queued(snapshot, 'Note ${note.id}'),
      ),
    );
  }

  Future<void> deleteNote(String bookId, String noteId) async {
    await _latency(milliseconds: 80);
    final snapshot = await _backendStore.load();
    final items = (snapshot.notes[bookId] ?? [])
        .where((item) => item.id != noteId)
        .toList();
    await _backendStore.save(
      snapshot.copyWith(
        notes: {...snapshot.notes, bookId: items},
        pendingSyncActions: _queued(snapshot, 'Delete note $noteId'),
      ),
    );
  }

  Future<ReaderPayload> loadReaderPayload(String bookId) async {
    await _latency(milliseconds: 140);
    final snapshot = await _backendStore.load();
    final book = (await _parsedBook(bookId)).copyWith(
      isDownloaded: snapshot.downloadedBookIds.contains(bookId),
      progress: snapshot.progress[bookId]?.percent,
    );
    if (!_online && !book.isDownloaded) {
      throw const ApiException(
        'This book is not downloaded for offline reading.',
      );
    }

    return ReaderPayload(
      book: book,
      progress: snapshot.progress[bookId],
      bookmarks: List.unmodifiable(snapshot.bookmarks[bookId] ?? []),
      highlights: List.unmodifiable(snapshot.highlights[bookId] ?? []),
      notes: List.unmodifiable(snapshot.notes[bookId] ?? []),
      insights: List.unmodifiable(snapshot.insights[bookId] ?? []),
    );
  }

  Future<InsightCard> generateInsight({
    required String bookId,
    required int chapterIndex,
    required String selectedText,
    required InsightType type,
  }) async {
    final card = await _ollamaInsightClient.generate(
      bookId: bookId,
      chapterIndex: chapterIndex,
      selectedText: selectedText,
      type: type,
    );
    final snapshot = await _backendStore.load();
    final items = List<InsightCard>.from(snapshot.insights[bookId] ?? [])
      ..insert(0, card);
    await _backendStore.save(
      snapshot.copyWith(insights: {...snapshot.insights, bookId: items}),
    );
    return card;
  }

  Future<void> setOnline(bool value) async {
    await _latency(milliseconds: 80);
    _online = value;
  }

  Future<int> syncPendingActions() async {
    await _networkRequired(milliseconds: 500);
    final snapshot = await _backendStore.load();
    final synced = snapshot.pendingSyncActions.length;
    await _backendStore.save(snapshot.copyWith(pendingSyncActions: []));
    return synced;
  }

  Future<void> updateOllamaSettings({
    required String endpoint,
    required String model,
  }) async {
    await _latency(milliseconds: 80);
    _ollamaInsightClient.endpoint = endpoint.trim();
    _ollamaInsightClient.model = model.trim();
  }

  Future<String> testOllama() async {
    final insight = await _ollamaInsightClient.generate(
      bookId: 'healthcheck',
      chapterIndex: 0,
      selectedText:
          'Software architecture turns quality goals into design decisions.',
      type: InsightType.simpleExplanation,
    );
    return insight.body;
  }

  Future<Book> _parsedBook(String bookId) async {
    final cached = _parsedBooks[bookId];
    if (cached != null) {
      return cached;
    }

    final catalog = await _loadCatalog();
    final book = catalog.firstWhere((item) => item.id == bookId);
    final assetPath = book.assetPath;
    if (assetPath == null) {
      return book;
    }

    final chapters = await _pdfBookParser.parseAsset(assetPath);
    final parsed = book.copyWith(chapters: chapters);
    _parsedBooks[bookId] = parsed;
    return parsed;
  }

  Future<List<Book>> _loadCatalog() async {
    final cached = _catalog;
    if (cached != null) {
      return cached;
    }
    _catalog = await _purchasedBooksCatalog.loadPurchasedBooks();
    return _catalog!;
  }

  List<String> _queued(BackendSnapshot snapshot, String action) {
    if (_online) {
      return snapshot.pendingSyncActions;
    }
    return [...snapshot.pendingSyncActions, action];
  }

  Future<void> _networkRequired({int milliseconds = 380}) async {
    await _latency(milliseconds: milliseconds);
    if (!_online) {
      throw const ApiException(
        'No connection. Downloaded books remain available.',
      );
    }
  }

  Future<void> _latency({int milliseconds = 220}) {
    return Future<void>.delayed(Duration(milliseconds: milliseconds));
  }
}

class ReaderPayload {
  const ReaderPayload({
    required this.book,
    required this.progress,
    required this.bookmarks,
    required this.highlights,
    required this.notes,
    required this.insights,
  });

  final Book book;
  final ReadingProgress? progress;
  final List<Bookmark> bookmarks;
  final List<Highlight> highlights;
  final List<Note> notes;
  final List<InsightCard> insights;
}
