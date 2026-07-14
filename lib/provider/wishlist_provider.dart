import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/product/catalog_models.dart';
import '../model/cart/server_cart.dart';
import '../model/wishlist/wishlist_item.dart';
import '../model/wishlist/server_wishlist.dart';
import '../service/shopping/customer_shopping_service.dart';
import '../service/api/api_exception.dart';
import 'auth_provider.dart';

class WishlistProvider extends ChangeNotifier {
  WishlistProvider({this.repository, AuthProvider? auth}) : _auth = auth {
    auth?.addListener(_authChanged);
    _authChanged();
  }
  final CustomerShoppingRepository? repository;
  final AuthProvider? _auth;
  List<WishlistItem> _items = [];
  List<WishlistItem> _pending = [];
  bool loading = false, mutating = false, merging = false;
  String? error;
  List<ShoppingWarning> warnings = [];
  int? _customer;
  int _generation = 0;
  bool get authenticated => _auth?.authenticated == true;
  List<WishlistItem> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool contains(int id) => _items.any((e) => e.productId == id);
  void _authChanged() {
    final next = _auth?.authenticated == true
        ? _auth!.profile!.customerId
        : null;
    if (next == _customer) return;
    _customer = next;
    final g = ++_generation;
    if (next == null) {
      _items = [];
      _pending = [];
      loading = mutating = merging = false;
      error = null;
      warnings = [];
      notifyListeners();
    } else {
      _pending = List.of(_items);
      unawaited(_sync(g));
    }
  }

  Future<void> _sync(int g) async {
    if (repository == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      _apply(await repository!.getWishlist());
      if (_pending.isNotEmpty) {
        merging = true;
        notifyListeners();
        final id =
            'wishlist-$_customer-${DateTime.now().microsecondsSinceEpoch}';
        _apply(
          await repository!.mergeWishlist(
            id,
            _pending.map((e) => e.productId).toList(),
          ),
        );
        _pending = [];
      }
    } catch (e) {
      if (g == _generation) error = userSafeApiMessage(e);
    } finally {
      if (g == _generation) {
        loading = false;
        merging = false;
        notifyListeners();
      }
    }
  }

  void _apply(ServerWishlist w) {
    _items = w.items
        .map(
          (e) => WishlistItem(
            productId: e.productId,
            name: e.name,
            productCode: '',
            imageUrl: e.imageUrl,
            price: e.price,
            stock: StockAvailability(
              inStock: e.stockLabel != 'Out of Stock',
              stockLabel: e.stockLabel,
            ),
            category: e.category,
          ),
        )
        .toList();
    warnings = w.warnings;
    error = null;
  }

  void toggle(ProductSummary p) {
    if (authenticated && repository != null) {
      unawaited(toggleRemote(p));
      return;
    }
    contains(p.id)
        ? _items = _items.where((e) => e.productId != p.id).toList()
        : _items = [..._items, WishlistItem.fromProduct(p)];
    notifyListeners();
  }

  Future<void> toggleRemote(ProductSummary p) async {
    if (!authenticated || repository == null) {
      toggle(p);
      return;
    }
    await _mutate(
      () => contains(p.id)
          ? repository!.removeWishlist(p.id)
          : repository!.addWishlist(p.id),
    );
  }

  void remove(int id) {
    if (authenticated && repository != null) {
      unawaited(_mutate(() => repository!.removeWishlist(id)));
      return;
    }
    if (contains(id)) {
      _items = _items.where((e) => e.productId != id).toList();
      notifyListeners();
    }
  }

  void clear() {
    if (authenticated && repository != null) {
      unawaited(_mutate(repository!.clearWishlist));
      return;
    }
    if (_items.isNotEmpty) {
      _items = [];
      notifyListeners();
    }
  }

  Future<void> retry() => _sync(_generation);
  Future<void> _mutate(Future<ServerWishlist> Function() action) async {
    if (mutating) return;
    mutating = true;
    error = null;
    notifyListeners();
    try {
      _apply(await action());
    } catch (e) {
      error = userSafeApiMessage(e);
    } finally {
      mutating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_authChanged);
    super.dispose();
  }
}
