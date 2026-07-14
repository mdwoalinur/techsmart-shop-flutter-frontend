import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/common/api_models.dart';
import '../model/product/catalog_models.dart';
import '../service/catalog/catalog_service.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider(
    this._catalog, {
    this.debounceDuration = const Duration(milliseconds: 400),
  });
  final CatalogRepository _catalog;
  final Duration debounceDuration;
  Timer? _timer;
  int _request = 0;
  String _query = '';
  List<ProductSummary> _results = const [];
  ApiPage<ProductSummary>? _page;
  CatalogSort _sort = CatalogSort.nameAsc;
  CatalogFilters _filters = const CatalogFilters();
  bool _loading = false, _loadingMore = false;
  String? _error;
  String get query => _query;
  List<ProductSummary> get results => _results;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  String? get error => _error;
  CatalogSort get sort => _sort;
  CatalogFilters get filters => _filters;
  bool get canLoadMore => _page != null && !_page!.last;
  void updateQuery(String value) {
    _query = value.trimLeft();
    _timer?.cancel();
    if (_query.trim().isEmpty) {
      clear();
      return;
    }
    _timer = Timer(debounceDuration, submit);
    notifyListeners();
  }

  Future<void> submit() async {
    _timer?.cancel();
    final clean = _query.trim();
    if (clean.isEmpty) return;
    if (clean.length > 100) {
      _error = 'Search text cannot exceed 100 characters.';
      notifyListeners();
      return;
    }
    final request = ++_request;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final p = await _catalog.searchProducts(
        clean,
        page: 0,
        sort: _sort,
        filters: _filters,
      );
      if (request == _request) {
        _page = p;
        _results = p.content;
      }
    } catch (_) {
      if (request == _request) {
        _error =
            'We could not search products. Check your connection and try again.';
      }
    } finally {
      if (request == _request) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !canLoadMore) return;
    final request = _request;
    _loadingMore = true;
    notifyListeners();
    try {
      final p = await _catalog.searchProducts(
        _query.trim(),
        page: _page!.page + 1,
        sort: _sort,
        filters: _filters,
      );
      if (request == _request) {
        final ids = _results.map((e) => e.id).toSet();
        _results = [..._results, ...p.content.where((e) => ids.add(e.id))];
        _page = p;
      }
    } catch (_) {
      if (request == _request) _error = 'Could not load more search results.';
    } finally {
      if (request == _request) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> changeSort(CatalogSort value) async {
    _sort = value;
    await submit();
  }

  Future<void> applyFilters(CatalogFilters value) async {
    _filters = value;
    await submit();
  }

  void clear() {
    _timer?.cancel();
    _request++;
    _query = '';
    _results = const [];
    _page = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
