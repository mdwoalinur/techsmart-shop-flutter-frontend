import 'package:flutter/foundation.dart';
import '../model/common/api_models.dart';
import '../model/product/catalog_models.dart';
import '../service/catalog/catalog_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider(
    this._catalog, {
    this.categoryId,
    CatalogSort initialSort = CatalogSort.nameAsc,
  }) : _sort = initialSort,
       _filters = CatalogFilters(categoryId: categoryId);
  final CatalogRepository _catalog;
  final int? categoryId;
  List<ProductSummary> _products = const [];
  ProductDetail? _detail;
  ProductVariation? _selectedVariation;
  ApiPage<ProductSummary>? _page;
  CatalogSort _sort;
  CatalogFilters _filters;
  bool _initialLoading = false, _loadingMore = false, _refreshing = false;
  String? _error, _loadMoreError;
  int _request = 0;
  int? _detailId;
  List<ProductSummary> get products => _products;
  ProductDetail? get detail => _detail;
  ProductVariation? get selectedVariation => _selectedVariation;
  CatalogSort get sort => _sort;
  CatalogFilters get filters => _filters;
  bool get isInitialLoading => _initialLoading;
  bool get isLoadingMore => _loadingMore;
  bool get isRefreshing => _refreshing;
  bool get canLoadMore => _page != null && !_page!.last;
  int get totalElements => _page?.totalElements ?? 0;
  String? get error => _error;
  String? get loadMoreError => _loadMoreError;

  Future<void> loadInitial() => _load(reset: true);
  Future<void> retry() => _load(reset: true);
  Future<void> refresh() async {
    _refreshing = true;
    notifyListeners();
    await _load(reset: true, silent: true);
    _refreshing = false;
    notifyListeners();
  }

  Future<void> changeSort(CatalogSort value) async {
    if (value == _sort) return;
    _sort = value;
    await _load(reset: true);
  }

  Future<void> applyFilters(CatalogFilters value) async {
    _filters = value.copyWith(categoryId: categoryId ?? value.categoryId);
    await _load(reset: true);
  }

  Future<void> resetFilters() =>
      applyFilters(CatalogFilters(categoryId: categoryId));
  Future<void> loadMore() async {
    if (_loadingMore || !canLoadMore) return;
    await _load(reset: false);
  }

  Future<void> _load({required bool reset, bool silent = false}) async {
    if (reset) {
      final request = ++_request;
      if (!silent) _initialLoading = true;
      _error = null;
      _loadMoreError = null;
      notifyListeners();
      try {
        final next = await _fetch(0);
        if (request != _request) return;
        _page = next;
        _products = next.content;
      } catch (_) {
        if (request != _request) return;
        _error =
            'We could not load products. Check your connection and try again.';
      } finally {
        if (request == _request) {
          _initialLoading = false;
          notifyListeners();
        }
      }
    } else {
      final request = _request;
      _loadingMore = true;
      _loadMoreError = null;
      notifyListeners();
      try {
        final next = await _fetch((_page?.page ?? -1) + 1);
        if (request != _request) return;
        final ids = _products.map((e) => e.id).toSet();
        _products = [..._products, ...next.content.where((e) => ids.add(e.id))];
        _page = next;
      } catch (_) {
        if (request == _request) {
          _loadMoreError = 'Could not load more products.';
        }
      } finally {
        if (request == _request) {
          _loadingMore = false;
          notifyListeners();
        }
      }
    }
  }

  Future<ApiPage<ProductSummary>> _fetch(int page) => categoryId == null
      ? _catalog.fetchProducts(page: page, sort: _sort, filters: _filters)
      : _catalog.fetchCategoryProducts(
          categoryId!,
          page: page,
          sort: _sort,
          filters: _filters,
        );

  Future<void> loadDetail(int id) async {
    _detailId = id;
    final request = ++_request;
    _initialLoading = true;
    _error = null;
    _detail = null;
    notifyListeners();
    try {
      final result = await _catalog.fetchProduct(id);
      if (request == _request) {
        _detail = result;
        _selectedVariation = result.variations.isEmpty
            ? null
            : result.variations.first;
      }
    } catch (e) {
      if (request == _request) {
        _error = e is CatalogRequestException && e.statusCode == 404
            ? 'This product is unavailable.'
            : 'We could not load this product.';
      }
    } finally {
      if (request == _request) {
        _initialLoading = false;
        notifyListeners();
      }
    }
  }

  void selectVariation(ProductVariation? value) {
    if (_selectedVariation?.id == value?.id) return;
    _selectedVariation = value;
    notifyListeners();
  }

  Future<void> retryDetail() => loadDetail(_detailId!);
}
