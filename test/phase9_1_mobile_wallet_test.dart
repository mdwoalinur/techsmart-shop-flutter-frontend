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
  test('mobile wallet provider and session models parse safe backend DTOs', () {
    final provider = MobileWalletProviderOption.fromJson({
      'code': 'BKASH',
      'displayName': 'bKash',
      'shortDescription': 'Wallet simulation',
      'eligible': true,
      'displayOrder': 1,
      'iconAssetKey': 'wallet_bkash',
      'visualThemeKey': 'pink',
      'phoneLabel': 'bKash wallet number',
      'phoneHint': '01XXXXXXXXX',
      'requiresVerificationCode': true,
      'requiresPaymentPin': true,
      'instructions': 'Use test credentials',
      'supportedCurrency': 'BDT',
    });
    expect(provider.code, 'BKASH');
    expect(provider.eligible, isTrue);
    final session = MobileWalletSessionResult.fromJson({
      'paymentNumber': 'TSP-1',
      'attemptReference': 'MW-1',
      'orderNumber': 'TSS-1',
      'providerCode': 'BKASH',
      'providerDisplayName': 'bKash',
      'amount': 185.0,
      'currency': 'BDT',
      'expiresAt': '2026-01-01T00:15:00Z',
      'currentStep': 'ENTER_WALLET_NUMBER',
      'safeInstruction': 'Presentation simulation only.',
    });
    expect(session.attemptReference, 'MW-1');
    expect(session.amount.value, '185.0');
  });

  test(
    'wallet service request bodies omit client amount and success flag',
    () async {
      final bodies = <String, Map<String, Object?>>{};
      final api = ApiClient(
        baseUri: Uri.parse('https://example.test/api/mobile/v1'),
        client: MockClient((request) async {
          if (request.method == 'GET') {
            expect(
              request.url.path,
              '/api/mobile/v1/orders/TSS-1/mobile-wallet-providers',
            );
            return http.Response(jsonEncode(walletProvidersJson()), 200);
          }
          final body = jsonDecode(request.body) as Map<String, Object?>;
          bodies[request.url.path] = body;
          if (request.url.path.endsWith('/payments/mobile-wallet/initiate')) {
            return http.Response(jsonEncode(walletSessionJson()), 201);
          }
          return http.Response(jsonEncode(statusJson('PAID')), 200);
        }),
      );
      final service = PaymentService(api);
      expect(await service.mobileWalletProviders('TSS-1'), hasLength(6));
      await service.initiateMobileWallet(
        'TSS-1',
        providerCode: 'BKASH',
        idempotencyKey: 'wallet-1',
      );
      await service.confirmMobileWallet(
        'MW-1',
        walletNumber: '01700000000',
        verificationCode: '123456',
        paymentPin: '12345',
        idempotencyKey: 'confirm-1',
      );
      for (final body in bodies.values) {
        expect(body.keys, isNot(contains('amount')));
        expect(body.keys, isNot(contains('success')));
      }
      expect(
        bodies.values.first.keys,
        containsAll(['providerCode', 'idempotencyKey']),
      );
      api.close();
    },
  );

  test(
    'provider wallet flow becomes paid only after backend confirmation',
    () async {
      final auth = await authed();
      final repo = FakeWalletRepo(
        statuses: [
          PaymentStatusResult.fromJson(statusJson('NOT_STARTED')),
          PaymentStatusResult.fromJson(statusJson('PENDING_GATEWAY')),
        ],
      );
      final p = PaymentProvider(repo, auth);
      await p.loadMethods('TSS-1');
      p.selectMethod(repo.methodsList.single);
      await p.loadWalletProviders();
      await p.initiateWallet();
      expect(p.current!.paid, isFalse);
      expect(
        await p.confirmWallet(
          walletNumber: '01700000000',
          verificationCode: '123456',
          paymentPin: '12345',
        ),
        isTrue,
      );
      expect(p.state, PaymentFlowState.paid);
      p.dispose();
    },
  );

  test('provider validates wallet number before sending credentials', () async {
    final auth = await authed();
    final repo = FakeWalletRepo();
    final p = PaymentProvider(repo, auth);
    await p.loadMethods('TSS-1');
    p.selectMethod(repo.methodsList.single);
    await p.loadWalletProviders();
    await p.initiateWallet();
    expect(
      await p.confirmWallet(
        walletNumber: '1700000000',
        verificationCode: '123456',
        paymentPin: '12345',
      ),
      isFalse,
    );
    expect(repo.confirmCalls, 0);
    expect(p.error, contains('11 digit'));
    p.dispose();
  });

  testWidgets(
    'payment screen shows six wallet providers and simulation disclosure',
    (tester) async {
      final auth = await authed();
      final repo = FakeWalletRepo();
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
      await tester.tap(find.text('Mobile Wallet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose Mobile Wallet'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Payment Simulation'), findsOneWidget);
      for (final name in [
        'bKash',
        'Nagad',
        'Rocket',
        'Upay',
        'SureCash',
        'Tap',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
    },
  );
}

Map<String, Object?> methodJson() => {
  'code': 'MOBILE_WALLET',
  'displayName': 'Mobile Wallet',
  'description': 'Wallet checkout',
  'type': 'MOBILE_WALLET',
  'active': true,
  'eligible': true,
  'supportedCurrency': 'BDT',
  'requiresReference': false,
  'requiresProof': false,
  'customerInstructions': 'Choose a wallet provider',
  'autoVerify': true,
  'reviewRequired': false,
};

List<Map<String, Object?>> walletProvidersJson() =>
    [
          ['BKASH', 'bKash', 'pink'],
          ['NAGAD', 'Nagad', 'orange'],
          ['ROCKET', 'Rocket', 'purple'],
          ['UPAY', 'Upay', 'blue'],
          ['SURECASH', 'SureCash', 'green'],
          ['TAP', 'Tap', 'teal'],
        ]
        .asMap()
        .entries
        .map((entry) {
          final row = entry.value;
          return {
            'code': row[0],
            'displayName': row[1],
            'shortDescription': '${row[1]} wallet simulation',
            'eligible': true,
            'displayOrder': entry.key + 1,
            'iconAssetKey': 'wallet_${row[0]}',
            'visualThemeKey': row[2],
            'phoneLabel': '${row[1]} wallet number',
            'phoneHint': '01XXXXXXXXX',
            'requiresVerificationCode': true,
            'requiresPaymentPin': true,
            'instructions': 'Use test credentials',
            'supportedCurrency': 'BDT',
          };
        })
        .toList(growable: false);

Map<String, Object?> walletSessionJson() => {
  'paymentNumber': 'TSP-1',
  'attemptReference': 'MW-1',
  'orderNumber': 'TSS-1',
  'providerCode': 'BKASH',
  'providerDisplayName': 'bKash',
  'amount': 185.0,
  'currency': 'BDT',
  'expiresAt': '2026-01-01T00:15:00Z',
  'currentStep': 'ENTER_WALLET_NUMBER',
  'safeInstruction': 'Presentation simulation only.',
};

Map<String, Object?> statusJson(String status) => {
  'paymentNumber': status == 'NOT_STARTED' ? null : 'TSP-1',
  'orderNumber': 'TSS-1',
  'paymentStatus': status,
  'accountingStatus': status == 'PAID' ? 'POSTED' : 'UNPOSTED',
  'methodCode': status == 'NOT_STARTED' ? null : 'MOBILE_WALLET',
  'methodType': status == 'NOT_STARTED' ? null : 'MOBILE_WALLET',
  'amount': 185.0,
  'currency': 'BDT',
  'customerMessage': 'Wallet status',
  'retryAllowed': status == 'FAILED',
  'cancellable': status == 'PENDING_GATEWAY',
  'attempts': [],
  'timeline': [],
};

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

class FakeWalletRepo implements PaymentRepository {
  FakeWalletRepo({List<PaymentStatusResult>? statuses})
    : statuses = List.of(statuses ?? []);

  final List<PaymentStatusResult> statuses;
  final methodsList = [PaymentMethodOption.fromJson(methodJson())];
  int confirmCalls = 0;

  @override
  Future<List<PaymentMethodOption>> methods(String orderNumber) async =>
      methodsList;

  @override
  Future<List<MobileWalletProviderOption>> mobileWalletProviders(
    String orderNumber,
  ) async => walletProvidersJson()
      .map(MobileWalletProviderOption.fromJson)
      .toList(growable: false);

  @override
  Future<MobileWalletSessionResult> initiateMobileWallet(
    String orderNumber, {
    required String providerCode,
    required String idempotencyKey,
  }) async => MobileWalletSessionResult.fromJson(walletSessionJson());

  @override
  Future<PaymentStatusResult> confirmMobileWallet(
    String attemptReference, {
    required String walletNumber,
    required String verificationCode,
    required String paymentPin,
    required String idempotencyKey,
  }) async {
    confirmCalls++;
    return PaymentStatusResult.fromJson(statusJson('PAID'));
  }

  @override
  Future<PaymentInitiationResult> initiate(
    String orderNumber, {
    required String paymentMethodCode,
    required String idempotencyKey,
  }) => throw UnimplementedError();

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
  }) => throw UnimplementedError();

  @override
  Future<CodSelectionResult> selectCod(
    String orderNumber, {
    required String idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<PaymentStatusResult> cancel(String orderNumber) =>
      throw UnimplementedError();

  @override
  Future<PaymentStatusResult> status(String orderNumber) async =>
      statuses.isEmpty
      ? PaymentStatusResult.fromJson(statusJson('NOT_STARTED'))
      : statuses.removeAt(0);
}
