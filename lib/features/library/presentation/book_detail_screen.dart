import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../reader/presentation/reader_screen.dart';
import '../domain/book.dart';
import 'book_cover.dart';
import 'library_cubit.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final book = state.books.firstWhere((item) => item.id == bookId);
        final isDownloading = state.downloadingBookIds.contains(book.id);
        return Scaffold(
          appBar: AppBar(title: const Text('Book Details')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(book: book, width: 112),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text('by ${book.author}'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(book.format.label)),
                            Chip(label: Text(book.category)),
                            Chip(
                              avatar: Icon(
                                book.isDownloaded
                                    ? Icons.offline_pin
                                    : Icons.cloud_download_outlined,
                                size: 18,
                              ),
                              label: Text(
                                book.isDownloaded ? 'Downloaded' : 'Cloud only',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              LinearProgressIndicator(value: book.progress.clamp(0, 1)),
              const SizedBox(height: 8),
              Text('${(book.progress * 100).round()}% reading progress'),
              const SizedBox(height: 22),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(book.description),
              const SizedBox(height: 22),
              Text('Chapters', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (book.chapters.isEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text('${book.pageCount ?? 0} PDF pages'),
                  subtitle: Text(
                    '${book.fileSizeLabel ?? 'Local file'} - text is parsed when the book is opened or downloaded.',
                  ),
                )
              else
                ...book.chapters
                    .take(8)
                    .map(
                      (chapter) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(chapter.title),
                        subtitle: Text(
                          '${chapter.paragraphs.length} readable blocks',
                        ),
                      ),
                    ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReaderScreen(bookId: book.id),
                    ),
                  );
                },
                icon: const Icon(Icons.chrome_reader_mode_outlined),
                label: Text(
                  book.progress > 0 ? 'Continue reading' : 'Open reader',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: book.isDownloaded || isDownloading
                    ? null
                    : () => context.read<LibraryCubit>().downloadBook(book.id),
                icon: isDownloading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_for_offline_outlined),
                label: Text(
                  isDownloading
                      ? 'Preparing offline copy'
                      : book.isDownloaded
                      ? 'Available offline'
                      : 'Download for offline',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
