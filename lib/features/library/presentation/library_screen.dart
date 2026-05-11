import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/async_state_view.dart';
import '../domain/book.dart';
import 'book_cover.dart';
import 'book_detail_screen.dart';
import 'library_cubit.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchased Library'),
        actions: [
          BlocBuilder<LibraryCubit, LibraryState>(
            builder: (context, state) {
              return IconButton(
                tooltip: state.isOnline ? 'Online' : 'Offline',
                onPressed: () =>
                    context.read<LibraryCubit>().setOnline(!state.isOnline),
                icon: Icon(state.isOnline ? Icons.wifi : Icons.wifi_off),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          if (state.status == LibraryStatus.initial ||
              state.status == LibraryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == LibraryStatus.failure && state.books.isEmpty) {
            return AsyncStateView(
              icon: Icons.cloud_off_outlined,
              title: 'Library unavailable',
              message:
                  state.errorMessage ??
                  'Try again when the connection is back.',
              actionLabel: 'Retry',
              onAction: () => context.read<LibraryCubit>().loadLibrary(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<LibraryCubit>().loadLibrary(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _LibraryHeader(state: state)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: state.visibleBooks.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: AsyncStateView(
                            icon: Icons.search_off,
                            title: 'No books found',
                            message:
                                'Change the search or filter to see purchased books.',
                          ),
                        )
                      : SliverList.separated(
                          itemCount: state.visibleBooks.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final book = state.visibleBooks[index];
                            return _BookTile(book: book);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LibraryCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: cubit.search,
            decoration: const InputDecoration(
              hintText: 'Search title, author, or category',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LibraryFilter.values
                  .map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: state.filter == filter,
                        onSelected: (_) => cubit.changeFilter(filter),
                        label: Text(_filterLabel(filter)),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${state.books.length} purchased books • ${state.pendingSyncCount} pending sync',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _filterLabel(LibraryFilter filter) {
    switch (filter) {
      case LibraryFilter.all:
        return 'All';
      case LibraryFilter.downloaded:
        return 'Downloaded';
      case LibraryFilter.inProgress:
        return 'In progress';
      case LibraryFilter.unread:
        return 'Unread';
    }
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(bookId: book.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(book: book),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(book.author),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(label: Text(book.format.label)),
                        Chip(label: Text(book.category)),
                        if (book.isDownloaded)
                          const Chip(
                            avatar: Icon(Icons.offline_pin, size: 18),
                            label: Text('Offline'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: book.progress.clamp(0, 1)),
                    const SizedBox(height: 4),
                    Text('${(book.progress * 100).round()}% complete'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
