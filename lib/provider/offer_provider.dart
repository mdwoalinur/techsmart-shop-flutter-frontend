import 'package:flutter/foundation.dart';

import '../model/common/api_models.dart';
import '../model/offer/offer_models.dart';
import '../service/offer/offer_service.dart';

enum OfferLoadState { idle, loading, loaded, error }

class OfferProvider extends ChangeNotifier {
  OfferProvider(this._repo);
  final OfferRepository _repo;
  OfferLoadState state = OfferLoadState.idle;
  String? error;
  List<OfferSummary> offers = const [];
  OfferDetail? selected;
  List<OfferProduct> products = const [];
  ApiPage<OfferProduct>? page;
  bool loadingMore = false;

  Future<void> loadOffers({bool force = false}) async {
    if (!force && state == OfferLoadState.loaded) return;
    state = OfferLoadState.loading;
    error = null;
    notifyListeners();
    try {
      offers = await _repo.fetchOffers();
      state = OfferLoadState.loaded;
    } catch (e) {
      error = e is OfferRequestException ? e.message : 'Unable to load offers.';
      state = OfferLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadDetail(int id) async {
    state = OfferLoadState.loading;
    error = null;
    selected = null;
    products = const [];
    page = null;
    notifyListeners();
    try {
      selected = await _repo.fetchOffer(id);
      page = await _repo.fetchOfferProducts(id);
      products = page!.content;
      state = OfferLoadState.loaded;
    } catch (e) {
      error = e is OfferRequestException ? e.message : 'Unable to load offer.';
      state = OfferLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    final current = page;
    final offer = selected;
    if (loadingMore || current == null || offer == null || current.last) return;
    loadingMore = true;
    notifyListeners();
    try {
      final next = await _repo.fetchOfferProducts(
        offer.id,
        page: current.page + 1,
      );
      page = next;
      products = List.unmodifiable([...products, ...next.content]);
    } catch (e) {
      error = e is OfferRequestException
          ? e.message
          : 'Unable to load more products.';
    }
    loadingMore = false;
    notifyListeners();
  }
}
