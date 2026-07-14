import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/payment/payment_models.dart';
import '../service/api/api_exception.dart';
import '../service/payment/payment_service.dart';
import 'auth_provider.dart';

enum PaymentFlowState {
  idle,
  loadingMethods,
  methodsReady,
  loadingWalletProviders,
  walletProvidersReady,
  providerSelected,
  initiating,
  walletSessionReady,
  processingWallet,
  awaitingGateway,
  pending,
  reviewRequired,
  paid,
  failed,
  cancelled,
  loadingStatus,
  error,
}

class PaymentProvider extends ChangeNotifier {
  PaymentProvider(this.repository, this.auth) {
    auth.addListener(_authChanged);
  }

  final PaymentRepository repository;
  final AuthProvider auth;
  PaymentFlowState state = PaymentFlowState.idle;
  List<PaymentMethodOption> methods = [];
  List<MobileWalletProviderOption> walletProviders = [];
  PaymentMethodOption? selectedMethod;
  MobileWalletProviderOption? selectedWalletProvider;
  PaymentStatusResult? current;
  PaymentInitiationResult? initiation;
  MobileWalletSessionResult? walletSession;
  ManualPaymentResult? manualResult;
  CodSelectionResult? codResult;
  String? orderNumber,
      idempotencyKey,
      walletIdempotencyKey,
      confirmIdempotencyKey,
      manualReference,
      payerName,
      payerPhone,
      manualNote,
      error;
  bool _busy = false;
  int _generation = 0, pollCount = 0;
  Timer? _poll;

  Future<void> loadMethods(String order) async {
    if (!auth.authenticated) return;
    final g = _generation;
    orderNumber = order;
    state = PaymentFlowState.loadingMethods;
    error = null;
    notifyListeners();
    try {
      methods = await repository.methods(order);
      if (g != _generation) return;
      selectedMethod = methods
          .where((m) => m.eligible)
          .cast<PaymentMethodOption?>()
          .firstOrNull;
      state = PaymentFlowState.methodsReady;
      await refreshStatus(silent: true);
    } catch (e) {
      if (g != _generation) return;
      error = userSafeApiMessage(e);
      state = PaymentFlowState.error;
    }
    notifyListeners();
  }

  void selectMethod(PaymentMethodOption? method) {
    if (method == null || !method.eligible) return;
    selectedMethod = method;
    selectedWalletProvider = null;
    walletSession = null;
    walletIdempotencyKey = null;
    confirmIdempotencyKey = null;
    error = null;
    state = PaymentFlowState.methodsReady;
    notifyListeners();
  }

