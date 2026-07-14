import '../product/catalog_models.dart';

class WishlistItem {
  const WishlistItem({
    required this.productId,
    required this.name,
    required this.productCode,
    this.imageUrl,
    required this.price,
    required this.stock,
    this.category,
  });
  final int productId;
  final String name;
  final String productCode;
  final String? imageUrl;
  final DecimalValue price;
  final StockAvailability stock;
  final String? category;
  factory WishlistItem.fromProduct(ProductSummary p) => WishlistItem(
    productId: p.id,
    name: p.name,
    productCode: p.productCode,
    imageUrl: p.imageUrl,
    price: p.sellingPrice,
    stock: p.stock,
    category: p.category?.name,
  );
}
