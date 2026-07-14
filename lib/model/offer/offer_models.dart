import '../common/api_models.dart';
import '../product/catalog_models.dart';

class OfferSummary {
  const OfferSummary({
    required this.id,
    required this.code,
    required this.title,
    this.subtitle,
    this.description,
    this.bannerUrl,
    this.channel,
    required this.startAt,
    required this.endAt,
    required this.productCount,
  });
  final int id;
  final String code;
  final String title;
  final String? subtitle;
  final String? description;
  final String? bannerUrl;
  final String? channel;
  final DateTime startAt;
  final DateTime endAt;
  final int productCount;

  factory OfferSummary.fromJson(Object? value) {
    final j = requireMap(value, 'offer');
    return OfferSummary(
      id: requireInt(j, 'id'),
      code: requireString(j, 'code'),
      title: requireString(j, 'title'),
      subtitle: j['subtitle'] as String?,
      description: j['description'] as String?,
      bannerUrl: j['bannerUrl'] as String?,
      channel: j['channel'] as String?,
      startAt: DateTime.parse(requireString(j, 'startAt')),
      endAt: DateTime.parse(requireString(j, 'endAt')),
      productCount: requireInt(j, 'productCount'),
    );
  }
}

class OfferDetail extends OfferSummary {
  const OfferDetail({
    required super.id,
    required super.code,
    required super.title,
    super.subtitle,
    super.description,
    super.bannerUrl,
    super.channel,
    required super.startAt,
    required super.endAt,
    required super.productCount,
  });
  factory OfferDetail.fromJson(Object? value) {
    final s = OfferSummary.fromJson(value);
    return OfferDetail(
      id: s.id,
      code: s.code,
      title: s.title,
      subtitle: s.subtitle,
      description: s.description,
      bannerUrl: s.bannerUrl,
      channel: s.channel,
      startAt: s.startAt,
      endAt: s.endAt,
      productCount: s.productCount,
    );
  }
}

class OfferProduct extends ProductSummary {
  const OfferProduct({
    required super.id,
    required super.productCode,
    super.sku,
    required super.name,
    super.description,
    required super.sellingPrice,
    required super.originalPrice,
    required super.savingsAmount,
    super.savingsLabel,
    super.taxRate,
    super.imageUrl,
    super.category,
    super.unit,
    required super.stock,
    required super.offerId,
    required super.offerTitle,
  });

  factory OfferProduct.fromJson(Object? value) {
    final j = requireMap(value, 'offerProduct');
    final p = ProductSummary.fromJson(j);
    return OfferProduct(
      id: p.id,
      productCode: p.productCode,
      sku: p.sku,
      name: p.name,
      description: p.description,
      sellingPrice: p.sellingPrice,
      originalPrice: DecimalValue.fromJson(j['originalPrice'], 'originalPrice'),
      savingsAmount: DecimalValue.fromJson(j['savingsAmount'], 'savingsAmount'),
      savingsLabel: j['savingsLabel'] as String?,
      taxRate: p.taxRate,
      imageUrl: p.imageUrl,
      category: p.category,
      unit: p.unit,
      stock: p.stock,
      offerId: requireInt(j, 'offerId'),
      offerTitle: requireString(j, 'offerTitle'),
    );
  }
}
