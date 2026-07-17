import '../common/api_models.dart';

class DecimalValue {
  DecimalValue._(this.value);
  final String value;

  factory DecimalValue.fromJson(Object? value, String field) {
    if (value is! num || !value.isFinite) {
      throw CatalogParseException('$field must be a finite number.', value);
    }
    return DecimalValue._(value.toString());
  }

  factory DecimalValue.fromInput(String value) {
    final parsed = num.tryParse(value.trim());
    if (parsed == null || !parsed.isFinite) {
      throw const FormatException('Enter a valid number.');
    }
    return DecimalValue._(value.trim());
  }

  DecimalValue multiply(int quantity) {
    if (quantity < 0) {
      throw const FormatException('Quantity cannot be negative.');
    }
    final parts = value.split('.');
    final scale = parts.length == 2 ? parts[1].length : 0;
    final result =
        BigInt.parse(value.replaceAll('.', '')) * BigInt.from(quantity);
    return DecimalValue._(_fromScaled(result, scale));
  }

  DecimalValue add(DecimalValue other) {
    final a = value.contains('.') ? value.split('.')[1].length : 0;
    final b = other.value.contains('.') ? other.value.split('.')[1].length : 0;
    final scale = a > b ? a : b;
    BigInt scaled(String text, int current) =>
        BigInt.parse(text.replaceAll('.', '')) *
        BigInt.from(10).pow(scale - current);
    return DecimalValue._(
      _fromScaled(scaled(value, a) + scaled(other.value, b), scale),
    );
  }

  static String _fromScaled(BigInt result, int scale) {
    if (scale == 0) return result.toString();
    final digits = result.abs().toString().padLeft(scale + 1, '0');
    final split = digits.length - scale;
    return '${result.isNegative ? '-' : ''}${digits.substring(0, split)}.${digits.substring(split)}';
  }

  num get numericValue => num.parse(value);
  @override
  String toString() => value;
}

abstract final class MoneyFormatter {
  static String taka(DecimalValue amount) {
    final parts = amount.value.split('.');
    final sign = parts.first.startsWith('-') ? '-' : '';
    final digits = parts.first.replaceFirst('-', '');
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final fraction = parts.length > 1 && int.tryParse(parts[1]) != 0
        ? '.${parts[1]}'
        : '';
    return '$sign\u09F3$grouped$fraction';
  }
}

class CategorySummary {
  const CategorySummary({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.root,
    required this.active,
  });
  final int id;
  final String name;
  final String? description;
  final int? parentId;
  final bool root;
  final bool active;
  factory CategorySummary.fromJson(Object? value) {
    final json = requireMap(value, 'category');
    return CategorySummary(
      id: requireInt(json, 'id'),
      name: requireString(json, 'name'),
      description: json['description'] as String?,
      parentId: json['parentId'] as int?,
      root: requireBool(json, 'root'),
      active: requireBool(json, 'active'),
    );
  }
}

class CategoryDetail extends CategorySummary {
  const CategoryDetail({
    required super.id,
    required super.name,
    super.description,
    super.parentId,
    required super.root,
    required super.active,
    required this.children,
  });
  final List<CategorySummary> children;
  factory CategoryDetail.fromJson(Object? value) {
    final json = requireMap(value, 'categoryDetail');
    final summary = CategorySummary.fromJson(json);
    final raw = json['children'];
    if (raw is! List<Object?>) {
      throw CatalogParseException('children must be an array.', raw);
    }
    return CategoryDetail(
      id: summary.id,
      name: summary.name,
      description: summary.description,
      parentId: summary.parentId,
      root: summary.root,
      active: summary.active,
      children: List.unmodifiable(raw.map(CategorySummary.fromJson)),
    );
  }
}

class UnitSummary {
  const UnitSummary({required this.id, required this.name, required this.code});
  final int id;
  final String name;
  final String code;
  factory UnitSummary.fromJson(Object? value) {
    final j = requireMap(value, 'unit');
    return UnitSummary(
      id: requireInt(j, 'id'),
      name: requireString(j, 'name'),
      code: requireString(j, 'code'),
    );
  }
}

class StockAvailability {
  const StockAvailability({required this.inStock, required this.stockLabel});
  final bool inStock;
  final String stockLabel;
  factory StockAvailability.fromJson(Object? value) {
    final j = requireMap(value, 'stock');
    return StockAvailability(
      inStock: requireBool(j, 'inStock'),
      stockLabel: requireString(j, 'stockLabel'),
    );
  }
}

