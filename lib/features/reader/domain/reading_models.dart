enum InsightType { summary, visual, example, actionSteps, simpleExplanation }

class ReadingPreferences {
  const ReadingPreferences({
    this.fontSize = 18,
    this.lineHeight = 1.55,
    this.wideMargins = false,
    this.darkMode = false,
    this.aiEnabled = true,
    this.businessMode = true,
  });

  final double fontSize;
  final double lineHeight;
  final bool wideMargins;
  final bool darkMode;
  final bool aiEnabled;
  final bool businessMode;

  ReadingPreferences copyWith({
    double? fontSize,
    double? lineHeight,
    bool? wideMargins,
    bool? darkMode,
    bool? aiEnabled,
    bool? businessMode,
  }) {
    return ReadingPreferences(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      wideMargins: wideMargins ?? this.wideMargins,
      darkMode: darkMode ?? this.darkMode,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      businessMode: businessMode ?? this.businessMode,
    );
  }
}

class ReadingProgress {
  const ReadingProgress({
    required this.bookId,
    required this.chapterIndex,
    required this.percent,
  });

  final String bookId;
  final int chapterIndex;
  final double percent;
}

class Bookmark {
  const Bookmark({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.label,
  });

  final String id;
  final String bookId;
  final int chapterIndex;
  final String label;
}

class Highlight {
  const Highlight({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.text,
  });

  final String id;
  final String bookId;
  final int chapterIndex;
  final String text;
}

class Note {
  const Note({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.text,
    required this.body,
  });

  final String id;
  final String bookId;
  final int chapterIndex;
  final String text;
  final String body;

  Note copyWith({String? body}) {
    return Note(
      id: id,
      bookId: bookId,
      chapterIndex: chapterIndex,
      text: text,
      body: body ?? this.body,
    );
  }
}

class InsightCard {
  const InsightCard({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.type,
    required this.title,
    required this.body,
    required this.points,
  });

  final String id;
  final String bookId;
  final int chapterIndex;
  final InsightType type;
  final String title;
  final String body;
  final List<String> points;
}
