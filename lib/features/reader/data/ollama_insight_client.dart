import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/reading_models.dart';

class OllamaInsightClient {
  OllamaInsightClient({
    this.endpoint = 'http://127.0.0.1:11434/api/generate',
    this.model = 'llama3.2:1b',
  });

  String endpoint;
  String model;

  Future<InsightCard> generate({
    required String bookId,
    required int chapterIndex,
    required String selectedText,
    required InsightType type,
  }) async {
    final uri = Uri.parse(endpoint);
    final prompt = _promptFor(type, selectedText);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);

    try {
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 6));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'model': model,
          'prompt': prompt,
          'stream': false,
          'options': {'temperature': 0.35, 'num_predict': 260},
        }),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OllamaException(
          'Ollama returned HTTP ${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final generated = (decoded['response'] as String? ?? '').trim();
      if (generated.isEmpty) {
        throw const OllamaException('Ollama returned an empty response.');
      }

      return InsightCard(
        id: 'insight-${DateTime.now().microsecondsSinceEpoch}',
        bookId: bookId,
        chapterIndex: chapterIndex,
        type: type,
        title: _titleFor(type),
        body: generated,
        points: _pointsFrom(generated),
      );
    } on SocketException catch (error) {
      throw OllamaException(
        'Cannot reach Ollama at $endpoint. Start Ollama and run: ollama pull $model. Details: ${error.message}',
      );
    } on TimeoutException {
      throw OllamaException('Ollama did not answer in time at $endpoint.');
    } finally {
      client.close(force: true);
    }
  }

  String _promptFor(InsightType type, String text) {
    final instruction = switch (type) {
      InsightType.summary =>
        'Summarize the passage in 4 concise bullet points.',
      InsightType.visual =>
        'Create a compact text-based concept diagram with arrows and labels.',
      InsightType.example =>
        'Give one practical software architecture example based on the passage.',
      InsightType.actionSteps =>
        'Turn the passage into 5 concrete action steps for a software architect.',
      InsightType.simpleExplanation =>
        'Explain the passage in simpler language for a student.',
    };

    return '''
You are the local AI assistant inside a mobile reading app.
Do not invent facts outside the selected passage.
Keep the answer useful, short, and readable on a phone.

Task: $instruction

Selected passage:
$text
''';
  }

  String _titleFor(InsightType type) {
    return switch (type) {
      InsightType.summary => 'Ollama Summary',
      InsightType.visual => 'Ollama Concept Diagram',
      InsightType.example => 'Ollama Example',
      InsightType.actionSteps => 'Ollama Action Steps',
      InsightType.simpleExplanation => 'Ollama Simple Explanation',
    };
  }

  List<String> _pointsFrom(String generated) {
    final lines = generated
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^[-*•\d.)\s]+'), '').trim())
        .where((line) => line.length > 8)
        .take(4)
        .toList();
    return lines.isEmpty
        ? ['Generated locally', 'Ollama', 'On-device workflow']
        : lines;
  }
}

class OllamaException implements Exception {
  const OllamaException(this.message);

  final String message;

  @override
  String toString() => message;
}
