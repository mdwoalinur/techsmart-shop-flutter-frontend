import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/address/address_models.dart';
import '../model/checkout/checkout_models.dart';
import '../service/checkout/checkout_service.dart';
import '../service/api/api_exception.dart';
import 'auth_provider.dart';

enum CheckoutState {
  idle,
  loadingReview,
  reviewReady,
  submitting,
  submitted,
  error,
}

class CheckoutProvider extends ChangeNotifier {
  CheckoutProvider(this.repository, this.auth) {
    auth.addListener(_authChanged);
  }
  final CheckoutRepository repository;
  final AuthProvider auth;
  List<CustomerAddress> addresses = [];
  List<DeliveryMethod> methods = [];
  CustomerAddress? selectedAddress;
  DeliveryMethod? selectedMethod;
  CheckoutReview? review;
  OrderConfirmation? confirmation;
  CheckoutState state = CheckoutState.idle;
  String? error;
  bool termsAccepted = false;
  String? _key;
  int? _customer;
  Future<void> loadPrerequisites() async {
    if (!auth.authenticated) return;
    try {
      addresses = await repository.addresses();
      selectedAddress =
          addresses.where((e) => e.isDefault).firstOrNull ??
          addresses.firstOrNull;
      methods = await repository.deliveryMethods(
        addressId: selectedAddress?.id,
      );
      selectedMethod = methods.where((e) => e.eligible).firstOrNull;
      error = null;
    } catch (e) {
      error = userSafeApiMessage(e);
      state = CheckoutState.error;
    }
    notifyListeners();
  }

  Future<bool> saveAddress(AddressDraft d, {int? id}) async {
    try {
      id == null
          ? await repository.createAddress(d)
          : await repository.updateAddress(id, d);
      await loadPrerequisites();
      return true;
    } catch (e) {
      error = userSafeApiMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteAddress(int id) async {
    await repository.deleteAddress(id);
    await loadPrerequisites();
  }

  Future<void> setDefault(int id) async {
    await repository.setDefault(id);
    await loadPrerequisites();
  }

  Future<void> selectAddress(CustomerAddress a) async {
    selectedAddress = a;
    selectedMethod = null;
    review = null;
    methods = await repository.deliveryMethods(addressId: a.id);
    notifyListeners();
  }

  void selectMethod(DeliveryMethod m) {
    selectedMethod = m;
    review = null;
    notifyListeners();
  }

  void setTerms(bool v) {
    termsAccepted = v;
    notifyListeners();
  }

  Future<void> requestReview() async {
    if (selectedAddress == null || selectedMethod == null) return;
    state = CheckoutState.loadingReview;
    error = null;
    notifyListeners();
    try {
      review = await repository.review(selectedAddress!.id, selectedMethod!.id);
      state = CheckoutState.reviewReady;
    } catch (e) {
      error = userSafeApiMessage(e);
      state = CheckoutState.error;
    }
    notifyListeners();
  }

  Future<bool> submit({String? note}) async {
    if (state == CheckoutState.submitting || review == null || !termsAccepted) {
      return false;
    }
    if (DateTime.now().isAfter(review!.expiresAt)) {
      error = 'Checkout review expired. Refresh it.';
      state = CheckoutState.error;
      notifyListeners();
      return false;
    }
    _key ??= 'order-${DateTime.now().microsecondsSinceEpoch}';
    state = CheckoutState.submitting;
    notifyListeners();
    try {
      confirmation = await repository.submit(
        review!.id,
        _key!,
        true,
        note: note,
      );
      state = CheckoutState.submitted;
      return true;
    } catch (e) {
      error = userSafeApiMessage(e);
      state = CheckoutState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  void _authChanged() {
    final n = auth.authenticated ? auth.profile!.customerId : null;
    if (n == _customer) return;
    _customer = n;
    if (n == null) {
      addresses = [];
      methods = [];
      selectedAddress = null;
      selectedMethod = null;
      review = null;
      confirmation = null;
      _key = null;
      termsAccepted = false;
      state = CheckoutState.idle;
      error = null;
      notifyListeners();
    } else {
      unawaited(loadPrerequisites());
    }
  }

  @override
  void dispose() {
    auth.removeListener(_authChanged);
    super.dispose();
  }
}
