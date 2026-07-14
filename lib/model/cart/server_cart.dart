import '../product/catalog_models.dart';

class ShoppingWarning {
  const ShoppingWarning(this.code, this.message);
  final String code, message;
  factory ShoppingWarning.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return ShoppingWarning(j['code'] as String, j['message'] as String);
  }
}

class ServerCartItem {
  const ServerCartItem({
    required this.itemId,
    required this.productId,
    this.variationId,
    required this.productName,
    required this.code,
    this.variationName,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.stockLabel,
    required this.available,
    this.validationMessage,
  });
  final int itemId, productId, quantity;
  final int? variationId;
  final String productName, code, stockLabel;
  final String? variationName, imageUrl, validationMessage;
  final DecimalValue unitPrice;
  final bool available;
  String get identity => '$productId:${variationId ?? 'base'}';
  factory ServerCartItem.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return ServerCartItem(
      itemId: (j['itemId'] as num).toInt(),
      productId: (j['productId'] as num).toInt(),
      variationId: (j['variationId'] as num?)?.toInt(),
      productName: j['productName'] as String,
      code: (j['sku'] ?? j['productCode'] ?? '') as String,
      variationName: j['variationName'] as String?,
      imageUrl: j['imageUrl'] as String?,
      unitPrice: DecimalValue.fromJson(j['unitPrice'], 'unitPrice'),
      quantity: (j['quantity'] as num).toInt(),
      stockLabel: j['stockLabel'] as String,
      available: j['availableForPurchase'] == true,
      validationMessage: j['validationMessage'] as String?,
    );
  }
}

class ServerCart {
  const ServerCart({
    required this.items,
    required this.totalQuantity,
    required this.subtotal,
    required this.warnings,
  });
  final List<ServerCartItem> items;
  final int totalQuantity;
  final DecimalValue subtotal;
  final List<ShoppingWarning> warnings;
  factory ServerCart.fromJson(Object? v) {
    final j = v as Map<String, Object?>;
    return ServerCart(
      items: (j['items'] as List).map(ServerCartItem.fromJson).toList(),
      totalQuantity: (j['totalQuantity'] as num).toInt(),
      subtotal: DecimalValue.fromJson(j['subtotal'], 'subtotal'),
      warnings: (j['validationWarnings'] as List? ?? const [])
          .map(ShoppingWarning.fromJson)
          .toList(),
    );
  }
}
