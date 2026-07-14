import 'package:flutter_test/flutter_test.dart';
import 'package:tech_smart_shop/provider/category_provider.dart';
import 'package:tech_smart_shop/provider/product_provider.dart';
import 'package:tech_smart_shop/provider/search_provider.dart';
import 'package:tech_smart_shop/service/catalog/catalog_service.dart';
import 'support/fake_catalog_repository.dart';

void main() {
  test('category provider handles success empty error and retry', () async {
    final repo = FakeCatalogRepository();
    final p = CategoryProvider(repo);
    await p.load();
    expect(p.categories, hasLength(1));
    repo.empty = true;
    await p.load();
    expect(p.categories, isEmpty);
    repo.fail = true;
    await p.load();
    expect(p.error, isNotNull);
    repo.fail = false;
    repo.empty = false;
    await p.load();
    expect(p.error, isNull);
  });
  test('product provider loads, sorts, filters and refreshes', () async {
    final repo = FakeCatalogRepository();
    final p = ProductProvider(repo);
    await p.loadInitial();
    expect(p.products, hasLength(1));
    await p.changeSort(CatalogSort.priceDesc);
    expect(p.sort, CatalogSort.priceDesc);
    await p.applyFilters(const CatalogFilters(inStockOnly: true));
    expect(p.filters.inStockOnly, isTrue);
    await p.resetFilters();
    expect(p.filters.inStockOnly, isFalse);
    await p.refresh();
    expect(repo.productCalls, 5);
  });
  test('search debounces and clears state', () async {
    final repo = FakeCatalogRepository();
    final p = SearchProvider(
      repo,
      debounceDuration: const Duration(milliseconds: 10),
    );
    p.updateQuery('hub');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(p.results, hasLength(1));
    p.clear();
    expect(p.results, isEmpty);
    p.dispose();
  });
}
