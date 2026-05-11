import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insightshelf_mobile/app.dart';

void main() {
  Future<void> pumpLargeApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const InsightShelfApp());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int maxPumps = 30,
  }) async {
    for (var i = 0; i < maxPumps; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    expect(finder, findsWidgets);
  }

  testWidgets('user can sign in and view the purchased library', (
    tester,
  ) async {
    await pumpLargeApp(tester);

    expect(find.text('InsightShelf Mobile'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await pumpUntilFound(tester, find.text('Purchased Library'));

    expect(find.text('Purchased Library'), findsOneWidget);
    expect(find.textContaining('Kafka Streams'), findsWidgets);
    expect(find.text('Streaming Systems'), findsWidgets);
  });

  testWidgets('reader opens and can create a highlight', (tester) async {
    await pumpLargeApp(tester);

    await tester.tap(find.text('Sign in'));
    await pumpUntilFound(tester, find.textContaining('Kafka Streams'));

    await tester.tap(find.textContaining('Kafka Streams').last);
    await pumpUntilFound(tester, find.text('Book Details'));

    await tester.scrollUntilVisible(
      find.text('Open reader'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Open reader'));
    await pumpUntilFound(tester, find.byTooltip('Highlight paragraph'));

    expect(find.textContaining('Kafka Streams'), findsWidgets);

    await tester.tap(find.byTooltip('Highlight paragraph').first);
    await tester.pump(const Duration(seconds: 1));

    await tester.scrollUntilVisible(
      find.text('Highlights'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Highlights'), findsOneWidget);
    expect(find.textContaining('Kafka Streams'), findsWidgets);
  });

  testWidgets('offline mode shows sync state', (tester) async {
    await pumpLargeApp(tester);

    await tester.tap(find.text('Sign in'));
    await pumpUntilFound(tester, find.text('Purchased Library'));

    await tester.tap(find.text('Sync'));
    await pumpUntilFound(tester, find.text('Sync & Account'));

    expect(find.text('Sync & Account'), findsOneWidget);

    await tester.tap(find.text('Online mode'));
    await tester.pump(const Duration(milliseconds: 250));
    await pumpUntilFound(tester, find.text('Offline mode'));

    expect(find.text('Offline mode'), findsOneWidget);
  });
}
