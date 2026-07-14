import '../../model/common/api_models.dart';
import '../../model/product/catalog_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

enum CatalogSort {
  nameAsc('Name A–Z', 'name', 'asc'),
  nameDesc('Name Z–A', 'name', 'desc'),
  priceAsc('Price Low to High', 'price', 'asc'),
  priceDesc('Price High to Low', 'price', 'desc'),
  newest('Newest', 'createdAt', 'desc'),
  recentlyUpdated('Recently Updated', 'updatedAt', 'desc');

  const CatalogSort(this.label, this.apiField, this.direction);
  final String label;
  final String apiField;
  final String direction;
}

class CatalogFilters {
  const CatalogFilters({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
  });
  final int? categoryId;
  final DecimalValue? minPrice;
  final DecimalValue? maxPrice;
  final bool inStockOnly;
  bool get isEmpty =>
      categoryId == null &&
      minPrice == null &&
      maxPrice == null &&
      !inStockOnly;
  CatalogFilters copyWith({
    int? categoryId,
    DecimalValue? minPrice,
    DecimalValue? maxPrice,
    bool? inStockOnly,
    bool clearPrices = false,
  }) => CatalogFilters(
    categoryId: categoryId ?? this.categoryId,
    minPrice: clearPrices ? null : minPrice ?? this.minPrice,
    maxPrice: clearPrices ? null : maxPrice ?? this.maxPrice,
    inStockOnly: inStockOnly ?? this.inStockOnly,
  );
}

abstract interface class CatalogRepository {
  Future<List<CategorySummary>> fetchCategories({
    int? parentId,
    bool rootOnly = false,
  });
  Future<CategoryDetail> fetchCategory(int id);
  Future<ApiPage<ProductSummary>> fetchProducts({
    int page = 0,
    int size = 20,
    CatalogSort sort = CatalogSort.nameAsc,
    CatalogFilters filters = const CatalogFilters(),
  });
  Future<ApiPage<ProductSummary>> fetchCategoryProducts(
    int categoryId, {
    int page = 0,
    int size = 20,
    CatalogSort sort = CatalogSort.nameAsc,
    CatalogFilters filters = const CatalogFilters(),
  });
  Future<ApiPage<ProductSummary>> searchProducts(
    String query, {
    int page = 0,
    int size = 20,
    CatalogSort sort = CatalogSort.nameAsc,
    CatalogFilters filters = const CatalogFilters(),
  });
  Future<ProductDetail> fetchProduct(int id);
}

class CatalogService implements CatalogRepository {
  const CatalogService(this._client);
  final ApiClient _client;

  @override
  Future<List<CategorySummary>> fetchCategories({
    int? parentId,
    bool rootOnly = false,
  }) async {
    final data = await _get('/categories', {
      'parentId': parentId?.toString(),
      'rootOnly': rootOnly.toString(),
    });
    return ApiEnvelope<List<CategorySummary>>.fromJson(data, (raw) {
      if (raw is! List<Object?>) {
        throw CatalogParseException('data must be an array.', raw);
      }
      return List.unmodifiable(raw.map(CategorySummary.fromJson));
    }).data;
  }

  @override
  Future<CategoryDetail> fetchCategory(int id) async =>
      ApiEnvelope<CategoryDetail>.fromJson(
        await _get('/categories/$id'),
        CategoryDetail.fromJson,
      ).data;

  @override
  Future<ApiPage<ProductSummary>> fetchProducts({
    int page = 0,
    int size = 20,
    CatalogSort sort = CatalogSort.nameAsc,
    CatalogFilters filters = const CatalogFilters(),
  }) => _products('/products', page, size, sort, filters);

  @override
  Future<ApiPage<ProductSummary>> fetchCategoryProducts(
    int categoryId, {
    int page = 0,
    int size = 20,
    CatalogSort sort = CatalogSort.nameAsc,
    CatalogFilters filters = const CatalogFilters(),
  }) =>
      _products('/categories/$categoryId/products', page, size, sort, filters);

  @override
  Future<ApiPage<ProductSummary>> searchProducts(
    String query, {
    int page = 0,
    int size = 20,
    CatalogSort sort = CatalogSort.nameAsc,
    CatalogFilters filters = const CatalogFilters(),
  }) {
    final clean = query.trim();
    if (clean.isEmpty) {
      throw const CatalogRequestException('Enter a search term.');
    }
    if (clean.length > 100) {
      throw const CatalogRequestException(
        'Search text cannot exceed 100 characters.',
      );
    }
    return _products(
      '/products/search',
      page,
      size,
      sort,
      filters,
      query: clean,
    );
  }

  @override
  Future<ProductDetail> fetchProduct(int id) async =>
      ApiEnvelope<ProductDetail>.fromJson(
        await _get('/products/$id'),
        ProductDetail.fromJson,
      ).data;

  Future<ApiPage<ProductSummary>> _products(
    String path,
    int page,
    int size,
    CatalogSort sort,
    CatalogFilters filters, {
    String? query,
  }) async {
    final parameters = <String, String?>{
      'q': query,
      'page': '$page',
      'size': '$size',
      'sort': sort.apiField,
      'direction': sort.direction,
      'categoryId': filters.categoryId?.toString(),
      'minPrice': filters.minPrice?.value,
      'maxPrice': filters.maxPrice?.value,
      'inStock': filters.inStockOnly ? 'true' : null,
    };
    final envelope = ApiEnvelope<ApiPage<ProductSummary>>.fromJson(
      await _get(path, parameters),
      (raw) => ApiPage.fromJson(raw, ProductSummary.fromJson),
    );
    return envelope.data;
  }

  Future<Object?> _get(
    String path, [
    Map<String, String?> query = const {},
  ]) async {
    try {
      return await _client.get(path, queryParameters: query);
    } on ApiException catch (error) {
      MobileApiError? parsed;
      try {
        if (error.responseBody != null) {
          parsed = MobileApiError.fromJson(error.responseBody);
        }
      } on FormatException {
        /* use safe client message */
      }
      throw CatalogRequestException(
        parsed?.message ?? error.message,
        statusCode: error.statusCode,
        fieldErrors: parsed?.fieldErrors ?? const [],
        type: error.type,
      );
    } on FormatException catch (error) {
      throw CatalogRequestException(
        'The server returned unexpected catalog data.',
        cause: error,
      );
    }
  }
}

class CatalogRequestException implements Exception {
  const CatalogRequestException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const [],
    this.type,
    this.cause,
  });
  final String message;
  final int? statusCode;
  final List<MobileFieldError> fieldErrors;
  final ApiExceptionType? type;
  final Object? cause;
}
