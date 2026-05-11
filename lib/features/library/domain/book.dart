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
    this.assetPath,
    this.pageCount,
    this.fileSizeLabel,
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
  final String? assetPath;
  final int? pageCount;
  final String? fileSizeLabel;
  final double progress;
  final bool isDownloaded;

  Book copyWith({
    List<BookChapter>? chapters,
    double? progress,
    bool? isDownloaded,
  }) {
    return Book(
      id: id,
      title: title,
      author: author,
      description: description,
      category: category,
      format: format,
      coverColor: coverColor,
      chapters: chapters ?? this.chapters,
      assetPath: assetPath,
      pageCount: pageCount,
      fileSizeLabel: fileSizeLabel,
      progress: progress ?? this.progress,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

class BookChapter {
  const BookChapter({
    required this.title,
    required this.paragraphs,
    this.pageNumber,
  });

  final String title;
  final List<String> paragraphs;
  final int? pageNumber;
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
