import '../../model/cart/server_cart.dart';
import '../../model/wishlist/server_wishlist.dart';
import '../api/api_client.dart';

abstract class CustomerShoppingRepository {
  Future<ServerCart> getCart();
  Future<ServerCart> addCart(int productId, int? variationId, int quantity);
  Future<ServerCart> updateCart(int itemId, int quantity);
  Future<ServerCart> removeCart(int itemId);
  Future<ServerCart> clearCart();
  Future<ServerCart> mergeCart(
    String requestId,
    List<Map<String, Object?>> items,
  );
  Future<ServerCart> validateCart();
  Future<ServerWishlist> getWishlist();
  Future<ServerWishlist> addWishlist(int productId);
  Future<ServerWishlist> removeWishlist(int productId);
  Future<ServerWishlist> clearWishlist();
  Future<ServerWishlist> mergeWishlist(String requestId, List<int> ids);
}

class CustomerShoppingService implements CustomerShoppingRepository {
  CustomerShoppingService(this.client);
  final ApiClient client;

  @override
  Future<ServerCart> getCart() async =>
      ServerCart.fromJson(await client.get('cart', authenticated: true));
  @override
  Future<ServerCart> addCart(int p, int? v, int q) async => ServerCart.fromJson(
    await client.post(
      'cart/items',
      authenticated: true,
      body: {'productId': p, 'variationId': v, 'quantity': q},
    ),
  );
  @override
  Future<ServerCart> updateCart(int id, int q) async => ServerCart.fromJson(
    await client.put(
      'cart/items/$id',
      authenticated: true,
      body: {'quantity': q},
    ),
  );
  @override
  Future<ServerCart> removeCart(int id) async => ServerCart.fromJson(
    await client.delete('cart/items/$id', authenticated: true),
  );
  @override
  Future<ServerCart> clearCart() async =>
      ServerCart.fromJson(await client.delete('cart', authenticated: true));
  @override
  Future<ServerCart> mergeCart(
    String id,
    List<Map<String, Object?>> items,
  ) async => ServerCart.fromJson(
    await client.post(
      'cart/merge-session',
      authenticated: true,
      body: {'requestId': id, 'items': items},
    ),
  );
  @override
  Future<ServerCart> validateCart() async => ServerCart.fromJson(
    await client.post('cart/validate', authenticated: true),
  );
  @override
  Future<ServerWishlist> getWishlist() async => ServerWishlist.fromJson(
    await client.get('wishlist', authenticated: true),
  );
  @override
  Future<ServerWishlist> addWishlist(int p) async => ServerWishlist.fromJson(
    await client.post(
      'wishlist/items',
      authenticated: true,
      body: {'productId': p},
    ),
  );
  @override
  Future<ServerWishlist> removeWishlist(int p) async => ServerWishlist.fromJson(
    await client.delete('wishlist/items/$p', authenticated: true),
  );
  @override
  Future<ServerWishlist> clearWishlist() async => ServerWishlist.fromJson(
    await client.delete('wishlist', authenticated: true),
  );
  @override
  Future<ServerWishlist> mergeWishlist(String id, List<int> ids) async =>
      ServerWishlist.fromJson(
        await client.post(
          'wishlist/merge-session',
          authenticated: true,
          body: {'requestId': id, 'productIds': ids},
        ),
      );
}
