import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/cart/cart_item.dart';
import '../model/cart/server_cart.dart';
import '../model/product/catalog_models.dart';
import '../service/shopping/customer_shopping_service.dart';
import '../service/api/api_exception.dart';
import 'auth_provider.dart';

enum CartAddResult { added, outOfStock, invalidQuantity }

class CartProvider extends ChangeNotifier {
  static const maxQuantity = 99;
  CartProvider({this.repository, AuthProvider? auth}) : _auth = auth {
    auth?.addListener(_authChanged);
    _authChanged();
  }
  final CustomerShoppingRepository? repository;
  final AuthProvider? _auth;
  List<CartItem> _items = [];
  List<CartItem> _pendingGuest = [];
  final Map<String, int> _serverIds = {};
  DecimalValue? _serverSubtotal;
  bool loading = false, mutating = false, merging = false;
  String? error;
  List<ShoppingWarning> warnings = [];
  int? _customer;
  int _generation = 0;
  bool get authenticated => _auth?.authenticated == true;
  List<CartItem> get items => List.unmodifiable(_items);
  int get lineCount => _items.length;
  int get totalQuantity => _items.fold(0, (s, e) => s + e.quantity);
  DecimalValue get subtotal => authenticated && _serverSubtotal != null
      ? _serverSubtotal!
      : _items.fold(DecimalValue.fromInput('0'), (s, e) => s.add(e.subtotal));
  void _authChanged() {
    final next = _auth?.authenticated == true
        ? _auth!.profile!.customerId
        : null;
    if (next == _customer) return;
    _customer = next;
    final g = ++_generation;
    if (next == null) {
      _items = [];
      _pendingGuest = [];
      _serverIds.clear();
      _serverSubtotal = null;
      loading = mutating = merging = false;
      error = null;
      warnings = [];
      notifyListeners();
    } else {
      _pendingGuest = List.of(_items);
      unawaited(_synchronize(g));
    }
  }

  Future<void> _synchronize(int g) async {
    if (repository == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      _apply(await repository!.getCart());
      if (_pendingGuest.isNotEmpty) {
        merging = true;
        notifyListeners();
        final payload = _pendingGuest
            .map(
              (e) => <String, Object?>{
                'productId': e.productId,
                'variationId': e.variationId,
                'quantity': e.quantity,
              },
            )
            .toList();
        final id = 'cart-$_customer-${DateTime.now().microsecondsSinceEpoch}';
        _apply(await repository!.mergeCart(id, payload));
        _pendingGuest = [];
      }
      if (g != _generation) return;
    } catch (e) {
      if (g == _generation) error = _message(e);
    } finally {
      if (g == _generation) {
        loading = false;
        merging = false;
        notifyListeners();
      }
    }
  }

  void _apply(ServerCart c) {
    _serverIds
      ..clear()
      ..addEntries(c.items.map((e) => MapEntry(e.identity, e.itemId)));
    _items = c.items
        .map(
          (e) => CartItem(
            productId: e.productId,
            productName: e.productName,
            imageUrl: e.imageUrl,
            code: e.code,
            variationId: e.variationId,
            variationName: e.variationName,
            unitPrice: e.unitPrice,
            quantity: e.quantity,
            stockLabel: e.stockLabel,
          ),
        )
        .toList();
    _serverSubtotal = c.subtotal;
    warnings = c.warnings;
    error = null;
  }

  CartAddResult add(
    ProductSummary p, {
    ProductVariation? variation,
    int quantity = 1,
  }) {
    if (!p.stock.inStock || p.stock.stockLabel == 'Out of Stock') {
      return CartAddResult.outOfStock;
    }
    if (quantity < 1 || quantity > maxQuantity) {
      return CartAddResult.invalidQuantity;
    }
    if (authenticated && repository != null) {
      unawaited(addRemote(p, variation: variation, quantity: quantity));
      return CartAddResult.added;
    }
    final item = CartItem.fromProduct(
      p,
      variation: variation,
      quantity: quantity,
    );
    final i = _items.indexWhere((e) => e.identity == item.identity);
    if (i < 0) {
      _items = [..._items, item];
    } else {
      final next = [..._items];
      next[i] = next[i].copyWith(
        quantity: (_items[i].quantity + quantity).clamp(1, maxQuantity),
      );
      _items = next;
    }
    notifyListeners();
    return CartAddResult.added;
  }

  Future<CartAddResult> addRemote(
    ProductSummary p, {
    ProductVariation? variation,
    int quantity = 1,
  }) async {
    if (!authenticated || repository == null) {
      return add(p, variation: variation, quantity: quantity);
    }
    if (quantity < 1 || quantity > 99) return CartAddResult.invalidQuantity;
    await _mutate(() => repository!.addCart(p.id, variation?.id, quantity));
    return error == null ? CartAddResult.added : CartAddResult.invalidQuantity;
  }

  bool setQuantity(String id, int q) {
    if (q < 1 || q > 99) return false;
    if (authenticated && repository != null) {
      final itemId = _serverIds[id];
      if (itemId != null) {
        unawaited(_mutate(() => repository!.updateCart(itemId, q)));
      }
      return itemId != null;
    }
    final i = _items.indexWhere((e) => e.identity == id);
    if (i < 0) return false;
    final n = [..._items];
    n[i] = n[i].copyWith(quantity: q);
    _items = n;
    notifyListeners();
    return true;
  }

  void increase(String id) {
    final i = _items.indexWhere((e) => e.identity == id);
    if (i >= 0 && _items[i].quantity < 99) {
      setQuantity(id, _items[i].quantity + 1);
    }
  }

  void decrease(String id) {
    final i = _items.indexWhere((e) => e.identity == id);
    if (i >= 0 && _items[i].quantity > 1) {
      setQuantity(id, _items[i].quantity - 1);
    }
  }

  void remove(String id) {
    if (authenticated && repository != null) {
      final itemId = _serverIds[id];
      if (itemId != null) {
        unawaited(_mutate(() => repository!.removeCart(itemId)));
      }
      return;
    }
    final n = _items.where((e) => e.identity != id).toList();
    if (n.length != _items.length) {
      _items = n;
      notifyListeners();
    }
  }

  void clear() {
    if (authenticated && repository != null) {
      unawaited(_mutate(repository!.clearCart));
      return;
    }
    if (_items.isNotEmpty) {
      _items = [];
      notifyListeners();
    }
  }

  Future<void> validate() async {
    if (repository != null && authenticated) {
      await _mutate(repository!.validateCart);
    }
  }

  Future<void> retry() async {
    if (authenticated) await _synchronize(_generation);
  }

  Future<void> _mutate(Future<ServerCart> Function() action) async {
    if (mutating) return;
    mutating = true;
    error = null;
    notifyListeners();
    try {
      _apply(await action());
    } catch (e) {
      error = _message(e);
    } finally {
      mutating = false;
      notifyListeners();
    }
  }

  String _message(Object e) => userSafeApiMessage(e);
  @override
  void dispose() {
    _auth?.removeListener(_authChanged);
    super.dispose();
  }
}
