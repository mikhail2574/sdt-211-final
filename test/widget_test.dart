import 'package:flutter_test/flutter_test.dart';

import 'package:insightshelf_mobile/app.dart';
import 'package:insightshelf_mobile/features/library/data/reader_backend_store.dart';

void main() {
  testWidgets('app renders the login screen', (tester) async {
    await tester.pumpWidget(
      InsightShelfApp(
        backendStore: ReaderBackendStore(
          fileName: 'widget-test-${DateTime.now().microsecondsSinceEpoch}.json',
          useApplicationSupportDirectory: false,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('InsightShelf Mobile'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
