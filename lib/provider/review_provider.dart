import 'package:flutter/foundation.dart';

import '../model/review/review_models.dart';
import '../service/review/review_service.dart';
import 'auth_provider.dart';

enum ReviewLoadState { idle, loading, loaded, error }

class ReviewProvider extends ChangeNotifier {
  ReviewProvider(this.repository, this.auth) {
    auth.addListener(_authChanged);
  }

  final ReviewRepository repository;
  final AuthProvider auth;
  ReviewLoadState state = ReviewLoadState.idle;
  String? error;
  ReviewSummary? summary;
  List<ProductReview> productReviews = const [];
  List<ReviewableItem> reviewableItems = const [];
  List<ProductReview> myReviews = const [];
  bool submitting = false;
  int? _loadedProductId;

  Future<void> loadProduct(int productId, {bool force = false}) async {
    if (!force &&
        _loadedProductId == productId &&
        state == ReviewLoadState.loaded) {
      return;
    }
    _loadedProductId = productId;
    state = ReviewLoadState.loading;
    error = null;
    notifyListeners();
    try {
      final nextSummary = await repository.summary(productId);
      final nextReviews = await repository.productReviews(productId);
      summary = nextSummary;
      productReviews = nextReviews;
      state = ReviewLoadState.loaded;
    } catch (e) {
      error = e is ReviewRequestException
          ? e.message
          : 'Unable to load reviews.';
      state = ReviewLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadReviewable(String orderNumber) async {
    if (!auth.authenticated) return;
    state = ReviewLoadState.loading;
    error = null;
    notifyListeners();
    try {
      reviewableItems = await repository.reviewableItems(orderNumber);
      state = ReviewLoadState.loaded;
    } catch (e) {
      error = e is ReviewRequestException
          ? e.message
          : 'Unable to load reviewable items.';
      state = ReviewLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMine({bool force = false}) async {
    if (!auth.authenticated) return;
    if (!force && myReviews.isNotEmpty) return;
    state = ReviewLoadState.loading;
    error = null;
    notifyListeners();
    try {
      myReviews = await repository.myReviews();
      state = ReviewLoadState.loaded;
    } catch (e) {
      error = e is ReviewRequestException
          ? e.message
          : 'Unable to load your reviews.';
      state = ReviewLoadState.error;
    }
    notifyListeners();
  }

  Future<bool> submit({
    required ReviewableItem item,
    required int rating,
    String? title,
    required String comment,
  }) async {
    if (!auth.authenticated || submitting) return false;
    submitting = true;
    error = null;
    notifyListeners();
    try {
      final review = await repository.createReview(
        productId: item.productId,
        orderNumber: item.orderNumber,
        orderItemId: item.orderItemId,
        rating: rating,
        title: title,
        comment: comment,
      );
      reviewableItems = reviewableItems
          .map(
            (entry) => entry.orderItemId == item.orderItemId
                ? ReviewableItem(
                    orderNumber: entry.orderNumber,
                    orderItemId: entry.orderItemId,
                    productId: entry.productId,
                    productName: entry.productName,
                    variationName: entry.variationName,
                    imageUrl: entry.imageUrl,
                    delivered: entry.delivered,
                    alreadyReviewed: true,
                    existingReviewNumber: review.reviewNumber,
                    existingReviewStatus: review.status,
                  )
                : entry,
          )
          .toList(growable: false);
      myReviews = [review, ...myReviews];
      if (_loadedProductId == item.productId) {
        await loadProduct(item.productId, force: true);
      }
      submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e is ReviewRequestException
          ? e.message
          : 'Unable to submit review.';
      submitting = false;
      notifyListeners();
      return false;
    }
  }

  void _authChanged() {
    if (!auth.authenticated) clear();
  }

  void clear() {
    state = ReviewLoadState.idle;
    error = null;
    summary = null;
    productReviews = const [];
    reviewableItems = const [];
    myReviews = const [];
    submitting = false;
    _loadedProductId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    auth.removeListener(_authChanged);
    super.dispose();
  }
}
