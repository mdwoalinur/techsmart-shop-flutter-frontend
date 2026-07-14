import '../../model/payment/payment_models.dart';
import '../api/api_client.dart';

abstract class PaymentRepository {
  Future<List<PaymentMethodOption>> methods(String orderNumber);
  Future<List<MobileWalletProviderOption>> mobileWalletProviders(
    String orderNumber,
  );
  Future<PaymentInitiationResult> initiate(
    String orderNumber, {
    required String paymentMethodCode,
    required String idempotencyKey,
  });
  Future<ManualPaymentResult> submitManual(
    String orderNumber, {
    required String paymentMethodCode,
    required String transactionReference,
    required String submittedAmount,
    String? payerName,
    String? payerPhone,
    String? note,
    required String idempotencyKey,
  });
  Future<MobileWalletSessionResult> initiateMobileWallet(
    String orderNumber, {
    required String providerCode,
    required String idempotencyKey,
  });
  Future<PaymentStatusResult> confirmMobileWallet(
    String attemptReference, {
    required String walletNumber,
    required String verificationCode,
    required String paymentPin,
    required String idempotencyKey,
  });
  Future<CodSelectionResult> selectCod(
    String orderNumber, {
    required String idempotencyKey,
  });
  Future<PaymentStatusResult> cancel(String orderNumber);
  Future<PaymentStatusResult> status(String orderNumber);
}

class PaymentService implements PaymentRepository {
  PaymentService(this.client);
  final ApiClient client;

  @override
  Future<List<PaymentMethodOption>> methods(String orderNumber) async =>
      (await client.get(
                'orders/$orderNumber/payment-methods',
                authenticated: true,
              )
              as List)
          .map(PaymentMethodOption.fromJson)
          .toList(growable: false);

  @override
  Future<List<MobileWalletProviderOption>> mobileWalletProviders(
    String orderNumber,
  ) async =>
      (await client.get(
                'orders/$orderNumber/mobile-wallet-providers',
                authenticated: true,
              )
              as List)
          .map(MobileWalletProviderOption.fromJson)
          .toList(growable: false);

  @override
  Future<PaymentInitiationResult> initiate(
    String orderNumber, {
    required String paymentMethodCode,
    required String idempotencyKey,
  }) async => PaymentInitiationResult.fromJson(
    await client.post(
      'orders/$orderNumber/payments/initiate',
      authenticated: true,
      body: {
        'paymentMethodCode': paymentMethodCode,
        'idempotencyKey': idempotencyKey,
      },
    ),
  );

  @override
  Future<ManualPaymentResult> submitManual(
    String orderNumber, {
    required String paymentMethodCode,
    required String transactionReference,
    required String submittedAmount,
    String? payerName,
    String? payerPhone,
    String? note,
    required String idempotencyKey,
  }) async => ManualPaymentResult.fromJson(
    await client.post(
      'orders/$orderNumber/payments/manual',
      authenticated: true,
      body: {
        'paymentMethodCode': paymentMethodCode,
        'transactionReference': transactionReference,
        'submittedAmount': submittedAmount,
        'payerName': payerName,
        'payerPhone': payerPhone,
        'customerNote': note,
        'idempotencyKey': idempotencyKey,
      },
    ),
  );

  @override
  Future<MobileWalletSessionResult> initiateMobileWallet(
    String orderNumber, {
    required String providerCode,
    required String idempotencyKey,
  }) async => MobileWalletSessionResult.fromJson(
    await client.post(
      'orders/$orderNumber/payments/mobile-wallet/initiate',
      authenticated: true,
      body: {'providerCode': providerCode, 'idempotencyKey': idempotencyKey},
    ),
  );

  @override
  Future<PaymentStatusResult> confirmMobileWallet(
    String attemptReference, {
    required String walletNumber,
    required String verificationCode,
    required String paymentPin,
    required String idempotencyKey,
  }) async => PaymentStatusResult.fromJson(
    await client.post(
      'payments/mobile-wallet/$attemptReference/confirm',
      authenticated: true,
      body: {
        'walletNumber': walletNumber,
        'verificationCode': verificationCode,
        'paymentPin': paymentPin,
        'idempotencyKey': idempotencyKey,
      },
    ),
  );

  @override
  Future<CodSelectionResult> selectCod(
    String orderNumber, {
    required String idempotencyKey,
  }) async => CodSelectionResult.fromJson(
    await client.post(
      'orders/$orderNumber/payments/cod',
      authenticated: true,
      body: {'idempotencyKey': idempotencyKey},
    ),
  );

  @override
  Future<PaymentStatusResult> cancel(String orderNumber) async =>
      PaymentStatusResult.fromJson(
        await client.post(
          'orders/$orderNumber/payments/cancel',
          authenticated: true,
        ),
      );

  @override
  Future<PaymentStatusResult> status(String orderNumber) async =>
      PaymentStatusResult.fromJson(
        await client.get(
          'orders/$orderNumber/payments/status',
          authenticated: true,
        ),
      );
}
