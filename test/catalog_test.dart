import 'package:flutter_test/flutter_test.dart';
import 'package:insightshelf_mobile/features/library/data/purchased_books_catalog.dart';

void main() {
  testWidgets('catalog reads purchased PDF folder', (tester) async {
    final books = await const PurchasedBooksCatalog().loadPurchasedBooks();
    expect(books.length, greaterThanOrEqualTo(4));
    expect(books.map((book) => book.assetPath), everyElement(contains('assets/purchased_books/')));
  });
}
