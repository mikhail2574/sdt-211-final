import 'dart:async';

import '../../library/domain/book.dart';
import '../../reader/domain/reading_models.dart';
import '../domain/user.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MockInsightShelfApi {
  MockInsightShelfApi();

  User? _session;
  bool _online = true;
  final Set<String> _downloadedBookIds = {};
  final Map<String, ReadingProgress> _progress = {};
  final Map<String, List<Bookmark>> _bookmarks = {};
  final Map<String, List<Highlight>> _highlights = {};
  final Map<String, List<Note>> _notes = {};
  final Map<String, List<InsightCard>> _insights = {};
  final List<String> _pendingSyncActions = [];

  bool get isOnline => _online;
  int get pendingSyncCount => _pendingSyncActions.length;

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
      token: 'mock-token-${DateTime.now().millisecondsSinceEpoch}',
    );
    return _session!;
  }

  Future<void> logout() async {
    await _latency();
    _session = null;
  }

  Future<List<Book>> fetchPurchasedBooks() async {
    await _networkRequired();
    return _books
        .map(
          (book) => book.copyWith(
            isDownloaded: _downloadedBookIds.contains(book.id),
            progress: _progress[book.id]?.percent ?? book.progress,
          ),
        )
        .toList(growable: false);
  }

  Future<Book> downloadBook(String bookId) async {
    await _networkRequired(milliseconds: 650);
    _downloadedBookIds.add(bookId);
    return _books
        .firstWhere((book) => book.id == bookId)
        .copyWith(isDownloaded: true, progress: _progress[bookId]?.percent);
  }

  Future<void> saveProgress(ReadingProgress progress) async {
    await _latency(milliseconds: 160);
    _progress[progress.bookId] = progress;
    _queueIfOffline('Progress for ${progress.bookId}');
  }

  Future<void> saveBookmark(Bookmark bookmark) async {
    await _latency(milliseconds: 120);
    final items = List<Bookmark>.from(_bookmarks[bookmark.bookId] ?? []);
    items.removeWhere((item) => item.id == bookmark.id);
    items.add(bookmark);
    _bookmarks[bookmark.bookId] = items;
    _queueIfOffline('Bookmark ${bookmark.id}');
  }

  Future<void> deleteBookmark(String bookId, String bookmarkId) async {
    await _latency(milliseconds: 120);
    _bookmarks[bookId] = (_bookmarks[bookId] ?? [])
        .where((item) => item.id != bookmarkId)
        .toList();
    _queueIfOffline('Delete bookmark $bookmarkId');
  }

  Future<void> saveHighlight(Highlight highlight) async {
    await _latency(milliseconds: 120);
    final items = List<Highlight>.from(_highlights[highlight.bookId] ?? []);
    items.add(highlight);
    _highlights[highlight.bookId] = items;
    _queueIfOffline('Highlight ${highlight.id}');
  }

  Future<void> deleteHighlight(String bookId, String highlightId) async {
    await _latency(milliseconds: 120);
    _highlights[bookId] = (_highlights[bookId] ?? [])
        .where((item) => item.id != highlightId)
        .toList();
    _queueIfOffline('Delete highlight $highlightId');
  }

  Future<void> saveNote(Note note) async {
    await _latency(milliseconds: 120);
    final items = List<Note>.from(_notes[note.bookId] ?? []);
    items.removeWhere((item) => item.id == note.id);
    items.add(note);
    _notes[note.bookId] = items;
    _queueIfOffline('Note ${note.id}');
  }

  Future<void> deleteNote(String bookId, String noteId) async {
    await _latency(milliseconds: 120);
    _notes[bookId] = (_notes[bookId] ?? [])
        .where((item) => item.id != noteId)
        .toList();
    _queueIfOffline('Delete note $noteId');
  }

  Future<ReaderPayload> loadReaderPayload(String bookId) async {
    await _latency(milliseconds: 250);
    final book = _books
        .firstWhere((item) => item.id == bookId)
        .copyWith(
          isDownloaded: _downloadedBookIds.contains(bookId),
          progress: _progress[bookId]?.percent,
        );
    if (!_online && !book.isDownloaded) {
      throw const ApiException(
        'This book is not downloaded for offline reading.',
      );
    }

    return ReaderPayload(
      book: book,
      progress: _progress[bookId],
      bookmarks: List.unmodifiable(_bookmarks[bookId] ?? []),
      highlights: List.unmodifiable(_highlights[bookId] ?? []),
      notes: List.unmodifiable(_notes[bookId] ?? []),
      insights: List.unmodifiable(_insights[bookId] ?? []),
    );
  }

  Future<InsightCard> generateInsight({
    required String bookId,
    required int chapterIndex,
    required String selectedText,
    required InsightType type,
  }) async {
    await _networkRequired(milliseconds: 900);
    final card = InsightCard(
      id: 'insight-${DateTime.now().microsecondsSinceEpoch}',
      bookId: bookId,
      chapterIndex: chapterIndex,
      type: type,
      title: _titleFor(type),
      body: _bodyFor(type, selectedText),
      points: _pointsFor(type),
    );
    final items = List<InsightCard>.from(_insights[bookId] ?? [])
      ..insert(0, card);
    _insights[bookId] = items;
    return card;
  }

  Future<void> setOnline(bool value) async {
    await _latency(milliseconds: 120);
    _online = value;
  }

  Future<int> syncPendingActions() async {
    await _networkRequired(milliseconds: 700);
    final synced = _pendingSyncActions.length;
    _pendingSyncActions.clear();
    return synced;
  }

  void _queueIfOffline(String action) {
    if (!_online) {
      _pendingSyncActions.add(action);
    }
  }

  Future<void> _networkRequired({int milliseconds = 380}) async {
    await _latency(milliseconds: milliseconds);
    if (!_online) {
      throw const ApiException(
        'No connection. Downloaded books remain available.',
      );
    }
  }

  Future<void> _latency({int milliseconds = 300}) {
    return Future<void>.delayed(Duration(milliseconds: milliseconds));
  }

  String _titleFor(InsightType type) {
    switch (type) {
      case InsightType.summary:
        return 'Section Summary';
      case InsightType.visual:
        return 'Visual Framework';
      case InsightType.example:
        return 'Practical Example';
      case InsightType.actionSteps:
        return 'Action Steps';
      case InsightType.simpleExplanation:
        return 'Simpler Explanation';
    }
  }

  String _bodyFor(InsightType type, String text) {
    final compact = text.length > 130 ? '${text.substring(0, 130)}...' : text;
    switch (type) {
      case InsightType.summary:
        return 'A concise explanation of: "$compact"';
      case InsightType.visual:
        return 'A three-part concept card connecting the main idea, driver, and result.';
      case InsightType.example:
        return 'A real-world business scenario showing how this idea changes a decision.';
      case InsightType.actionSteps:
        return 'A short checklist that turns the passage into something the reader can do.';
      case InsightType.simpleExplanation:
        return 'The same idea rewritten in plain language for faster comprehension.';
    }
  }

  List<String> _pointsFor(InsightType type) {
    switch (type) {
      case InsightType.summary:
        return [
          'Identify the claim',
          'Find the supporting reason',
          'Connect it to the chapter goal',
        ];
      case InsightType.visual:
        return ['Input', 'Process', 'Outcome'];
      case InsightType.example:
        return ['Team context', 'Decision pressure', 'Measurable result'];
      case InsightType.actionSteps:
        return ['Write the next action', 'Set a deadline', 'Review the result'];
      case InsightType.simpleExplanation:
        return ['Plain words', 'One example', 'One takeaway'];
    }
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

final List<Book> _books = [
  Book(
    id: 'book-systems',
    title: 'Systems for Focus',
    author: 'Mira Dalton',
    description:
        'A practical guide to building durable attention systems for study, product work, and business leadership.',
    category: 'Productivity',
    format: BookFormat.epub,
    coverColor: 0xFF176B87,
    progress: 0.36,
    chapters: const [
      BookChapter(
        title: 'Design the Environment',
        paragraphs: [
          'Attention improves when the environment removes decisions before willpower is required. A good system makes the desired behavior the easiest behavior.',
          'The strongest routines are not dramatic. They are quiet defaults: the prepared desk, the blocked calendar, the visible next step, and the closed loop for unfinished work.',
          'When teams design focus together, they reduce coordination tax. Fewer status meetings and clearer written updates create more space for deep work.',
        ],
      ),
      BookChapter(
        title: 'Measure the Useful Signal',
        paragraphs: [
          'A metric should explain whether the system is working, not merely whether people are busy. Output, recovery, and learning rate matter more than hours alone.',
          'Review cycles protect the system from becoming stale. Every Friday, remove one friction point and keep one practice that produced visible progress.',
        ],
      ),
      BookChapter(
        title: 'Keep the Loop Small',
        paragraphs: [
          'Small feedback loops create confidence. A reader, student, or founder can adjust quickly when the next review is close and the cost of change is low.',
          'The goal is not constant productivity. The goal is a dependable rhythm that creates room for hard thinking and healthy recovery.',
        ],
      ),
    ],
  ),
  Book(
    id: 'book-market',
    title: 'Market Maps',
    author: 'Jon Bell',
    description:
        'A concise non-fiction book about understanding customers, competitors, and positioning through visual market models.',
    category: 'Business',
    format: BookFormat.pdf,
    coverColor: 0xFFE17A47,
    progress: 0.12,
    chapters: const [
      BookChapter(
        title: 'Customer Gravity',
        paragraphs: [
          'Customers move toward products that reduce a painful job better than their current workaround. Mapping gravity means finding what already pulls their attention.',
          'A useful market map separates loud competitors from meaningful alternatives. The strongest alternative is often a spreadsheet, a chat thread, or a manual process.',
        ],
      ),
      BookChapter(
        title: 'Positioning Choices',
        paragraphs: [
          'Positioning is a tradeoff. A product cannot be fastest, deepest, cheapest, and most flexible for every buyer at the same time.',
          'Good positioning narrows the promise until the right customer can repeat it clearly to another person.',
        ],
      ),
    ],
  ),
  Book(
    id: 'book-learning',
    title: 'Learning That Sticks',
    author: 'Nadia Chen',
    description:
        'An education-focused reader on notes, memory, spaced repetition, and reflection habits for long-term knowledge retention.',
    category: 'Education',
    format: BookFormat.epub,
    coverColor: 0xFF5D7A3A,
    chapters: const [
      BookChapter(
        title: 'Make Recall Visible',
        paragraphs: [
          'Learning feels smooth during rereading, but durable memory appears during recall. The learner needs a way to see what can be produced without the page.',
          'Notes should become prompts, not archives. A good note asks a future question and leaves enough context to rebuild the answer.',
        ],
      ),
      BookChapter(
        title: 'Reflect and Reconnect',
        paragraphs: [
          'Reflection links new information to decisions, examples, and previous knowledge. Without reflection, highlights become decoration.',
          'The best study systems are lightweight enough to survive busy weeks and structured enough to create compounding value.',
        ],
      ),
    ],
  ),
];
