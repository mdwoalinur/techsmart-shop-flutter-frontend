import '../product/catalog_models.dart';

class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.code,
    this.variationId,
    this.variationName,
    required this.unitPrice,
    required this.quantity,
    required this.stockLabel,
  });
  final int productId;
  final String productName;
  final String? imageUrl;
  final String code;
  final int? variationId;
  final String? variationName;
  final DecimalValue unitPrice;
  final int quantity;
  final String stockLabel;
  String get identity => '$productId:${variationId ?? 'base'}';
  DecimalValue get subtotal => unitPrice.multiply(quantity);
  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    productName: productName,
    imageUrl: imageUrl,
    code: code,
    variationId: variationId,
    variationName: variationName,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
    stockLabel: stockLabel,
  );
  factory CartItem.fromProduct(
    ProductSummary p, {
    ProductVariation? variation,
    int quantity = 1,
  }) => CartItem(
    productId: p.id,
    productName: p.name,
    imageUrl: variation?.imageUrl ?? p.imageUrl,
    code: variation?.sku ?? p.sku ?? p.productCode,
    variationId: variation?.id,
    variationName: variation?.name,
    unitPrice: variation?.effectivePrice ?? p.sellingPrice,
    quantity: quantity,
    stockLabel: p.stock.stockLabel,
  );
}
