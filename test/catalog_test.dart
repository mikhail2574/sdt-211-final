import 'package:flutter_test/flutter_test.dart';
import 'package:insightshelf_mobile/features/library/data/purchased_books_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog reads purchased PDF folder', () async {
    final books = await const PurchasedBooksCatalog().loadPurchasedBooks();
    expect(books.length, greaterThanOrEqualTo(4));
    expect(
      books.map((book) => book.assetPath),
      everyElement(contains('assets/purchased_books/')),
    );
  });
}
