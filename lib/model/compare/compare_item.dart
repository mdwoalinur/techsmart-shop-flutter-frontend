import '../product/catalog_models.dart';

class CompareItem {
  const CompareItem({
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.stock,
    this.category,
    this.unit,
    required this.productCode,
    this.sku,
  });
  final int productId;
  final String name;
  final String? imageUrl;
  final DecimalValue price;
  final StockAvailability stock;
  final String? category;
  final String? unit;
  final String productCode;
  final String? sku;
  factory CompareItem.fromProduct(ProductSummary p) => CompareItem(
    productId: p.id,
    name: p.name,
    imageUrl: p.imageUrl,
    price: p.sellingPrice,
    stock: p.stock,
    category: p.category?.name,
    unit: p.unit?.name,
    productCode: p.productCode,
    sku: p.sku,
  );
}
