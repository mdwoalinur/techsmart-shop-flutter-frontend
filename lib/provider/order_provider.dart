import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/order/order_models.dart';
import '../model/tracking/order_tracking_models.dart';
import '../service/order/order_service.dart';
import '../service/api/api_exception.dart';
import 'auth_provider.dart';

enum OrderLoadState { idle, loading, loaded, refreshing, loadingMore, error }

class OrderProvider extends ChangeNotifier {
  OrderProvider(this.repository, this.auth) {
    auth.addListener(_authChanged);
  }
  final OrderRepository repository;
  final AuthProvider auth;
  OrderLoadState state = OrderLoadState.idle;
  String? error;
  List<OrderSummary> orders = [];
  int page = 0;
  bool last = true;
  String sort = 'newest';
  String? orderStatus;
  String? paymentStatus;
  String? query;
  OrderDetail? selected;
  CancellationRequest? cancellation;
  ReturnRequest? returnRequest;
  ReturnRequestDraft? returnDraft;
  String? returnDraftError;
  OrderDocument? document;
  final Map<String, OrderTracking> trackingByOrderNumber = {};
  bool trackingLoading = false, refreshingTracking = false;
  String? trackingError;
  bool submittingCancellation = false,
      submittingReturn = false,
      loadingDocument = false;
  int? _customer;
  int _generation = 0;

  Future<void> load({bool refresh = false}) async {
    if (!auth.authenticated) return;
    final g = _generation;
    if (state == OrderLoadState.loading || state == OrderLoadState.refreshing) {
      return;
    }
    state = orders.isEmpty ? OrderLoadState.loading : OrderLoadState.refreshing;
    error = null;
    notifyListeners();
    try {
      final p = await repository.history(
        page: 0,
        size: 10,
        orderStatus: orderStatus,
        paymentStatus: paymentStatus,
        query: query,
        sort: sort,
      );
      if (g != _generation) return;
      orders = p.content;
      page = p.page;
      last = p.last;
      state = OrderLoadState.loaded;
    } catch (e) {
      if (g != _generation) return;
      error = userSafeApiMessage(e);
      state = orders.isEmpty ? OrderLoadState.error : OrderLoadState.loaded;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!auth.authenticated || last || state == OrderLoadState.loadingMore) {
      return;
    }
    final g = _generation;
    state = OrderLoadState.loadingMore;
    notifyListeners();
    try {
      final p = await repository.history(
        page: page + 1,
        size: 10,
        orderStatus: orderStatus,
        paymentStatus: paymentStatus,
        query: query,
        sort: sort,
      );
      if (g != _generation) return;
      orders = [...orders, ...p.content];
      page = p.page;
      last = p.last;
      state = OrderLoadState.loaded;
    } catch (e) {
      if (g != _generation) return;
      error = userSafeApiMessage(e);
      state = OrderLoadState.loaded;
    }
    notifyListeners();
  }

  Future<void> setFilters({
    String? status,
    String? pay,
    String? search,
    String? orderSort,
  }) async {
    orderStatus = status;
    paymentStatus = pay;
    query = search;
    sort = orderSort ?? sort;
    await load(refresh: true);
  }

  Future<void> loadDetail(String orderNumber) async {
    if (!auth.authenticated) return;
    final g = _generation;
    selected = null;
    cancellation = null;
    returnRequest = null;
    document = null;
    trackingError = null;
    error = null;
    notifyListeners();
    try {
      final d = await repository.detail(orderNumber);
      if (g != _generation) return;
      selected = d;
      unawaited(loadTracking(d.orderNumber));
      if (returnDraft != null && returnDraft!.orderNumber != d.orderNumber) {
        returnDraft = null;
        returnDraftError = null;
      }
    } catch (e) {
      if (g != _generation) return;
      error = userSafeApiMessage(e);
    }
    notifyListeners();
  }

  Future<bool> submitCancellation(String reason, {String? text}) async {
    final d = selected;
    if (d == null || submittingCancellation) return false;
    submittingCancellation = true;
    error = null;
    notifyListeners();
    try {
      cancellation = await repository.submitCancellation(
        d.orderNumber,
        reasonCode: reason,
        reasonText: text,
        idempotencyKey:
            'cancel-${d.orderNumber}-${DateTime.now().microsecondsSinceEpoch}',
      );
      await loadDetail(d.orderNumber);
      await load(refresh: true);
      return true;
    } catch (e) {
      error = userSafeApiMessage(e);
      return false;
    } finally {
      submittingCancellation = false;
      notifyListeners();
    }
  }

  void startReturnDraft(ReturnEligibility eligibility, String orderNumber) {
    if (returnDraft?.orderNumber == orderNumber &&
        returnDraft!.items.isNotEmpty) {
      returnDraftError = null;
      notifyListeners();
      return;
    }
    returnDraft = ReturnRequestDraft(
      orderNumber: orderNumber,
      items: eligibility.items
          .map((item) => ReturnRequestItemDraft(item: item))
          .toList(growable: false),
    );
    returnDraftError = null;
    notifyListeners();
  }

  void clearReturnDraft() {
    returnDraft = null;
    returnDraftError = null;
    notifyListeners();
  }

  void selectReturnItem(int itemId, bool selected) {
    _updateDraftItem(itemId, (item) => item.copyWith(selected: selected));
  }

  void updateReturnQuantity(int itemId, int quantity) {
    final draftItem = returnDraft?.items
        .where((e) => e.item.itemId == itemId)
        .firstOrNull;
    final max = draftItem?.item.remainingReturnableQuantity ?? 1;
    _updateDraftItem(
      itemId,
      (item) => item.copyWith(quantity: quantity.clamp(1, max).toInt()),
    );
  }

