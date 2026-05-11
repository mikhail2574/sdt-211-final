import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/library_repository.dart';
import '../domain/book.dart';

enum LibraryStatus { initial, loading, loaded, failure }

class LibraryState {
  const LibraryState({
    required this.status,
    this.books = const [],
    this.downloadingBookIds = const {},
    this.query = '',
    this.filter = LibraryFilter.all,
    this.isOnline = true,
    this.pendingSyncCount = 0,
    this.ollamaEndpoint = 'http://127.0.0.1:11434/api/generate',
    this.ollamaModel = 'llama3.2:1b',
    this.isTestingOllama = false,
    this.ollamaMessage,
    this.errorMessage,
  });

  const LibraryState.initial() : this(status: LibraryStatus.initial);

  final LibraryStatus status;
  final List<Book> books;
  final Set<String> downloadingBookIds;
  final String query;
  final LibraryFilter filter;
  final bool isOnline;
  final int pendingSyncCount;
  final String ollamaEndpoint;
  final String ollamaModel;
  final bool isTestingOllama;
  final String? ollamaMessage;
  final String? errorMessage;

  List<Book> get visibleBooks {
    final normalized = query.trim().toLowerCase();
    return books
        .where((book) {
          final matchesQuery =
              normalized.isEmpty ||
              book.title.toLowerCase().contains(normalized) ||
              book.author.toLowerCase().contains(normalized) ||
              book.category.toLowerCase().contains(normalized);
          final matchesFilter = switch (filter) {
            LibraryFilter.all => true,
            LibraryFilter.downloaded => book.isDownloaded,
            LibraryFilter.inProgress => book.progress > 0 && book.progress < 1,
            LibraryFilter.unread => book.progress == 0,
          };
          return matchesQuery && matchesFilter;
        })
        .toList(growable: false);
  }

  LibraryState copyWith({
    LibraryStatus? status,
    List<Book>? books,
    Set<String>? downloadingBookIds,
    String? query,
    LibraryFilter? filter,
    bool? isOnline,
    int? pendingSyncCount,
    String? ollamaEndpoint,
    String? ollamaModel,
    bool? isTestingOllama,
    String? ollamaMessage,
    String? errorMessage,
  }) {
    return LibraryState(
      status: status ?? this.status,
      books: books ?? this.books,
      downloadingBookIds: downloadingBookIds ?? this.downloadingBookIds,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      ollamaEndpoint: ollamaEndpoint ?? this.ollamaEndpoint,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      isTestingOllama: isTestingOllama ?? this.isTestingOllama,
      ollamaMessage: ollamaMessage,
      errorMessage: errorMessage,
    );
  }
}

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repository) : super(const LibraryState.initial());

  final LibraryRepository _repository;

  Future<void> loadLibrary() async {
    emit(state.copyWith(status: LibraryStatus.loading));
    try {
      final books = await _repository.fetchPurchasedBooks();
      final pendingSyncCount = await _repository.pendingSyncCount;
      emit(
        state.copyWith(
          status: LibraryStatus.loaded,
          books: books,
          isOnline: _repository.isOnline,
          pendingSyncCount: pendingSyncCount,
          ollamaEndpoint: _repository.ollamaEndpoint,
          ollamaModel: _repository.ollamaModel,
        ),
      );
    } catch (error) {
      final pendingSyncCount = await _repository.pendingSyncCount;
      emit(
        state.copyWith(
          status: LibraryStatus.failure,
          isOnline: _repository.isOnline,
          pendingSyncCount: pendingSyncCount,
          ollamaEndpoint: _repository.ollamaEndpoint,
          ollamaModel: _repository.ollamaModel,
          errorMessage: '$error',
        ),
      );
    }
  }

  void search(String query) {
    emit(state.copyWith(query: query, errorMessage: null));
  }

  void changeFilter(LibraryFilter filter) {
    emit(state.copyWith(filter: filter, errorMessage: null));
  }

  Future<void> downloadBook(String bookId) async {
    emit(
      state.copyWith(
        downloadingBookIds: {...state.downloadingBookIds, bookId},
        errorMessage: null,
      ),
    );
    try {
      final downloaded = await _repository.downloadBook(bookId);
      final pendingSyncCount = await _repository.pendingSyncCount;
      final updated = state.books
          .map((book) {
            return book.id == bookId ? downloaded : book;
          })
          .toList(growable: false);
      emit(
        state.copyWith(
          status: LibraryStatus.loaded,
          books: updated,
          downloadingBookIds: {...state.downloadingBookIds}..remove(bookId),
          isOnline: _repository.isOnline,
          pendingSyncCount: pendingSyncCount,
          ollamaEndpoint: _repository.ollamaEndpoint,
          ollamaModel: _repository.ollamaModel,
        ),
      );
    } catch (error) {
      final pendingSyncCount = await _repository.pendingSyncCount;
      emit(
        state.copyWith(
          status: LibraryStatus.failure,
          downloadingBookIds: {...state.downloadingBookIds}..remove(bookId),
          isOnline: _repository.isOnline,
          pendingSyncCount: pendingSyncCount,
          ollamaEndpoint: _repository.ollamaEndpoint,
          ollamaModel: _repository.ollamaModel,
          errorMessage: '$error',
        ),
      );
    }
  }

  Future<void> setOnline(bool value) async {
    await _repository.setOnline(value);
    final pendingSyncCount = await _repository.pendingSyncCount;
    emit(
      state.copyWith(
        isOnline: _repository.isOnline,
        pendingSyncCount: pendingSyncCount,
        ollamaEndpoint: _repository.ollamaEndpoint,
        ollamaModel: _repository.ollamaModel,
      ),
    );
  }

  Future<int> syncPendingActions() async {
    final synced = await _repository.syncPendingActions();
    final pendingSyncCount = await _repository.pendingSyncCount;
    emit(
      state.copyWith(
        isOnline: _repository.isOnline,
        pendingSyncCount: pendingSyncCount,
        ollamaEndpoint: _repository.ollamaEndpoint,
        ollamaModel: _repository.ollamaModel,
      ),
    );
    return synced;
  }

  Future<void> updateOllamaSettings({
    required String endpoint,
    required String model,
  }) async {
    await _repository.updateOllamaSettings(endpoint: endpoint, model: model);
    emit(
      state.copyWith(
        ollamaEndpoint: _repository.ollamaEndpoint,
        ollamaModel: _repository.ollamaModel,
        ollamaMessage: 'Saved Ollama settings.',
      ),
    );
  }

  Future<void> testOllama() async {
    emit(state.copyWith(isTestingOllama: true, ollamaMessage: null));
    try {
      final response = await _repository.testOllama();
      emit(
        state.copyWith(
          isTestingOllama: false,
          ollamaMessage: 'Ollama responded: ${_compact(response)}',
        ),
      );
    } catch (error) {
      emit(state.copyWith(isTestingOllama: false, ollamaMessage: '$error'));
    }
  }

  Future<void> updateBookProgress(String bookId, double progress) async {
    final updated = state.books
        .map((book) {
          return book.id == bookId ? book.copyWith(progress: progress) : book;
        })
        .toList(growable: false);
    final pendingSyncCount = await _repository.pendingSyncCount;
    emit(state.copyWith(books: updated, pendingSyncCount: pendingSyncCount));
  }

  String _compact(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.length > 140
        ? '${normalized.substring(0, 140)}...'
        : normalized;
  }
}
