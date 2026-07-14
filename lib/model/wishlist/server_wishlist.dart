import '../cart/server_cart.dart';
import '../product/catalog_models.dart';

class ServerWishlistItem {
  const ServerWishlistItem({
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.stockLabel,
    this.category,
  });
  final int productId;
  final String name, stockLabel;
  final String? imageUrl, category;
  final DecimalValue price;
  factory ServerWishlistItem.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return ServerWishlistItem(
      productId: (j['productId'] as num).toInt(),
      name: j['productName'] as String,
      imageUrl: j['imageUrl'] as String?,
      price: DecimalValue.fromJson(j['sellingPrice'], 'sellingPrice'),
      stockLabel: j['stockLabel'] as String,
      category: j['category'] as String?,
    );
  }
}

class ServerWishlist {
  const ServerWishlist({required this.items, required this.warnings});
  final List<ServerWishlistItem> items;
  final List<ShoppingWarning> warnings;
  factory ServerWishlist.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return ServerWishlist(
      items: (j['items'] as List).map(ServerWishlistItem.fromJson).toList(),
      warnings: (j['validationWarnings'] as List? ?? const [])
          .map(ShoppingWarning.fromJson)
          .toList(),
    );
  }
}
