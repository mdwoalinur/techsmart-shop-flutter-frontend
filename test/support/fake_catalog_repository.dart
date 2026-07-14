import 'package:tech_smart_shop/model/common/api_models.dart';
import 'package:tech_smart_shop/model/product/catalog_models.dart';
import 'package:tech_smart_shop/service/catalog/catalog_service.dart';

final sampleCategory = CategorySummary(
  id: 1,
  name: 'Laptops',
  root: true,
  active: true,
);
final sampleProduct = ProductSummary(
  id: 32,
  productCode: 'ANKER',
  sku: 'ANKER-32',
  name: 'Anker USB-C Hub',
  sellingPrice: DecimalValue.fromInput('5500.00'),
  category: sampleCategory,
  stock: const StockAvailability(inStock: true, stockLabel: 'In Stock'),
);
final sampleDetail = ProductDetail(
  id: 32,
  productCode: 'ANKER',
  sku: 'ANKER-32',
  name: 'Anker USB-C Hub',
  description: 'Eight useful ports.',
  sellingPrice: DecimalValue.fromInput('5500.00'),
  category: sampleCategory,
  stock: const StockAvailability(inStock: true, stockLabel: 'In Stock'),
  variations: [
    ProductVariation(
      id: 1,
      name: 'Silver',
      effectivePrice: DecimalValue.fromInput('5750.00'),
      additionalPrice: DecimalValue.fromInput('250.00'),
      stock: const StockAvailability(inStock: true, stockLabel: 'In Stock'),
    ),
  ],
);

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({this.fail = false, this.empty = false});
  bool fail;
  bool empty;
  int productCalls = 0;
  void check() {
    if (fail) throw const CatalogRequestException('failed');
  }

  ApiPage<ProductSummary> page(int page) => ApiPage(
    content: empty ? const [] : [sampleProduct],
    page: page,
    size: 20,
    totalElements: empty ? 0 : 1,
    totalPages: 1,
    first: page == 0,
    last: true,
  );
  @override
  Future<List<CategorySummary>> fetchCategories({
    int? parentId,
    bool rootOnly = false,
  }) async {
    check();
    return empty ? const [] : [sampleCategory];
  }

  @override
  Future<CategoryDetail> fetchCategory(int id) async {
    check();
    return CategoryDetail(
      id: 1,
      name: 'Laptops',
      root: true,
      active: true,
      children: const [],
    );
  }

  @override
  Future<ApiPage<ProductSummary>> fetchProducts({
    int page = 0,
    int size = 20,
    CatalogSort sort = CatalogSort.nameAsc,
    CatalogFilters filters = const CatalogFilters(),
  }) async {
    productCalls++;
    check();
    return this.page(page);
  }

  @override
  Future<ApiPage<ProductSummary>> fetchCategoryProducts(
    int categoryId, {
    int page = 0,
    int size = 20,
    CatalogSort sort = CatalogSort.nameAsc,
    CatalogFilters filters = const CatalogFilters(),
  }) => fetchProducts(page: page, size: size, sort: sort, filters: filters);
  @override
  Future<ApiPage<ProductSummary>> searchProducts(
    String query, {
    int page = 0,
    int size = 20,
    CatalogSort sort = CatalogSort.nameAsc,
    CatalogFilters filters = const CatalogFilters(),
  }) async {
    check();
    return this.page(page);
  }

  @override
  Future<ProductDetail> fetchProduct(int id) async {
    check();
    return sampleDetail;
  }
}
