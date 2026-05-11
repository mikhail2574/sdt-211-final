import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../domain/book.dart';

class PdfBookParser {
  const PdfBookParser();

  Future<List<BookChapter>> parseAsset(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final document = PdfDocument(inputBytes: bytes.buffer.asUint8List());
    final extractor = PdfTextExtractor(document);
    final chapters = <BookChapter>[];

    try {
      for (var index = 0; index < document.pages.count; index++) {
        final text = extractor.extractText(
          startPageIndex: index,
          endPageIndex: index,
        );
        final paragraphs = _paragraphsFrom(text);
        if (paragraphs.isEmpty) {
          continue;
        }

        chapters.add(
          BookChapter(
            title: _titleForPage(index + 1, paragraphs.first),
            pageNumber: index + 1,
            paragraphs: paragraphs,
          ),
        );
      }
    } finally {
      document.dispose();
    }

    if (chapters.isEmpty) {
      throw const FormatException('The PDF did not expose readable text.');
    }

    return chapters;
  }

  List<String> _paragraphsFrom(String raw) {
    final normalized = raw
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'-\s*\n\s*'), '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    if (normalized.isEmpty) {
      return const [];
    }

    final blocks = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((block) => block.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim())
        .where((block) => block.length > 40)
        .toList();

    if (blocks.isNotEmpty) {
      return blocks;
    }

    final single = normalized.replaceAll(RegExp(r'\s*\n\s*'), ' ').trim();
    return single.length > 20 ? [single] : const [];
  }

  String _titleForPage(int pageNumber, String firstParagraph) {
    final cleaned = firstParagraph
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceFirst(RegExp(r'^\d+\s+'), '')
        .trim();
    final title = cleaned.length > 64
        ? '${cleaned.substring(0, 64)}...'
        : cleaned;
    return 'Page $pageNumber - $title';
  }
}