  Future<void> loadWalletProviders() async {
    final order = orderNumber;
    final method = selectedMethod;
    if (order == null || method == null || !method.isWallet || _busy) return;
    _busy = true;
    state = PaymentFlowState.loadingWalletProviders;
    error = null;
    notifyListeners();
    try {
      walletProviders = await repository.mobileWalletProviders(order);
      selectedWalletProvider = walletProviders
          .where((p) => p.eligible)
          .cast<MobileWalletProviderOption?>()
          .firstOrNull;
      state = PaymentFlowState.walletProvidersReady;
    } catch (e) {
      error = userSafeApiMessage(e);
      state = PaymentFlowState.error;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void selectWalletProvider(MobileWalletProviderOption provider) {
    if (!provider.eligible) return;
    selectedWalletProvider = provider;
    walletSession = null;
    error = null;
    state = PaymentFlowState.providerSelected;
    notifyListeners();
  }

  Future<bool> initiateWallet() async {
    final order = orderNumber;
    final method = selectedMethod;
    final wallet = selectedWalletProvider;
    if (order == null ||
        method == null ||
        !method.isWallet ||
        wallet == null ||
        _busy) {
      return false;
    }
    _busy = true;
    walletIdempotencyKey ??= _key('wallet', order);
    state = PaymentFlowState.initiating;
    error = null;
    notifyListeners();
    try {
      walletSession = await repository.initiateMobileWallet(
        order,
        providerCode: wallet.code,
        idempotencyKey: walletIdempotencyKey!,
      );
      state = PaymentFlowState.walletSessionReady;
      await refreshStatus(silent: true);
      return true;
    } catch (e) {
      error = userSafeApiMessage(e);
      state = PaymentFlowState.error;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> confirmWallet({
    required String walletNumber,
    required String verificationCode,
    required String paymentPin,
  }) async {
    final session = walletSession;
    if (session == null || _busy) return false;
    final number = walletNumber.trim();
    final code = verificationCode.trim();
    final pin = paymentPin.trim();
    if (!RegExp(r'^01\d{9}$').hasMatch(number)) {
      error = 'Enter an 11 digit Bangladeshi wallet number starting with 01.';
      notifyListeners();
      return false;
    }
    if (code.isEmpty || pin.isEmpty) {
      error = 'Verification code and PIN are required for the simulation.';
      notifyListeners();
      return false;
    }
    _busy = true;
    confirmIdempotencyKey ??= _key('wallet-confirm', session.orderNumber);
    state = PaymentFlowState.processingWallet;
    error = null;
    notifyListeners();
    try {
      current = await repository.confirmMobileWallet(
        session.attemptReference,
        walletNumber: number,
        verificationCode: code,
        paymentPin: pin,
        idempotencyKey: confirmIdempotencyKey!,
      );
      _applyStatus();
      if (current?.paid == true) {
        walletIdempotencyKey = null;
        confirmIdempotencyKey = null;
      }
      return current?.paymentStatus != 'FAILED';
    } catch (e) {
      error = userSafeApiMessage(e);
      state = PaymentFlowState.error;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void updateManualDraft({
    String? reference,
    String? name,
    String? phone,
    String? note,
  }) {
    manualReference = reference ?? manualReference;
    payerName = name ?? payerName;
    payerPhone = phone ?? payerPhone;
    manualNote = note ?? manualNote;
    notifyListeners();
  }

  Future<bool> initiateOnline() async {
    final order = orderNumber;
    final method = selectedMethod;
    if (order == null || method == null || !method.isOnline || _busy) {
      return false;
    }
    _busy = true;
    idempotencyKey ??= _key('pay', order);
    state = PaymentFlowState.initiating;
    error = null;
    notifyListeners();
    try {
      initiation = await repository.initiate(
        order,
        paymentMethodCode: method.code,
        idempotencyKey: idempotencyKey!,
      );
      state = PaymentFlowState.awaitingGateway;
      await refreshStatus(silent: true);
      startPolling();
      return true;
    } catch (e) {
      error = userSafeApiMessage(e);
      state = PaymentFlowState.error;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> submitManual() async {
    final order = orderNumber;
    final method = selectedMethod;
    final ref = manualReference?.trim();
    if (order == null || method == null || !method.isManual || _busy) {
      return false;
    }
    if (ref == null || ref.isEmpty) {
      error = 'Transaction reference is required.';
      notifyListeners();
      return false;
    }
    _busy = true;
    idempotencyKey ??= _key('manual', order);
    state = PaymentFlowState.initiating;
    error = null;
    notifyListeners();
    try {
      final amount = current?.amount.value ?? '0';
      manualResult = await repository.submitManual(
        order,
        paymentMethodCode: method.code,
        transactionReference: ref,
        submittedAmount: amount,
        payerName: payerName,
        payerPhone: payerPhone,
        note: manualNote,
        idempotencyKey: idempotencyKey!,
      );
      state = PaymentFlowState.reviewRequired;
      await refreshStatus(silent: true);
      return true;
    } catch (e) {
      error = userSafeApiMessage(e);
      state = PaymentFlowState.error;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> selectCod() async {
    final order = orderNumber;
    final method = selectedMethod;
    if (order == null || method == null || !method.isCod || _busy) return false;
    _busy = true;
    idempotencyKey ??= _key('cod', order);
    state = PaymentFlowState.initiating;
    error = null;
    notifyListeners();
    try {
      codResult = await repository.selectCod(
        order,
        idempotencyKey: idempotencyKey!,
      );
      state = PaymentFlowState.pending;
      await refreshStatus(silent: true);
      return true;
    } catch (e) {
      error = userSafeApiMessage(e);
      state = PaymentFlowState.error;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> cancelPending() async {
    final order = orderNumber;
    if (order == null || _busy || current?.cancellable != true) return false;
    _busy = true;
    error = null;
    notifyListeners();
    try {
      current = await repository.cancel(order);
      _applyStatus();
      idempotencyKey = null;
      walletIdempotencyKey = null;
      confirmIdempotencyKey = null;
      _poll?.cancel();
      return true;
    } catch (e) {
      error = userSafeApiMessage(e);
      state = PaymentFlowState.error;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatus({bool silent = false}) async {
    final order = orderNumber;
    if (order == null || !auth.authenticated) return;
    final g = _generation;
    if (!silent) {
      state = PaymentFlowState.loadingStatus;
      notifyListeners();
    }
    try {
      current = await repository.status(order);
      if (g != _generation) return;
      _applyStatus();
    } catch (e) {
      if (g != _generation) return;
      error = userSafeApiMessage(e);
      if (!silent) state = PaymentFlowState.error;
    }
    if (!silent) notifyListeners();
  }

  void startPolling() {
    _poll?.cancel();
    pollCount = 0;
    _poll = Timer.periodic(const Duration(seconds: 3), (t) {
      if (pollCount++ >= 8 ||
          state == PaymentFlowState.paid ||
          state == PaymentFlowState.reviewRequired ||
          state == PaymentFlowState.failed) {
        t.cancel();
        return;
      }
      unawaited(refreshStatus(silent: true));
    });
  }

  void _applyStatus() {
    final s = current?.paymentStatus;
    if (s == 'PAID') {
      state = PaymentFlowState.paid;
      idempotencyKey = null;
      _poll?.cancel();
    } else if (s == 'REVIEW_REQUIRED') {
      state = PaymentFlowState.reviewRequired;
      _poll?.cancel();
    } else if (s == 'FAILED') {
      state = PaymentFlowState.failed;
    } else if (s == 'CANCELLED') {
      state = PaymentFlowState.cancelled;
    } else if (s == 'PENDING_GATEWAY') {
      state = walletSession == null
          ? PaymentFlowState.awaitingGateway
          : PaymentFlowState.walletSessionReady;
    } else if (s == 'COD_PENDING') {
      state = PaymentFlowState.pending;
    } else {
      state = methods.isEmpty
          ? PaymentFlowState.idle
          : PaymentFlowState.methodsReady;
    }
  }

  void clear() {
    _poll?.cancel();
    methods = [];
    walletProviders = [];
    selectedMethod = null;
    selectedWalletProvider = null;
    current = null;
    initiation = null;
    walletSession = null;
    manualResult = null;
    codResult = null;
    orderNumber = null;
    idempotencyKey = null;
    walletIdempotencyKey = null;
    confirmIdempotencyKey = null;
    manualReference = null;
    payerName = null;
    payerPhone = null;
    manualNote = null;
    error = null;
    state = PaymentFlowState.idle;
    pollCount = 0;
    notifyListeners();
  }

  void _authChanged() {
    if (!auth.authenticated) {
      ++_generation;
      clear();
    }
  }

  String _key(String p, String order) =>
      '$p-$order-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void dispose() {
    _poll?.cancel();
    auth.removeListener(_authChanged);
    super.dispose();
  }
}
