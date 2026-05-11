import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../domain/book.dart';

class PurchasedBooksCatalog {
  const PurchasedBooksCatalog({this.folder = 'assets/purchased_books/'});

  final String folder;

  Future<List<Book>> loadPurchasedBooks() async {
    final assets = await _pdfAssets();
    final books = <Book>[];

    for (var index = 0; index < assets.length; index++) {
      books.add(await _bookFromAsset(assets[index], index));
    }

    books.sort((a, b) => a.title.compareTo(b.title));
    return books;
  }

  Future<List<String>> _pdfAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where((asset) => asset.startsWith(folder) && asset.endsWith('.pdf'))
        .toList(growable: false);
  }

  Future<Book> _bookFromAsset(String assetPath, int index) async {
    final bytes = await rootBundle.load(assetPath);
    final document = PdfDocument(inputBytes: bytes.buffer.asUint8List());
    final info = document.documentInformation;

    try {
      final fileName = assetPath.split('/').last;
      final title = _cleanTitle(info.title) ?? _titleFromFile(fileName);
      final author = _cleanTitle(info.author) ?? _knownAuthor(fileName);

      return Book(
        id: _stableId(fileName),
        title: title,
        author: author,
        description:
            'Purchased PDF imported from $folder. It is parsed locally into readable pages, can be downloaded for offline reading, searched, annotated, and used with local Ollama generation.',
        category: _categoryFor(fileName, title),
        format: BookFormat.pdf,
        coverColor: _coverColors[index % _coverColors.length],
        assetPath: assetPath,
        pageCount: document.pages.count,
        fileSizeLabel: _formatSize(bytes.lengthInBytes),
        chapters: const [],
      );
    } finally {
      document.dispose();
    }
  }

  String? _cleanTitle(String? value) {
    final normalized = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String _titleFromFile(String fileName) {
    return Uri.decodeComponent(fileName)
        .replaceAll('.pdf', '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _knownAuthor(String fileName) {
    if (fileName.contains('Designing Software Architecture')) {
      return 'Humberto Cervantes, Rick Kazman';
    }
    if (fileName.contains('Kafka_Streams')) {
      return 'Bill Bejeck';
    }
    if (fileName.contains('Grokking_Streaming')) {
      return 'Josh Fischer, Ning Wang';
    }
    return 'Purchased book';
  }

  String _categoryFor(String fileName, String title) {
    final normalized = '$fileName $title'.toLowerCase();
    if (normalized.contains('architecture')) {
      return 'Software Architecture';
    }
    if (normalized.contains('kafka') || normalized.contains('streaming')) {
      return 'Streaming Systems';
    }
    return 'Technical Book';
  }

  String _stableId(String fileName) {
    return fileName
        .replaceAll('.pdf', '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String _formatSize(int bytes) {
    final megabytes = bytes / 1024 / 1024;
    return '${megabytes.toStringAsFixed(megabytes >= 10 ? 0 : 1)} MB';
  }
}

const _coverColors = [
  0xFF176B87,
  0xFFE17A47,
  0xFF5D7A3A,
  0xFF7C4D79,
  0xFF3E5C76,
  0xFF8A5A44,
];
