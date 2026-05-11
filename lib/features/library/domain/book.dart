enum BookFormat { epub, pdf, mobi }

enum LibraryFilter { all, downloaded, inProgress, unread }

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.category,
    required this.format,
    required this.coverColor,
    required this.chapters,
    this.progress = 0,
    this.isDownloaded = false,
  });

  final String id;
  final String title;
  final String author;
  final String description;
  final String category;
  final BookFormat format;
  final int coverColor;
  final List<BookChapter> chapters;
  final double progress;
  final bool isDownloaded;

  Book copyWith({double? progress, bool? isDownloaded}) {
    return Book(
      id: id,
      title: title,
      author: author,
      description: description,
      category: category,
      format: format,
      coverColor: coverColor,
      chapters: chapters,
      progress: progress ?? this.progress,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

class BookChapter {
  const BookChapter({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}

extension BookFormatLabel on BookFormat {
  String get label {
    switch (this) {
      case BookFormat.epub:
        return 'EPUB';
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.mobi:
        return 'MOBI';
    }
  }
}
