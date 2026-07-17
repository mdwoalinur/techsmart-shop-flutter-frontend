import '../../model/review/review_models.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

abstract interface class ReviewRepository {
  Future<ReviewSummary> summary(int productId);
  Future<List<ProductReview>> productReviews(int productId);
  Future<List<ReviewableItem>> reviewableItems(String orderNumber);
  Future<List<ProductReview>> myReviews();
  Future<ProductReview> createReview({
    required int productId,
    required String orderNumber,
    required int orderItemId,
    required int rating,
    String? title,
    required String comment,
  });
  Future<ProductReview> updateReview({
    required String reviewNumber,
    int? rating,
    String? title,
    String? comment,
  });
}

class ReviewService implements ReviewRepository {
  const ReviewService(this._client);
  final ApiClient _client;

  @override
  Future<ReviewSummary> summary(int productId) async =>
      ReviewSummary.fromJson(await _get('products/$productId/review-summary'));

  @override
  Future<List<ProductReview>> productReviews(int productId) async {
    final raw = unwrapData(await _get('products/$productId/reviews'));
    if (raw is! List<Object?>) {
      throw const FormatException('reviews must be an array.');
    }
    return List.unmodifiable(raw.map(ProductReview.fromJson));
  }

  @override
  Future<List<ReviewableItem>> reviewableItems(String orderNumber) async {
    final raw = unwrapData(
      await _get('orders/$orderNumber/reviewable-items', auth: true),
    );
    if (raw is! List<Object?>) {
      throw const FormatException('reviewable items must be an array.');
    }
    return List.unmodifiable(raw.map(ReviewableItem.fromJson));
  }

  @override
  Future<List<ProductReview>> myReviews() async {
    final raw = unwrapData(await _get('reviews/my', auth: true));
    final source = raw is Map<String, Object?> ? raw['reviews'] : raw;
    if (source is! List<Object?>) {
      throw const FormatException('my reviews must be an array.');
    }
    return List.unmodifiable(source.map(ProductReview.fromJson));
  }

  @override
  Future<ProductReview> createReview({
    required int productId,
    required String orderNumber,
    required int orderItemId,
    required int rating,
    String? title,
    required String comment,
  }) async {
    final body = <String, Object?>{
      'orderNumber': orderNumber,
      'orderItemId': orderItemId,
      'rating': rating,
      'comment': comment,
    };
    final cleanTitle = title?.trim();
    if (cleanTitle?.isNotEmpty == true) {
      body['title'] = cleanTitle;
    }
    return ProductReview.fromJson(
      await _post('products/$productId/reviews', body),
    );
  }

  @override
  Future<ProductReview> updateReview({
    required String reviewNumber,
    int? rating,
    String? title,
    String? comment,
  }) async {
    final body = <String, Object?>{};
    if (rating != null) {
      body['rating'] = rating;
    }
    if (title != null) {
      body['title'] = title;
    }
    if (comment != null) {
      body['comment'] = comment;
    }
    return ProductReview.fromJson(await _put('reviews/$reviewNumber', body));
  }

  Future<Object?> _get(String path, {bool auth = false}) =>
      _safe(() => _client.get(path, authenticated: auth));
  Future<Object?> _post(String path, Object body) =>
      _safe(() => _client.post(path, body: body, authenticated: true));
  Future<Object?> _put(String path, Object body) =>
      _safe(() => _client.put(path, body: body, authenticated: true));

  Future<Object?> _safe(Future<Object?> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw ReviewRequestException(
        userSafeApiMessage(e),
        statusCode: e.statusCode,
        cause: e,
      );
    } on FormatException catch (e) {
      throw ReviewRequestException(
        'The server returned unexpected review data.',
        cause: e,
      );
    }
  }
}

class ReviewRequestException implements Exception {
  const ReviewRequestException(this.message, {this.statusCode, this.cause});
  final String message;
  final int? statusCode;
  final Object? cause;
}
