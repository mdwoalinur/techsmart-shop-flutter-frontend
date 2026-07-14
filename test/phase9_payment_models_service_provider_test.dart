import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:tech_smart_shop/model/payment/payment_models.dart';
import 'package:tech_smart_shop/provider/auth_provider.dart';
import 'package:tech_smart_shop/provider/payment_provider.dart';
import 'package:tech_smart_shop/service/api/api_client.dart';
import 'package:tech_smart_shop/service/payment/payment_service.dart';
import 'package:tech_smart_shop/ui/screen/payment/payment_screen.dart';
import 'support/fake_auth.dart';

void main() {
  final methodJson = {
    'code': 'ONLINE_GATEWAY',
    'displayName': 'Online Gateway',
    'description': 'Hosted checkout',
    'type': 'ONLINE_GATEWAY',
    'active': true,
    'eligible': true,
    'ineligibilityReason': null,
    'minAmount': null,
    'maxAmount': null,
    'supportedCurrency': 'BDT',
    'requiresReference': false,
    'requiresProof': false,
    'customerInstructions': 'Use secure checkout',
    'autoVerify': true,
    'reviewRequired': false,
  };
  final manualJson = {
    ...methodJson,
    'code': 'BANK_TRANSFER',
    'displayName': 'Bank Transfer',
    'type': 'BANK_TRANSFER',
    'requiresReference': true,
    'requiresProof': true,
    'autoVerify': false,
    'reviewRequired': true,
  };
  final codJson = {
    ...methodJson,
    'code': 'CASH_ON_DELIVERY',
    'displayName': 'Cash on Delivery',
    'type': 'CASH_ON_DELIVERY',
    'autoVerify': false,
  };
  Map<String, Object?> statusJson(String status) => {
    'paymentNumber': status == 'NOT_STARTED' ? null : 'TSP-1',
    'orderNumber': 'TSS-1',
    'paymentStatus': status,
    'accountingStatus': status == 'PAID' ? 'POSTED' : 'UNPOSTED',
    'methodCode': status == 'NOT_STARTED' ? null : 'ONLINE_GATEWAY',
    'methodType': status == 'NOT_STARTED' ? null : 'ONLINE_GATEWAY',
    'amount': 185.0,
    'currency': 'BDT',
    'customerMessage': status == 'PAID'
        ? 'Payment received and posted.'
        : 'Pending',
    'retryAllowed': status == 'FAILED',
    'cancellable': status == 'PENDING_GATEWAY',
    'attempts': [],
    'timeline': [
      {
        'status': status,
        'source': 'TEST',
        'note': 'note',
        'occurredAt': '2026-01-01T00:00:00Z',
        'actorType': 'SYSTEM',
      },
    ],
  };

  test('payment models parse methods status timeline and unknown statuses', () {
    final method = PaymentMethodOption.fromJson(methodJson);
    expect(method.isOnline, isTrue);
    final status = PaymentStatusResult.fromJson(statusJson('FUTURE_STATUS'));
    expect(status.paymentStatus, 'FUTURE_STATUS');
    expect(status.amount.value, '185.0');
    expect(status.timeline.single.status, 'FUTURE_STATUS');
  });

  test(
    'service sends safe initiation body without amount or success flag',
    () async {
      late Map<String, Object?> body;
      final api = ApiClient(
        baseUri: Uri.parse('https://example.test/api/mobile/v1'),
        client: MockClient((request) async {
          expect(
            request.url.path,
            '/api/mobile/v1/orders/TSS-1/payments/initiate',
          );
          body = jsonDecode(request.body) as Map<String, Object?>;
          return http.Response(
            jsonEncode({
              'paymentNumber': 'TSP-1',
              'orderNumber': 'TSS-1',
              'paymentStatus': 'PENDING_GATEWAY',
              'attemptStatus': 'SESSION_CREATED',
              'methodCode': 'ONLINE_GATEWAY',
              'methodType': 'ONLINE_GATEWAY',
              'amount': 185.0,
              'currency': 'BDT',
              'provider': 'LOCAL_TEST',
              'gatewaySessionId': 'S1',
              'redirectUrl': 'techsmart://pay',
              'expiresAt': '2026-01-01T00:15:00Z',
              'customerMessage': 'Pending',
            }),
            201,
          );
        }),
      );
      await PaymentService(api).initiate(
        'TSS-1',
        paymentMethodCode: 'ONLINE_GATEWAY',
        idempotencyKey: 'k1',
      );
      expect(body.keys, containsAll(['paymentMethodCode', 'idempotencyKey']));
      expect(body.keys, isNot(contains('amount')));
      expect(body.keys, isNot(contains('success')));
      api.close();
    },
  );

  test('provider does not mark paid after client initiation alone', () async {
    final auth = await authed();
    final repo = FakePaymentRepo(
      statusSequence: [
        PaymentStatusResult.fromJson(statusJson('NOT_STARTED')),
        PaymentStatusResult.fromJson(statusJson('PENDING_GATEWAY')),
      ],
    );
    final p = PaymentProvider(repo, auth);
    await p.loadMethods('TSS-1');
    await p.initiateOnline();
    expect(p.state, PaymentFlowState.awaitingGateway);
    expect(p.current!.paid, isFalse);
    p.dispose();
  });

  test('provider marks paid only after backend status says PAID', () async {
    final auth = await authed();
    final repo = FakePaymentRepo(
      statusSequence: [
        PaymentStatusResult.fromJson(statusJson('NOT_STARTED')),
        PaymentStatusResult.fromJson(statusJson('PENDING_GATEWAY')),
        PaymentStatusResult.fromJson(statusJson('PAID')),
      ],
    );
    final p = PaymentProvider(repo, auth);
    await p.loadMethods('TSS-1');
    await p.initiateOnline();
    await p.refreshStatus();
    expect(p.state, PaymentFlowState.paid);
    expect(p.current!.accountingStatus, 'POSTED');
    p.dispose();
  });

  test(
    'manual payment remains review required and preserves reference',
    () async {
      final auth = await authed();
      final repo = FakePaymentRepo(
        methods: [PaymentMethodOption.fromJson(manualJson)],
        statusSequence: [
          PaymentStatusResult.fromJson(statusJson('NOT_STARTED')),
          PaymentStatusResult.fromJson(statusJson('REVIEW_REQUIRED')),
        ],
      );
      final p = PaymentProvider(repo, auth);
      await p.loadMethods('TSS-1');
      p.updateManualDraft(reference: 'BR123');
      expect(await p.submitManual(), isTrue);
      expect(p.state, PaymentFlowState.reviewRequired);
      expect(p.manualReference, 'BR123');
      p.dispose();
    },
  );

  test('cod selection is pending and does not claim paid', () async {
    final auth = await authed();
    final repo = FakePaymentRepo(
      methods: [PaymentMethodOption.fromJson(codJson)],
      statusSequence: [
        PaymentStatusResult.fromJson(statusJson('NOT_STARTED')),
        PaymentStatusResult.fromJson(statusJson('COD_PENDING')),
      ],
    );
    final p = PaymentProvider(repo, auth);
    await p.loadMethods('TSS-1');
    expect(await p.selectCod(), isTrue);
    expect(p.state, PaymentFlowState.pending);
    expect(p.current!.paid, isFalse);
    p.dispose();
  });

  test('provider cancels only backend-cancellable pending payment', () async {
    final auth = await authed();
    final repo = FakePaymentRepo(
      statusSequence: [
        PaymentStatusResult.fromJson(statusJson('NOT_STARTED')),
        PaymentStatusResult.fromJson(statusJson('PENDING_GATEWAY')),
      ],
    );
    final p = PaymentProvider(repo, auth);
    await p.loadMethods('TSS-1');
    await p.initiateOnline();
    expect(p.current!.cancellable, isTrue);
    final ok = await p.cancelPending();
    expect(ok, isTrue);
    expect(p.state, PaymentFlowState.cancelled);
    expect(p.current!.paymentStatus, 'CANCELLED');
    expect(p.idempotencyKey, isNull);
    p.dispose();
  });

  test('logout clears payment state and idempotency', () async {
    final auth = await authed();
    final p = PaymentProvider(
      FakePaymentRepo(
        statusSequence: [
          PaymentStatusResult.fromJson(statusJson('NOT_STARTED')),
          PaymentStatusResult.fromJson(statusJson('PENDING_GATEWAY')),
        ],
      ),
      auth,
    );
    await p.loadMethods('TSS-1');
    await p.initiateOnline();
    expect(p.idempotencyKey, isNotNull);
    await auth.logout();
    expect(p.state, PaymentFlowState.idle);
    expect(p.idempotencyKey, isNull);
    expect(p.current, isNull);
    p.dispose();
  });

  testWidgets('payment screen shows backend amount and ineligible methods', (
    tester,
  ) async {
    final auth = await authed();
    final repo = FakePaymentRepo(
      methods: [
        PaymentMethodOption.fromJson(methodJson),
        PaymentMethodOption.fromJson({
          ...manualJson,
          'eligible': false,
          'ineligibilityReason': 'Limit exceeded',
        }),
      ],
      statusSequence: [PaymentStatusResult.fromJson(statusJson('NOT_STARTED'))],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider(create: (_) => PaymentProvider(repo, auth)),
        ],
        child: const MaterialApp(home: PaymentScreen(orderNumber: 'TSS-1')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Amount due'), findsOneWidget);
    expect(find.text('Calculated by backend. Not editable.'), findsOneWidget);
    expect(find.text('Online Gateway'), findsOneWidget);
    expect(find.text('Limit exceeded'), findsOneWidget);
  });
}

Future<AuthProvider> authed() async {
  final storage = MemorySessionStorage()..value = testSession();
  final auth = AuthProvider(
    FakeAuthRepository(),
    storage,
    autoInitialize: false,
  );
  await auth.initialize();
  return auth;
}

class FakePaymentRepo implements PaymentRepository {
  FakePaymentRepo({
    List<PaymentMethodOption>? methods,
    List<PaymentStatusResult>? statusSequence,
  }) : methodsList =
           methods ??
           [
             PaymentMethodOption.fromJson({
               'code': 'ONLINE_GATEWAY',
               'displayName': 'Online Gateway',
               'type': 'ONLINE_GATEWAY',
               'active': true,
               'eligible': true,
               'supportedCurrency': 'BDT',
               'requiresReference': false,
               'requiresProof': false,
               'autoVerify': true,
               'reviewRequired': false,
             }),
           ],
       statuses = List.of(statusSequence ?? []);
  final List<PaymentMethodOption> methodsList;
  final List<PaymentStatusResult> statuses;
  @override
  Future<List<PaymentMethodOption>> methods(String orderNumber) async =>
      methodsList;
  @override
  Future<PaymentInitiationResult> initiate(
    String orderNumber, {
    required String paymentMethodCode,
    required String idempotencyKey,
  }) async => PaymentInitiationResult.fromJson({
    'paymentNumber': 'TSP-1',
    'orderNumber': orderNumber,
    'paymentStatus': 'PENDING_GATEWAY',
    'attemptStatus': 'SESSION_CREATED',
    'methodCode': paymentMethodCode,
    'methodType': 'ONLINE_GATEWAY',
    'amount': 185.0,
    'currency': 'BDT',
    'provider': 'LOCAL_TEST',
    'gatewaySessionId': 'S1',
    'customerMessage': 'Pending',
  });
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
  }) async => ManualPaymentResult.fromJson({
    'paymentNumber': 'TSP-1',
    'orderNumber': orderNumber,
    'paymentStatus': 'REVIEW_REQUIRED',
    'reviewStatus': 'PENDING_REVIEW',
    'amount': 185.0,
    'currency': 'BDT',
    'transactionReference': transactionReference,
    'submittedAt': '2026-01-01T00:00:00Z',
    'customerMessage': 'Submitted for review',
  });
  @override
  Future<CodSelectionResult> selectCod(
    String orderNumber, {
    required String idempotencyKey,
  }) async => CodSelectionResult.fromJson({
    'paymentNumber': 'TSP-1',
    'orderNumber': orderNumber,
    'paymentStatus': 'COD_PENDING',
    'orderStatus': 'CONFIRMED',
    'amount': 185.0,
    'currency': 'BDT',
    'customerMessage': 'COD pending',
  });
  @override
  Future<List<MobileWalletProviderOption>> mobileWalletProviders(
    String orderNumber,
  ) async => ['BKASH', 'NAGAD', 'ROCKET', 'UPAY', 'SURECASH', 'TAP']
      .asMap()
      .entries
      .map(
        (e) => MobileWalletProviderOption.fromJson({
          'code': e.value,
          'displayName': e.value == 'BKASH' ? 'bKash' : e.value,
          'shortDescription': 'Wallet simulation',
          'eligible': true,
          'displayOrder': e.key + 1,
          'requiresVerificationCode': true,
          'requiresPaymentPin': true,
          'supportedCurrency': 'BDT',
        }),
      )
      .toList(growable: false);

  @override
  Future<MobileWalletSessionResult> initiateMobileWallet(
    String orderNumber, {
    required String providerCode,
    required String idempotencyKey,
  }) async => MobileWalletSessionResult.fromJson({
    'paymentNumber': 'TSP-1',
    'attemptReference': 'MW-1',
    'orderNumber': orderNumber,
    'providerCode': providerCode,
    'providerDisplayName': providerCode,
    'amount': 185.0,
    'currency': 'BDT',
    'expiresAt': '2026-01-01T00:15:00Z',
    'currentStep': 'ENTER_WALLET_NUMBER',
    'safeInstruction': 'Presentation simulation only.',
  });

  @override
  Future<PaymentStatusResult> confirmMobileWallet(
    String attemptReference, {
    required String walletNumber,
    required String verificationCode,
    required String paymentPin,
    required String idempotencyKey,
  }) async => PaymentStatusResult.fromJson({
    'paymentNumber': 'TSP-1',
    'orderNumber': 'TSS-1',
    'paymentStatus': 'PAID',
    'accountingStatus': 'POSTED',
    'methodCode': 'MOBILE_WALLET',
    'methodType': 'MOBILE_WALLET',
    'amount': 185.0,
    'currency': 'BDT',
    'customerMessage': 'Payment received and posted.',
    'retryAllowed': false,
    'cancellable': false,
    'attempts': [],
    'timeline': [],
  });
  @override
  Future<PaymentStatusResult> cancel(String orderNumber) async =>
      PaymentStatusResult.fromJson({
        'paymentNumber': 'TSP-1',
        'orderNumber': orderNumber,
        'paymentStatus': 'CANCELLED',
        'accountingStatus': 'UNPOSTED',
        'methodCode': 'ONLINE_GATEWAY',
        'methodType': 'ONLINE_GATEWAY',
        'amount': 185.0,
        'currency': 'BDT',
        'customerMessage': 'Pending payment attempt cancelled.',
        'retryAllowed': true,
        'cancellable': false,
        'attempts': [],
        'timeline': [],
      });
  @override
  Future<PaymentStatusResult> status(String orderNumber) async =>
      statuses.isEmpty
      ? PaymentStatusResult.fromJson({
          'paymentNumber': null,
          'orderNumber': orderNumber,
          'paymentStatus': 'NOT_STARTED',
          'accountingStatus': 'UNPOSTED',
          'amount': 185.0,
          'currency': 'BDT',
          'retryAllowed': false,
          'cancellable': false,
          'attempts': [],
          'timeline': [],
        })
      : statuses.removeAt(0);
}
