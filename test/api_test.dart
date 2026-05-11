import 'package:flutter_test/flutter_test.dart';
import 'package:insightshelf_mobile/features/auth/data/local_insight_shelf_backend.dart';
import 'package:insightshelf_mobile/features/library/data/reader_backend_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('api returns purchased books from catalog', () async {
    final api = LocalInsightShelfBackend(
      backendStore: ReaderBackendStore(
        fileName: 'api-test-${DateTime.now().microsecondsSinceEpoch}.json',
        useApplicationSupportDirectory: false,
      ),
    );
    final books = await api.fetchPurchasedBooks();
    expect(books.length, greaterThanOrEqualTo(4));
  });
}
