import 'package:flutter/foundation.dart';
import '../model/product/catalog_models.dart';
import '../service/catalog/catalog_service.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this._catalog);
  final CatalogRepository _catalog;
  List<CategorySummary> _categories = const [];
  CategoryDetail? _detail;
  bool _loading = false;
  String? _error;
  int _request = 0;
  List<CategorySummary> get categories => _categories;
  CategoryDetail? get detail => _detail;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load({bool rootOnly = false}) async {
    final request = ++_request;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _catalog.fetchCategories(rootOnly: rootOnly);
      if (request != _request) return;
      _categories = result;
    } catch (_) {
      if (request != _request) return;
      _error =
          'We could not load categories. Check your connection and try again.';
    } finally {
      if (request == _request) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadDetail(int id) async {
    final request = ++_request;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _catalog.fetchCategory(id);
      if (request == _request) _detail = result;
    } catch (_) {
      if (request == _request) _error = 'We could not load this category.';
    } finally {
      if (request == _request) {
        _loading = false;
        notifyListeners();
      }
    }
  }
}