class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.productCode,
    this.sku,
    required this.name,
    this.description,
    required this.sellingPrice,
    this.originalPrice,
    this.savingsAmount,
    this.savingsLabel,
    this.offerId,
    this.offerTitle,
    this.taxRate,
    this.imageUrl,
    this.category,
    this.unit,
    required this.stock,
  });
  final int id;
  final String productCode;
  final String? sku;
  final String name;
  final String? description;
  final DecimalValue sellingPrice;
  final DecimalValue? originalPrice;
  final DecimalValue? savingsAmount;
  final String? savingsLabel;
  final int? offerId;
  final String? offerTitle;
  final DecimalValue? taxRate;
  final String? imageUrl;
  final CategorySummary? category;
  final UnitSummary? unit;
  final StockAvailability stock;
  factory ProductSummary.fromJson(Object? value) {
    final j = requireMap(value, 'product');
    return ProductSummary(
      id: requireInt(j, 'id'),
      productCode: requireString(j, 'productCode'),
      sku: j['sku'] as String?,
      name: requireString(j, 'name'),
      description: j['description'] as String?,
      sellingPrice: DecimalValue.fromJson(j['sellingPrice'], 'sellingPrice'),
      originalPrice: j['originalPrice'] == null
          ? null
          : DecimalValue.fromJson(j['originalPrice'], 'originalPrice'),
      savingsAmount: j['savingsAmount'] == null
          ? null
          : DecimalValue.fromJson(j['savingsAmount'], 'savingsAmount'),
      savingsLabel: j['savingsLabel'] as String?,
      offerId: j['offerId'] as int?,
      offerTitle: j['offerTitle'] as String?,
      taxRate: j['taxRate'] == null
          ? null
          : DecimalValue.fromJson(j['taxRate'], 'taxRate'),
      imageUrl: j['imageUrl'] as String?,
      category: j['category'] == null
          ? null
          : CategorySummary.fromJson(j['category']),
      unit: j['unit'] == null ? null : UnitSummary.fromJson(j['unit']),
      stock: StockAvailability.fromJson(j['stock']),
    );
  }
}

class ProductVariation {
  const ProductVariation({
    required this.id,
    required this.name,
    this.sku,
    required this.effectivePrice,
    required this.additionalPrice,
    this.imageUrl,
    required this.stock,
  });
  final int id;
  final String name;
  final String? sku;
  final DecimalValue effectivePrice;
  final DecimalValue additionalPrice;
  final String? imageUrl;
  final StockAvailability stock;
  factory ProductVariation.fromJson(Object? value) {
    final j = requireMap(value, 'variation');
    return ProductVariation(
      id: requireInt(j, 'id'),
      name: requireString(j, 'name'),
      sku: j['sku'] as String?,
      effectivePrice: DecimalValue.fromJson(
        j['effectivePrice'],
        'effectivePrice',
      ),
      additionalPrice: DecimalValue.fromJson(
        j['additionalPrice'],
        'additionalPrice',
      ),
      imageUrl: j['imageUrl'] as String?,
      stock: StockAvailability.fromJson(j['stock']),
    );
  }
}

class ProductDetail extends ProductSummary {
  const ProductDetail({
    required super.id,
    required super.productCode,
    super.sku,
    required super.name,
    super.description,
    required super.sellingPrice,
    super.originalPrice,
    super.savingsAmount,
    super.savingsLabel,
    super.offerId,
    super.offerTitle,
    super.taxRate,
    super.imageUrl,
    super.category,
    super.unit,
    required super.stock,
    required this.variations,
    this.averageRating = 0,
    this.reviewCount = 0,
  });
  final List<ProductVariation> variations;
  final double averageRating;
  final int reviewCount;
  factory ProductDetail.fromJson(Object? value) {
    final j = requireMap(value, 'productDetail');
    final p = ProductSummary.fromJson(j);
    final raw = j['variations'];
    if (raw is! List<Object?>) {
      throw CatalogParseException('variations must be an array.', raw);
    }
    return ProductDetail(
      id: p.id,
      productCode: p.productCode,
      sku: p.sku,
      name: p.name,
      description: p.description,
      sellingPrice: p.sellingPrice,
      originalPrice: p.originalPrice,
      savingsAmount: p.savingsAmount,
      savingsLabel: p.savingsLabel,
      offerId: p.offerId,
      offerTitle: p.offerTitle,
      taxRate: p.taxRate,
      imageUrl: p.imageUrl,
      category: p.category,
      unit: p.unit,
      stock: p.stock,
      variations: List.unmodifiable(raw.map(ProductVariation.fromJson)),
      averageRating: (j['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }
}
