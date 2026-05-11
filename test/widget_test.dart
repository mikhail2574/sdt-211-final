import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:insightshelf_mobile/app.dart';

void main() {
  testWidgets('user can sign in and view the purchased library', (
    tester,
  ) async {
    await tester.pumpWidget(const InsightShelfApp());
    await tester.pumpAndSettle();

    expect(find.text('InsightShelf Mobile'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Purchased Library'), findsOneWidget);
    expect(find.text('Systems for Focus'), findsWidgets);
    expect(find.text('Market Maps'), findsWidgets);
  });

  testWidgets('reader opens and can create a highlight', (tester) async {
    await tester.pumpWidget(const InsightShelfApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Systems for Focus').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Continue reading'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continue reading'));
    await tester.pumpAndSettle();

    expect(find.text('Design the Environment'), findsOneWidget);

    await tester.tap(find.byTooltip('Highlight').first);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Highlights'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Highlights'), findsOneWidget);
    expect(find.textContaining('Attention improves'), findsWidgets);
  });

  testWidgets('offline mode shows sync state', (tester) async {
    await tester.pumpWidget(const InsightShelfApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sync'));
    await tester.pumpAndSettle();

    expect(find.text('Sync & Account'), findsOneWidget);

    await tester.tap(find.text('Online mode'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Offline mode'), findsOneWidget);
  });
}
