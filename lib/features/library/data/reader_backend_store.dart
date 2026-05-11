import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../reader/domain/reading_models.dart';

class ReaderBackendStore {
  ReaderBackendStore({this.fileName = 'insightshelf_backend.json'});

  final String fileName;
  File? _file;
  BackendSnapshot? _snapshot;

  Future<BackendSnapshot> load() async {
    if (_snapshot != null) {
      return _snapshot!;
    }

    final file = await _backendFile();
    if (!await file.exists()) {
      _snapshot = BackendSnapshot.empty();
      await save(_snapshot!);
      return _snapshot!;
    }

    try {
      final raw = await file.readAsString();
      _snapshot = BackendSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      _snapshot = BackendSnapshot.empty();
      await save(_snapshot!);
    }

    return _snapshot!;
  }

  Future<void> save(BackendSnapshot snapshot) async {
    _snapshot = snapshot;
    final file = await _backendFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
      flush: true,
    );
  }

  Future<File> _backendFile() async {
    if (_file != null) {
      return _file!;
    }

    Directory directory;
    try {
      directory = await getApplicationSupportDirectory();
    } on MissingPluginException {
      directory = Directory.systemTemp;
    } on UnsupportedError {
      directory = Directory.systemTemp;
    }

    final appDirectory = Directory('${directory.path}/insightshelf_mobile');
    if (!await appDirectory.exists()) {
      await appDirectory.create(recursive: true);
    }
    _file = File('${appDirectory.path}/$fileName');
    return _file!;
  }
}

class BackendSnapshot {
  const BackendSnapshot({
    required this.downloadedBookIds,
    required this.progress,
    required this.bookmarks,
    required this.highlights,
    required this.notes,
    required this.insights,
    required this.pendingSyncActions,
  });

  factory BackendSnapshot.empty() {
    return const BackendSnapshot(
      downloadedBookIds: {},
      progress: {},
      bookmarks: {},
      highlights: {},
      notes: {},
      insights: {},
      pendingSyncActions: [],
    );
  }

  factory BackendSnapshot.fromJson(Map<String, dynamic> json) {
    return BackendSnapshot(
      downloadedBookIds: Set<String>.from(
        json['downloadedBookIds'] as List? ?? const [],
      ),
      progress: _mapOf(json['progress'], ReadingProgressCodec.fromJson),
      bookmarks: _listMapOf(json['bookmarks'], BookmarkCodec.fromJson),
      highlights: _listMapOf(json['highlights'], HighlightCodec.fromJson),
      notes: _listMapOf(json['notes'], NoteCodec.fromJson),
      insights: _listMapOf(json['insights'], InsightCardCodec.fromJson),
      pendingSyncActions: List<String>.from(
        json['pendingSyncActions'] as List? ?? const [],
      ),
    );
  }

  final Set<String> downloadedBookIds;
  final Map<String, ReadingProgress> progress;
  final Map<String, List<Bookmark>> bookmarks;
  final Map<String, List<Highlight>> highlights;
  final Map<String, List<Note>> notes;
  final Map<String, List<InsightCard>> insights;
  final List<String> pendingSyncActions;

  BackendSnapshot copyWith({
    Set<String>? downloadedBookIds,
    Map<String, ReadingProgress>? progress,
    Map<String, List<Bookmark>>? bookmarks,
    Map<String, List<Highlight>>? highlights,
    Map<String, List<Note>>? notes,
    Map<String, List<InsightCard>>? insights,
    List<String>? pendingSyncActions,
  }) {
    return BackendSnapshot(
      downloadedBookIds: downloadedBookIds ?? this.downloadedBookIds,
      progress: progress ?? this.progress,
      bookmarks: bookmarks ?? this.bookmarks,
      highlights: highlights ?? this.highlights,
      notes: notes ?? this.notes,
      insights: insights ?? this.insights,
      pendingSyncActions: pendingSyncActions ?? this.pendingSyncActions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadedBookIds': downloadedBookIds.toList()..sort(),
      'progress': progress.map((key, value) => MapEntry(key, value.toJson())),
      'bookmarks': bookmarks.map(
        (key, value) =>
            MapEntry(key, value.map((item) => item.toJson()).toList()),
      ),
      'highlights': highlights.map(
        (key, value) =>
            MapEntry(key, value.map((item) => item.toJson()).toList()),
      ),
      'notes': notes.map(
        (key, value) =>
            MapEntry(key, value.map((item) => item.toJson()).toList()),
      ),
      'insights': insights.map(
        (key, value) =>
            MapEntry(key, value.map((item) => item.toJson()).toList()),
      ),
      'pendingSyncActions': pendingSyncActions,
    };
  }

  static Map<String, T> _mapOf<T>(
    Object? raw,
    T Function(Map<String, dynamic>) convert,
  ) {
    final map = raw as Map? ?? const {};
    return map.map(
      (key, value) =>
          MapEntry('$key', convert(Map<String, dynamic>.from(value as Map))),
    );
  }

  static Map<String, List<T>> _listMapOf<T>(
    Object? raw,
    T Function(Map<String, dynamic>) convert,
  ) {
    final map = raw as Map? ?? const {};
    return map.map(
      (key, value) => MapEntry(
        '$key',
        (value as List? ?? const [])
            .map((item) => convert(Map<String, dynamic>.from(item as Map)))
            .toList(),
      ),
    );
  }
}

extension ReadingProgressCodec on ReadingProgress {
  static ReadingProgress fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      bookId: json['bookId'] as String,
      chapterIndex: json['chapterIndex'] as int,
      percent: (json['percent'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'bookId': bookId, 'chapterIndex': chapterIndex, 'percent': percent};
  }
}

extension BookmarkCodec on Bookmark {
  static Bookmark fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      chapterIndex: json['chapterIndex'] as int,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterIndex': chapterIndex,
      'label': label,
    };
  }
}

extension HighlightCodec on Highlight {
  static Highlight fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      chapterIndex: json['chapterIndex'] as int,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterIndex': chapterIndex,
      'text': text,
    };
  }
}

extension NoteCodec on Note {
  static Note fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      chapterIndex: json['chapterIndex'] as int,
      text: json['text'] as String,
      body: json['body'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterIndex': chapterIndex,
      'text': text,
      'body': body,
    };
  }
}

extension InsightCardCodec on InsightCard {
  static InsightCard fromJson(Map<String, dynamic> json) {
    return InsightCard(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      chapterIndex: json['chapterIndex'] as int,
      type: InsightType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => InsightType.summary,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      points: List<String>.from(json['points'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'chapterIndex': chapterIndex,
      'type': type.name,
      'title': title,
      'body': body,
      'points': points,
    };
  }
}
