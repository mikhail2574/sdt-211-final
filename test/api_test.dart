import 'package:flutter_test/flutter_test.dart';
import 'package:insightshelf_mobile/features/auth/data/mock_insight_shelf_api.dart';

void main() {
  testWidgets('api returns purchased books from catalog', (tester) async {
    final api = MockInsightShelfApi();
    final books = await api.fetchPurchasedBooks();
    expect(books.length, greaterThanOrEqualTo(4));
  });
}
