import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/library_repository.dart';
import '../domain/book.dart';

enum LibraryStatus { initial, loading, loaded, failure }

class LibraryState {
  const LibraryState({
    required this.status,
    this.books = const [],
    this.query = '',
    this.filter = LibraryFilter.all,
    this.isOnline = true,
    this.pendingSyncCount = 0,
    this.errorMessage,
  });

  const LibraryState.initial() : this(status: LibraryStatus.initial);

  final LibraryStatus status;
  final List<Book> books;
  final String query;
  final LibraryFilter filter;
  final bool isOnline;
  final int pendingSyncCount;
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
    String? query,
    LibraryFilter? filter,
    bool? isOnline,
    int? pendingSyncCount,
    String? errorMessage,
  }) {
    return LibraryState(
      status: status ?? this.status,
      books: books ?? this.books,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
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
      emit(
        state.copyWith(
          status: LibraryStatus.loaded,
          books: books,
          isOnline: _repository.isOnline,
          pendingSyncCount: _repository.pendingSyncCount,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: LibraryStatus.failure,
          isOnline: _repository.isOnline,
          pendingSyncCount: _repository.pendingSyncCount,
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
    try {
      final downloaded = await _repository.downloadBook(bookId);
      final updated = state.books
          .map((book) {
            return book.id == bookId ? downloaded : book;
          })
          .toList(growable: false);
      emit(
        state.copyWith(
          status: LibraryStatus.loaded,
          books: updated,
          isOnline: _repository.isOnline,
          pendingSyncCount: _repository.pendingSyncCount,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: LibraryStatus.failure,
          isOnline: _repository.isOnline,
          pendingSyncCount: _repository.pendingSyncCount,
          errorMessage: '$error',
        ),
      );
    }
  }

  Future<void> setOnline(bool value) async {
    await _repository.setOnline(value);
    emit(
      state.copyWith(
        isOnline: _repository.isOnline,
        pendingSyncCount: _repository.pendingSyncCount,
      ),
    );
  }

  Future<int> syncPendingActions() async {
    final synced = await _repository.syncPendingActions();
    emit(
      state.copyWith(
        isOnline: _repository.isOnline,
        pendingSyncCount: _repository.pendingSyncCount,
      ),
    );
    return synced;
  }

  void updateBookProgress(String bookId, double progress) {
    final updated = state.books
        .map((book) {
          return book.id == bookId ? book.copyWith(progress: progress) : book;
        })
        .toList(growable: false);
    emit(
      state.copyWith(
        books: updated,
        pendingSyncCount: _repository.pendingSyncCount,
      ),
    );
  }
}
