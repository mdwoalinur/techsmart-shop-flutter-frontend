import '../common/api_models.dart';

class ReviewSummary {
  const ReviewSummary({
    required this.productId,
    required this.averageRating,
    required this.reviewCount,
  });

  final int productId;
  final DecimalRating averageRating;
  final int reviewCount;

  factory ReviewSummary.fromJson(Object? value) {
    final j = unwrapDataMap(value, 'reviewSummary');
    return ReviewSummary(
      productId: requireInt(j, 'productId'),
      averageRating: DecimalRating.fromJson(j['averageRating']),
      reviewCount: requireInt(j, 'reviewCount'),
    );
  }
}

class DecimalRating {
  const DecimalRating(this.value);
  final String value;
  factory DecimalRating.fromJson(Object? value) {
    if (value is num && value.isFinite) return DecimalRating(value.toString());
    return const DecimalRating('0');
  }
  double get asDouble => double.tryParse(value) ?? 0;
}

class ProductReview {
  const ProductReview({
    required this.reviewNumber,
    required this.productId,
    required this.productName,
    required this.customerDisplayName,
    required this.orderNumber,
    required this.rating,
    this.title,
    this.comment,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String reviewNumber;
  final int productId;
  final String productName;
  final String customerDisplayName;
  final String orderNumber;
  final int rating;
  final String? title, comment, status;
  final DateTime? createdAt, updatedAt;

  factory ProductReview.fromJson(Object? value) {
    final j = unwrapDataMap(value, 'review');
    return ProductReview(
      reviewNumber: requireString(j, 'reviewNumber'),
      productId: requireInt(j, 'productId'),
      productName: (j['productName'] as String?) ?? 'Product',
      customerDisplayName: (j['customerDisplayName'] as String?) ?? 'Customer',
      orderNumber: (j['orderNumber'] as String?) ?? '',
      rating: requireInt(j, 'rating'),
      title: j['title'] as String?,
      comment: j['comment'] as String?,
      status: j['status'] as String?,
      createdAt: parseOptionalDate(j['createdAt']),
      updatedAt: parseOptionalDate(j['updatedAt']),
    );
  }
}

class ReviewableItem {
  const ReviewableItem({
    required this.orderNumber,
    required this.orderItemId,
    required this.productId,
    required this.productName,
    this.variationName,
    this.imageUrl,
    required this.delivered,
    required this.alreadyReviewed,
    this.existingReviewNumber,
    this.existingReviewStatus,
  });

  final String orderNumber;
  final int orderItemId, productId;
  final String productName;
  final String? variationName,
      imageUrl,
      existingReviewNumber,
      existingReviewStatus;
  final bool delivered, alreadyReviewed;

  factory ReviewableItem.fromJson(Object? value) {
    final j = unwrapDataMap(value, 'reviewableItem');
    return ReviewableItem(
      orderNumber: requireString(j, 'orderNumber'),
      orderItemId: requireInt(j, 'orderItemId'),
      productId: requireInt(j, 'productId'),
      productName: requireString(j, 'productName'),
      variationName: j['variationName'] as String?,
      imageUrl: j['imageUrl'] as String?,
      delivered: j['delivered'] == true,
      alreadyReviewed: j['alreadyReviewed'] == true,
      existingReviewNumber: j['existingReviewNumber'] as String?,
      existingReviewStatus: j['existingReviewStatus'] as String?,
    );
  }
}

Map<String, Object?> unwrapDataMap(Object? value, String field) {
  if (value is Map<String, Object?> && value.containsKey('success')) {
    return requireMap(value['data'], field);
  }
  return requireMap(value, field);
}

Object? unwrapData(Object? value) {
  if (value is Map<String, Object?> && value.containsKey('success')) {
    return value['data'];
  }
  return value;
}

DateTime? parseOptionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