  void updateReturnReason(int itemId, String reasonCode) {
    _updateDraftItem(itemId, (item) => item.copyWith(reasonCode: reasonCode));
  }

  void updateReturnReasonText(int itemId, String? reasonText) {
    _updateDraftItem(
      itemId,
      (item) => item.copyWith(
        reasonText: reasonText == null || reasonText.trim().isEmpty
            ? null
            : reasonText.trim(),
      ),
    );
  }

  void updateReturnPreferredResolution(String value) {
    final draft = returnDraft;
    if (draft == null) return;
    returnDraft = draft.copyWith(preferredResolution: value);
    returnDraftError = null;
    notifyListeners();
  }

  void updateReturnComment(String? value) {
    final draft = returnDraft;
    if (draft == null) return;
    returnDraft = draft.copyWith(
      comment: value == null || value.trim().isEmpty ? null : value.trim(),
    );
    notifyListeners();
  }

  String? validateReturnDraft() {
    final draft = returnDraft;
    final message = draft?.validationMessage ?? 'Return request is not ready.';
    returnDraftError =
        message == 'Return request is not ready.' && draft != null
        ? null
        : draft?.validationMessage;
    notifyListeners();
    return draft?.validationMessage;
  }

  Future<bool> submitReturnDraft() async {
    final d = selected;
    var draft = returnDraft;
    if (d == null || draft == null || submittingReturn) return false;
    final validation = draft.validationMessage;
    if (validation != null) {
      returnDraftError = validation;
      notifyListeners();
      return false;
    }
    final key =
        draft.idempotencyKey ??
        'return-${d.orderNumber}-${DateTime.now().microsecondsSinceEpoch}';
    draft = draft.copyWith(idempotencyKey: key);
    returnDraft = draft;
    submittingReturn = true;
    error = null;
    returnDraftError = null;
    notifyListeners();
    try {
      final created = await repository.submitReturn(
        d.orderNumber,
        idempotencyKey: key,
        preferredResolution: draft.preferredResolution,
        comment: draft.comment,
        items: draft.selectedJsonItems(),
      );
      returnDraft = null;
      returnDraftError = null;
      await loadDetail(d.orderNumber);
      await load(refresh: true);
      returnRequest = created;
      return true;
    } catch (e) {
      error = userSafeApiMessage(e);
      returnDraftError = 'Return request was not submitted. Please retry.';
      return false;
    } finally {
      submittingReturn = false;
      notifyListeners();
    }
  }

  Future<bool> submitReturn({
    required String preferredResolution,
    String? comment,
    required List<Map<String, Object?>> items,
  }) async {
    final d = selected;
    if (d == null || submittingReturn) return false;
    submittingReturn = true;
    error = null;
    notifyListeners();
    try {
      final created = await repository.submitReturn(
        d.orderNumber,
        idempotencyKey:
            'return-${d.orderNumber}-${DateTime.now().microsecondsSinceEpoch}',
        preferredResolution: preferredResolution,
        comment: comment,
        items: items,
      );
      await loadDetail(d.orderNumber);
      await load(refresh: true);
      returnRequest = created;
      return true;
    } catch (e) {
      error = userSafeApiMessage(e);
      return false;
    } finally {
      submittingReturn = false;
      notifyListeners();
    }
  }

  Future<void> loadTracking(String orderNumber, {bool refresh = false}) async {
    if (!auth.authenticated) return;
    final g = _generation;
    if (trackingLoading || refreshingTracking) return;
    if (!refresh && trackingByOrderNumber.containsKey(orderNumber)) return;
    trackingLoading = !trackingByOrderNumber.containsKey(orderNumber);
    refreshingTracking = !trackingLoading;
    trackingError = null;
    notifyListeners();
    try {
      final value = await repository.tracking(orderNumber);
      if (g != _generation) return;
      trackingByOrderNumber[orderNumber] = value;
    } catch (e) {
      if (g != _generation) return;
      trackingError = userSafeApiMessage(e);
    } finally {
      if (g == _generation) {
        trackingLoading = false;
        refreshingTracking = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadDocument() async {
    final d = selected;
    if (d == null || loadingDocument) return;
    loadingDocument = true;
    error = null;
    notifyListeners();
    try {
      document = await repository.document(d.orderNumber);
    } catch (e) {
      error = userSafeApiMessage(e);
    } finally {
      loadingDocument = false;
      notifyListeners();
    }
  }

  void _updateDraftItem(
    int itemId,
    ReturnRequestItemDraft Function(ReturnRequestItemDraft item) update,
  ) {
    final draft = returnDraft;
    if (draft == null) return;
    returnDraft = draft.copyWith(
      items: draft.items
          .map((item) => item.item.itemId == itemId ? update(item) : item)
          .toList(growable: false),
    );
    returnDraftError = null;
    notifyListeners();
  }

  void _authChanged() {
    final n = auth.authenticated ? auth.profile!.customerId : null;
    if (n == _customer) return;
    _customer = n;
    ++_generation;
    orders = [];
    page = 0;
    last = true;
    selected = null;
    cancellation = null;
    returnRequest = null;
    returnDraft = null;
    returnDraftError = null;
    document = null;
    trackingError = null;
    error = null;
    trackingByOrderNumber.clear();
    trackingLoading = false;
    refreshingTracking = false;
    trackingError = null;
    state = OrderLoadState.idle;
    notifyListeners();
    if (n != null) unawaited(load());
  }

  @override
  void dispose() {
    auth.removeListener(_authChanged);
    super.dispose();
  }
}
