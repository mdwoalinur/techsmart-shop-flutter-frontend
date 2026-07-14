import 'package:flutter_test/flutter_test.dart';
import 'package:tech_smart_shop/model/cart/cart_item.dart';
import 'package:tech_smart_shop/model/compare/compare_item.dart';
import 'package:tech_smart_shop/model/product/catalog_models.dart';
import 'package:tech_smart_shop/model/wishlist/wishlist_item.dart';
import 'package:tech_smart_shop/provider/cart_provider.dart';
import 'package:tech_smart_shop/provider/compare_provider.dart';
import 'package:tech_smart_shop/provider/wishlist_provider.dart';
import 'support/fake_catalog_repository.dart';

ProductSummary product(int id, {bool stock = true}) => ProductSummary(
  id: id,
  productCode: 'P$id',
  sku: 'S$id',
  name: 'Product $id',
  sellingPrice: DecimalValue.fromInput('24590.50'),
  category: sampleCategory,
  stock: StockAvailability(
    inStock: stock,
    stockLabel: stock ? 'In Stock' : 'Out of Stock',
  ),
);
ProductVariation variation(int id) => ProductVariation(
  id: id,
  name: 'V$id',
  sku: 'V-$id',
  effectivePrice: DecimalValue.fromInput('25000.25'),
  additionalPrice: DecimalValue.fromInput('409.75'),
  stock: const StockAvailability(inStock: true, stockLabel: 'In Stock'),
);
void main() {
  test('CartItem identities distinguish base and variation', () {
    expect(CartItem.fromProduct(product(1)).identity, '1:base');
    expect(
      CartItem.fromProduct(product(1), variation: variation(9)).identity,
      '1:9',
    );
  });
  test('money multiplication and item subtotal are exact', () {
    final item = CartItem.fromProduct(product(1), quantity: 3);
    expect(item.subtotal.value, '73771.50');
    expect(MoneyFormatter.taka(item.subtotal), '৳73,771.50');
  });
  test('safe Wishlist and Compare models copy supported fields', () {
    final p = product(2);
    final w = WishlistItem.fromProduct(p);
    final c = CompareItem.fromProduct(p);
    expect(w.productId, 2);
    expect(c.productCode, 'P2');
    expect(c.category, 'Laptops');
  });
  group('CartProvider', () {
    test('starts empty', () {
      expect(CartProvider().items, isEmpty);
    });
    test('adds and merges identical items', () {
      final c = CartProvider();
      c.add(product(1), quantity: 2);
      c.add(product(1), quantity: 3);
      expect(c.lineCount, 1);
      expect(c.totalQuantity, 5);
    });
    test('keeps variations separate', () {
      final c = CartProvider();
      c.add(product(1), variation: variation(1));
      c.add(product(1), variation: variation(2));
      expect(c.lineCount, 2);
    });
    test('increase decrease and limits are safe', () {
      final c = CartProvider();
      c.add(product(1));
      final id = c.items.single.identity;
      c.increase(id);
      c.decrease(id);
      expect(c.items.single.quantity, 1);
      expect(c.setQuantity(id, 0), isFalse);
      expect(c.setQuantity(id, 100), isFalse);
      expect(c.setQuantity(id, 99), isTrue);
      c.increase(id);
      expect(c.items.single.quantity, 99);
    });
    test('remove clear quantity and subtotal', () {
      final c = CartProvider();
      c.add(product(1), quantity: 2);
      expect(c.totalQuantity, 2);
      expect(c.subtotal.value, '49181.00');
      c.remove(c.items.single.identity);
      expect(c.items, isEmpty);
      c.add(product(2));
      c.clear();
      expect(c.items, isEmpty);
    });
    test('rejects out of stock', () {
      expect(
        CartProvider().add(product(1, stock: false)),
        CartAddResult.outOfStock,
      );
    });
  });
  group('WishlistProvider', () {
    test('add duplicate toggle remove clear contains count', () {
      final w = WishlistProvider();
      final p = product(1);
      expect(w.count, 0);
      w.toggle(p);
      expect(w.contains(1), isTrue);
      w.toggle(p);
      expect(w.count, 0);
      w.toggle(p);
      w.remove(1);
      expect(w.count, 0);
      w.toggle(p);
      w.clear();
      expect(w.items, isEmpty);
    });
  });
  group('CompareProvider', () {
    test('toggle duplicate remove clear and limit four', () {
      final c = CompareProvider();
      for (var i = 1; i <= 4; i++) {
        expect(c.toggle(product(i)), CompareResult.added);
      }
      expect(c.count, 4);
      expect(c.toggle(product(5)), CompareResult.limitReached);
      expect(c.toggle(product(1)), CompareResult.removed);
      expect(c.count, 3);
      c.remove(2);
      expect(c.contains(2), isFalse);
      c.clear();
      expect(c.items, isEmpty);
    });
  });
}
