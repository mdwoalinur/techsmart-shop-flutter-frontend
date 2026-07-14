import 'package:flutter/foundation.dart';
import '../model/compare/compare_item.dart';
import '../model/product/catalog_models.dart';

enum CompareResult { added, removed, limitReached }

class CompareProvider extends ChangeNotifier {
  static const maximum = 4;
  List<CompareItem> _items = [];
  List<CompareItem> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool contains(int id) => _items.any((e) => e.productId == id);
  CompareResult toggle(ProductSummary p) {
    if (contains(p.id)) {
      _items = _items.where((e) => e.productId != p.id).toList();
      notifyListeners();
      return CompareResult.removed;
    }
    if (_items.length >= maximum) return CompareResult.limitReached;
    _items = [..._items, CompareItem.fromProduct(p)];
    notifyListeners();
    return CompareResult.added;
  }

  void remove(int id) {
    if (!contains(id)) return;
    _items = _items.where((e) => e.productId != id).toList();
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items = [];
    notifyListeners();
  }
}
