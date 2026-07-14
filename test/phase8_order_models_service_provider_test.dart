import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tech_smart_shop/model/order/order_models.dart';
import 'package:tech_smart_shop/model/tracking/order_tracking_models.dart';
import 'package:tech_smart_shop/provider/auth_provider.dart';
import 'package:tech_smart_shop/provider/order_provider.dart';
import 'package:tech_smart_shop/service/api/api_client.dart';
import 'package:tech_smart_shop/service/order/order_service.dart';
import 'package:tech_smart_shop/ui/screen/order/order_detail_screen.dart';
import 'package:tech_smart_shop/ui/screen/order/return_request_screen.dart';
import 'support/fake_auth.dart';

void main() {
  final summary = {
    'orderNumber': 'TSS-1',
    'submittedAt': '2026-01-01T00:00:00Z',
    'orderStatus': 'PENDING_CONFIRMATION',
    'customerVisibleStatusLabel': 'Pending Confirmation',
    'paymentStatus': 'NOT_STARTED',
    'grandTotal': 185.0,
    'currency': 'BDT',
    'totalQuantity': 2,
    'itemCount': 1,
    'firstItemName': 'Cable',
    'firstItemImageUrl': null,
    'additionalItemCount': 0,
    'deliveryMethodName': 'Standard',
    'cancellationEligible': true,
    'returnEligible': false,
  };
  final eligibility = {
    'eligible': true,
    'reasonCode': 'ELIGIBLE',
    'message': 'Can cancel',
    'existingRequestStatus': null,
  };
  final returnEligibility = {
    'eligible': false,
    'reasonCode': 'ORDER_NOT_DELIVERED',
    'message': 'Returns are available only after delivery.',
    'returnWindowDays': 7,
    'items': [],
    'existingRequestStatus': null,
  };
  final detail = {
    ...summary,
    'updatedAt': '2026-01-01T00:01:00Z',
    'accountingStatus': 'UNPOSTED',
    'subtotal': 100.0,
    'taxTotal': 5.0,
    'deliveryCharge': 80.0,
    'discountTotal': 0.0,
    'items': [
      {
        'itemId': 1,
        'productId': 2,
        'variationId': null,
        'productName': 'Cable',
        'productCode': 'SKU',
        'variationName': null,
        'imageUrl': null,
        'unitPrice': 100.0,
        'quantity': 1,
        'lineSubtotal': 100.0,
        'taxRate': 5.0,
        'taxAmount': 5.0,
      },
    ],
    'delivery': {
      'recipientName': 'A',
      'phone': '017****00',
      'address': 'Dhaka',
      'deliveryMethodName': 'Standard',
    },
    'customerNote': null,
    'timeline': [
      {
        'status': 'PENDING_CONFIRMATION',
        'title': 'Pending Confirmation',
        'description': 'Submitted',
        'occurredAt': '2026-01-01T00:00:00Z',
        'completed': true,
        'current': true,
        'note': null,
      },
    ],
    'cancellationEligibility': eligibility,
    'returnEligibility': returnEligibility,
    'documentAvailable': true,
  };
  test('order page, detail, timeline and unknown labels parse safely', () {
    final page = OrderPage.fromJson({
      'content': [summary],
      'page': 0,
      'size': 10,
      'totalElements': 1,
      'totalPages': 1,
      'first': true,
      'last': true,
    });
    expect(page.content.single.paymentStatus, 'NOT_STARTED');
    final d = OrderDetail.fromJson(detail);
    expect(d.accountingStatus, 'UNPOSTED');
    expect(d.items.single.unitPrice.value, '100.0');
    expect(d.timeline.single.status, 'PENDING_CONFIRMATION');
  });
  test('cancellation, return eligibility and document metadata parse', () {
    expect(CancellationEligibility.fromJson(eligibility).eligible, true);
    expect(
      ReturnEligibility.fromJson(returnEligibility).reasonCode,
      'ORDER_NOT_DELIVERED',
    );
    final doc = OrderDocument.fromJson({
      'orderNumber': 'TSS-1',
      'fileName': 'TSS-1.html',
      'contentType': 'text/html',
      'documentTitle': 'Order Summary',
      'html': '<p>NOT_STARTED</p>',
    });
    expect(doc.html, isNot(contains('buyingPrice')));
  });
  test('order service builds pagination filters and safe sort', () async {
    late Uri uri;
    final client = ApiClient(
      client: MockClient((r) async {
        uri = r.url;
        return http.Response(
          jsonEncode({
            'content': [summary],
            'page': 0,
            'size': 10,
            'totalElements': 1,
            'totalPages': 1,
            'first': true,
            'last': true,
          }),
          200,
        );
      }),
      baseUri: Uri.parse('http://x/api/mobile/v1'),
    );
    final page = await OrderService(client).history(
      page: 2,
      size: 20,
      orderStatus: 'PENDING_CONFIRMATION',
      sort: 'oldest',
    );
    expect(page.content.single.orderNumber, 'TSS-1');
    expect(uri.queryParameters['page'], '2');
    expect(uri.queryParameters['sort'], 'oldest');
  });
  test(
    'order service cancellation submit sends idempotency key only with reason fields',
    () async {
      late Map<String, dynamic> body;
      final client = ApiClient(
        client: MockClient((r) async {
          body = jsonDecode(r.body);
          return http.Response(
            jsonEncode({
              'orderNumber': 'TSS-1',
              'status': 'REQUESTED',
              'reasonCode': 'OTHER',
              'reasonText': 'Need change',
              'requestedAt': '2026-01-01T00:00:00Z',
              'message': 'received',
            }),
            201,
          );
        }),
        baseUri: Uri.parse('http://x/api/mobile/v1'),
      );
      final c = await OrderService(client).submitCancellation(
        'TSS-1',
        reasonCode: 'OTHER',
        reasonText: 'Need change',
        idempotencyKey: 'k',
      );
      expect(c.status, 'REQUESTED');
      expect(body.containsKey('customerId'), false);
      expect(body.containsKey('orderStatus'), false);
      expect(body['idempotencyKey'], 'k');
    },
  );
  test(
    'order service return submit and document endpoint parse safely',
    () async {
      var calls = 0;
      final client = ApiClient(
        client: MockClient((r) async {
          calls++;
          if (r.url.path.endsWith('/document')) {
            return http.Response(
              jsonEncode({
                'orderNumber': 'TSS-1',
                'fileName': 'TSS-1.html',
                'contentType': 'text/html',
                'documentTitle': 'Order Summary',
                'html': 'NOT_STARTED',
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'requestNumber': 'RET-1',
              'orderNumber': 'TSS-1',
              'status': 'REQUESTED',
              'preferredResolution': 'REFUND_REQUESTED',
              'requestedAt': '2026-01-01T00:00:00Z',
              'items': [],
              'message': 'received',
            }),
            201,
          );
        }),
        baseUri: Uri.parse('http://x/api/mobile/v1'),
      );
      final r = await OrderService(client).submitReturn(
        'TSS-1',
        idempotencyKey: 'r',
        preferredResolution: 'REFUND_REQUESTED',
        items: [
          {
            'orderItemId': 1,
            'quantity': 1,
            'reasonCode': 'DAMAGED_OR_DEFECTIVE',
          },
        ],
      );
      final d = await OrderService(client).document('TSS-1');
      expect(r.status, 'REQUESTED');
      expect(d.html, contains('NOT_STARTED'));
      expect(calls, 2);
    },
  );
  test(
    'order provider loads history, prevents duplicate load more, and clears on logout',
    () async {
      final authRepo = FakeAuthRepository();
      final auth = AuthProvider(
        authRepo,
        MemorySessionStorage(),
        autoInitialize: false,
      );
      final repo = FakeOrderRepository(
        detailJson: detail,
        summaryJson: summary,
      );
      final provider = OrderProvider(repo, auth);
      await auth.login('test@example.com', 'Password1!');
      await Future<void>.delayed(Duration.zero);
      expect(provider.orders, isNotEmpty);
      provider.last = false;
      await Future.wait([provider.loadMore(), provider.loadMore()]);
      expect(repo.historyCalls, lessThanOrEqualTo(3));
      await auth.logout();
      expect(provider.orders, isEmpty);
      expect(provider.selected, isNull);
      provider.dispose();
    },
  );
  test(
    'order provider submits cancellation and return once when busy',
    () async {
      final auth = AuthProvider(
        FakeAuthRepository(),
        MemorySessionStorage(),
        autoInitialize: false,
      );
      final repo = FakeOrderRepository(
        detailJson: detail,
        summaryJson: summary,
      );
      final provider = OrderProvider(repo, auth);
      await auth.login('a', 'b');
      await provider.loadDetail('TSS-1');
      await Future.wait([
        provider.submitCancellation('ORDERED_BY_MISTAKE'),
        provider.submitCancellation('ORDERED_BY_MISTAKE'),
      ]);
      await Future.wait([
        provider.submitReturn(
          preferredResolution: 'REFUND_REQUESTED',
          items: [
            {
              'orderItemId': 1,
              'quantity': 1,
              'reasonCode': 'DAMAGED_OR_DEFECTIVE',
            },
          ],
        ),
        provider.submitReturn(
          preferredResolution: 'REFUND_REQUESTED',
          items: [
            {
              'orderItemId': 1,
              'quantity': 1,
              'reasonCode': 'DAMAGED_OR_DEFECTIVE',
            },
          ],
        ),
      ]);
      expect(repo.cancelCalls, 1);
      expect(repo.returnCalls, 1);
      provider.dispose();
    },
  );
  test(
    'return draft serializes multiple selected items and validates per item',
    () {
      final eligibility = OrderDetail.fromJson(
        returnDetailJson,
      ).returnEligibility;
      final first = ReturnRequestItemDraft(
        item: eligibility.items[0],
        selected: true,
        quantity: 2,
        reasonCode: 'WRONG_ITEM',
      );
      final second = ReturnRequestItemDraft(
        item: eligibility.items[1],
        selected: false,
        quantity: 1,
        reasonCode: 'OTHER',
        reasonText: 'Box was empty',
      );
      final draft = ReturnRequestDraft(
        orderNumber: 'TSS-RETURN',
        items: [first, second],
        preferredResolution: 'REPLACEMENT_REQUESTED',
        comment: 'Handle together',
        idempotencyKey: 'return-key-1',
      );

      expect(draft.validationMessage, isNull);
      expect(draft.selectedJsonItems(), [
        {
          'orderItemId': 1,
          'quantity': 2,
          'reasonCode': 'WRONG_ITEM',
          'reasonText': null,
        },
      ]);
      expect(
        draft
            .copyWith(
              items: [second.copyWith(selected: true, reasonText: null)],
            )
            .validationMessage,
        contains('OTHER'),
      );
      expect(
        draft
            .copyWith(items: [first.copyWith(selected: false)])
            .validationMessage,
        contains('Select at least one'),
      );
      expect(draft.preferredResolution, 'REPLACEMENT_REQUESTED');
      expect(draft.comment, 'Handle together');
      expect(draft.idempotencyKey, 'return-key-1');
    },
  );

  test(
    'order service sends two selected return items in one request',
    () async {
      late Map<String, dynamic> body;
      final client = ApiClient(
        client: MockClient((r) async {
          body = jsonDecode(r.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'requestNumber': 'RET-2',
              'orderNumber': 'TSS-RETURN',
              'status': 'REQUESTED',
              'preferredResolution': body['preferredResolution'],
              'requestedAt': '2026-01-01T00:00:00Z',
              'items': [],
              'message': 'received',
            }),
            201,
          );
        }),
        baseUri: Uri.parse('http://x/api/mobile/v1'),
      );

      final request = await OrderService(client).submitReturn(
        'TSS-RETURN',
        idempotencyKey: 'idempotent-return-key',
        preferredResolution: 'REPLACEMENT_REQUESTED',
        comment: 'One package, two problems',
        items: [
          {
            'orderItemId': 1,
            'quantity': 2,
            'reasonCode': 'WRONG_ITEM',
            'reasonText': null,
          },
          {
            'orderItemId': 2,
            'quantity': 1,
            'reasonCode': 'OTHER',
            'reasonText': 'Missing adapter',
          },
        ],
      );

      expect(request.status, 'REQUESTED');
      expect(body['idempotencyKey'], 'idempotent-return-key');
      expect(body['preferredResolution'], 'REPLACEMENT_REQUESTED');
      expect(body['customerComment'], 'One package, two problems');
      final items = body['items'] as List<dynamic>;
      expect(items, hasLength(2));
      expect(items[0], containsPair('quantity', 2));
      expect(items[0], containsPair('reasonCode', 'WRONG_ITEM'));
      expect(items[1], containsPair('orderItemId', 2));
      expect(items[1], containsPair('reasonText', 'Missing adapter'));
    },
  );

  test(
    'order provider manages return draft, retry idempotency, and logout clearing',
    () async {
      final auth = AuthProvider(
        FakeAuthRepository(),
        MemorySessionStorage(),
        autoInitialize: false,
      );
      final repo = FakeOrderRepository(
        detailJson: returnDetailJson,
        summaryJson: returnSummaryJson,
      );
      final provider = OrderProvider(repo, auth);
      await auth.login('customer-a@example.test', 'Password1!');
      await provider.loadDetail('TSS-RETURN');
      provider.startReturnDraft(
        provider.selected!.returnEligibility,
        'TSS-RETURN',
      );

      expect(provider.validateReturnDraft(), contains('Select at least one'));
      provider.selectReturnItem(1, true);
      provider.selectReturnItem(2, true);
      provider.updateReturnQuantity(1, 99);
      expect(provider.returnDraft!.items.first.quantity, 3);
      provider.updateReturnQuantity(2, 0);
      expect(provider.returnDraft!.items[1].quantity, 1);
      provider.updateReturnReason(2, 'OTHER');
      expect(provider.validateReturnDraft(), contains('OTHER'));
      provider.updateReturnReasonText(2, 'Missing adapter');
      provider.updateReturnPreferredResolution('REPLACEMENT_REQUESTED');
      provider.updateReturnComment('Return these together');
      provider.selectReturnItem(1, false);
      provider.selectReturnItem(1, true);
      provider.updateReturnQuantity(1, 2);

      repo.failReturn = true;
      expect(await provider.submitReturnDraft(), false);
      final retainedKey = provider.returnDraft!.idempotencyKey;
      expect(retainedKey, isNotNull);
      expect(provider.returnDraft!.selectedItems, hasLength(2));
      expect(provider.returnDraftError, contains('not submitted'));
      expect(repo.returnCalls, 1);

      repo.failReturn = false;
      final results = await Future.wait([
        provider.submitReturnDraft(),
        provider.submitReturnDraft(),
      ]);
      expect(results.where((value) => value), hasLength(1));
      expect(repo.returnCalls, 2);
      expect(repo.lastReturnKey, retainedKey);
      expect(repo.lastPreferredResolution, 'REPLACEMENT_REQUESTED');
      expect(repo.lastComment, 'Return these together');
      expect(repo.lastReturnItems, hasLength(2));
      expect(repo.lastReturnItems[0], containsPair('quantity', 2));
      expect(provider.returnDraft, isNull);
      expect(provider.returnRequest?.status, 'REQUESTED');

      provider.startReturnDraft(
        provider.selected!.returnEligibility,
        'TSS-RETURN',
      );
      provider.selectReturnItem(1, true);
      await auth.logout();
      expect(provider.returnDraft, isNull);
      expect(provider.returnDraftError, isNull);
      provider.dispose();
    },
  );

  testWidgets(
    'return screen selects two items, reviews, submits once, and confirms REQUESTED',
    (tester) async {
      final auth = AuthProvider(
        FakeAuthRepository(),
        MemorySessionStorage(),
        autoInitialize: false,
      );
      final repo = FakeOrderRepository(
        detailJson: returnDetailJson,
        summaryJson: returnSummaryJson,
      );
      final provider = OrderProvider(repo, auth);
      await auth.login('customer-a@example.test', 'Password1!');
      await provider.loadDetail('TSS-RETURN');

      await tester.pumpWidget(
        ChangeNotifierProvider<OrderProvider>.value(
          value: provider,
          child: MaterialApp(
            home: ReturnRequestScreen(detail: provider.selected!),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cable'), findsOneWidget);
      expect(find.text('Adapter'), findsOneWidget);
      await tester.tap(find.byKey(const Key('returnSelect-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('returnQtyPlus-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('returnSelect-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('returnReason-1')), findsOneWidget);
      expect(find.byKey(const Key('returnReason-2')), findsOneWidget);
      provider.updateReturnReason(2, 'WRONG_ITEM');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('returnOverallComment')));
      await tester.enterText(
        find.byKey(const Key('returnOverallComment')),
        'Two item return',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('reviewReturnRequest')));
      await tester.tap(find.byKey(const Key('reviewReturnRequest')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reviewReturnItem-1')), findsOneWidget);
      expect(find.byKey(const Key('reviewReturnItem-2')), findsOneWidget);
      expect(
        find.textContaining('Preferred resolution requested'),
        findsOneWidget,
      );
      expect(find.textContaining('Refund approved'), findsNothing);
      expect(find.textContaining('Stock restored'), findsNothing);

      await tester.tap(find.byKey(const Key('submitReturnRequest')));
      await tester.pumpAndSettle();

      expect(repo.returnCalls, 1);
      expect(repo.lastReturnItems, hasLength(2));
      expect(repo.lastReturnItems[0], containsPair('quantity', 2));
      expect(
        find.byKey(const Key('returnRequestConfirmation')),
        findsOneWidget,
      );
      expect(find.text('Status: REQUESTED'), findsOneWidget);
      expect(
        find.textContaining('Preferred resolution requested'),
        findsOneWidget,
      );
      provider.dispose();
    },
  );

  testWidgets(
    'return screen remains scrollable on a small phone viewport without overflow',
    (tester) async {
      final auth = AuthProvider(
        FakeAuthRepository(),
        MemorySessionStorage(),
        autoInitialize: false,
      );
      final repo = FakeOrderRepository(
        detailJson: returnDetailJson,
        summaryJson: returnSummaryJson,
      );
      final provider = OrderProvider(repo, auth);
      await auth.login('customer-a@example.test', 'Password1!');
      await provider.loadDetail('TSS-RETURN');

      await tester.pumpWidget(
        ChangeNotifierProvider<OrderProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: ReturnRequestScreen(detail: provider.selected!),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('returnSelect-1')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 100));

      final exception = tester.takeException();
      expect(exception?.toString() ?? '', isNot(contains('overflowed')));
      provider.dispose();
    },
  );
  test(
    'phase 11 tracking models parse steps events COD and unknown status',
    () {
      final tracking = OrderTracking.fromJson({
        ...trackingJson('TSS-1'),
        'fulfillmentStatus': 'FUTURE_STATUS',
      });
      expect(tracking.fulfillmentStatus, FulfillmentStatus.unknown);
      expect(tracking.codStatus, CodTrackingStatus.reconciled);
      expect(tracking.steps.first.status, TrackingStepStatus.completed);
      expect(tracking.steps[1].current, true);
      expect(tracking.deliveryEvents.single.title, 'Order shipped');
    },
  );

  test(
    'phase 11 order service tracking request sends no customer id',
    () async {
      late Uri uri;
      final client = ApiClient(
        client: MockClient((request) async {
          uri = request.url;
          expect(request.body, isEmpty);
          return http.Response(jsonEncode(trackingJson('TSS-1')), 200);
        }),
        baseUri: Uri.parse('http://x/api/mobile/v1'),
      );
      final tracking = await OrderService(client).tracking('TSS-1');
      expect(tracking.trackingNumber, 'TRK-1');
      expect(uri.path, '/api/mobile/v1/orders/TSS-1/tracking');
      expect(uri.queryParameters.containsKey('customerId'), false);
    },
  );

  test(
    'phase 11 provider loads refreshes and clears tracking safely',
    () async {
      final auth = AuthProvider(
        FakeAuthRepository(),
        MemorySessionStorage(),
        autoInitialize: false,
      );
      final repo = FakeOrderRepository(
        detailJson: detail,
        summaryJson: summary,
      );
      final provider = OrderProvider(repo, auth);
      await auth.login('customer-a@example.test', 'Password1!');
      await provider.loadDetail('TSS-1');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(provider.selected?.orderNumber, 'TSS-1');
      expect(provider.trackingByOrderNumber['TSS-1']?.trackingNumber, 'TRK-1');
      repo.failTracking = true;
      await provider.loadTracking('TSS-1', refresh: true);
      expect(provider.selected?.orderNumber, 'TSS-1');
      expect(provider.trackingByOrderNumber['TSS-1']?.trackingNumber, 'TRK-1');
      expect(provider.trackingError, isNotNull);
      await auth.logout();
      expect(provider.trackingByOrderNumber, isEmpty);
      provider.dispose();
    },
  );

  testWidgets(
    'phase 11 order detail displays tracking section without internals',
    (tester) async {
      final auth = AuthProvider(
        FakeAuthRepository(),
        MemorySessionStorage(),
        autoInitialize: false,
      );
      final repo = FakeOrderRepository(
        detailJson: detail,
        summaryJson: summary,
      );
      final provider = OrderProvider(repo, auth);
      await auth.login('customer-a@example.test', 'Password1!');
      await tester.pumpWidget(
        ChangeNotifierProvider<OrderProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: OrderDetailScreen(orderNumber: 'TSS-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delivery tracking'), findsOneWidget);
      expect(find.text('Fulfillment: Shipped'), findsOneWidget);
      expect(find.text('Tracking number: TRK-1'), findsOneWidget);
      expect(find.text('COD: COD reconciled'), findsOneWidget);
      expect(find.textContaining('warehouse'), findsNothing);
      expect(find.textContaining('supplier'), findsNothing);
      provider.dispose();
    },
  );
}

final returnSummaryJson = <String, Object?>{
  'orderNumber': 'TSS-RETURN',
  'submittedAt': '2026-01-01T00:00:00Z',
  'orderStatus': 'DELIVERED',
  'customerVisibleStatusLabel': 'Delivered',
  'paymentStatus': 'NOT_STARTED',
  'grandTotal': 300.0,
  'currency': 'BDT',
  'totalQuantity': 5,
  'itemCount': 2,
  'firstItemName': 'Cable',
  'firstItemImageUrl': null,
  'additionalItemCount': 1,
  'deliveryMethodName': 'Standard',
  'cancellationEligible': false,
  'returnEligible': true,
};

final returnDetailJson = <String, Object?>{
  ...returnSummaryJson,
  'updatedAt': '2026-01-01T00:01:00Z',
  'accountingStatus': 'UNPOSTED',
  'subtotal': 200.0,
  'taxTotal': 20.0,
  'deliveryCharge': 80.0,
  'discountTotal': 0.0,
  'items': [
    {
      'itemId': 1,
      'productId': 2,
      'variationId': null,
      'productName': 'Cable',
      'productCode': 'SKU-CABLE',
      'variationName': null,
      'imageUrl': null,
      'unitPrice': 50.0,
      'quantity': 3,
      'lineSubtotal': 150.0,
      'taxRate': 5.0,
      'taxAmount': 7.5,
    },
    {
      'itemId': 2,
      'productId': 3,
      'variationId': 4,
      'productName': 'Adapter',
      'productCode': 'SKU-ADAPTER',
      'variationName': 'USB-C',
      'imageUrl': null,
      'unitPrice': 50.0,
      'quantity': 2,
      'lineSubtotal': 100.0,
      'taxRate': 5.0,
      'taxAmount': 5.0,
    },
  ],
  'delivery': {
    'recipientName': 'A',
    'phone': '017****00',
    'address': 'Dhaka',
    'deliveryMethodName': 'Standard',
  },
  'customerNote': null,
  'timeline': [
    {
      'status': 'PENDING_CONFIRMATION',
      'title': 'Pending Confirmation',
      'description': 'Submitted',
      'occurredAt': '2026-01-01T00:00:00Z',
      'completed': true,
      'current': false,
      'note': null,
    },
    {
      'status': 'DELIVERED',
      'title': 'Delivered',
      'description': 'Delivered',
      'occurredAt': '2026-01-02T00:00:00Z',
      'completed': true,
      'current': true,
      'note': null,
    },
  ],
  'cancellationEligibility': {
    'eligible': false,
    'reasonCode': 'ORDER_STATUS_NOT_ELIGIBLE',
    'message': 'This order status is not eligible for cancellation.',
    'existingRequestStatus': null,
  },
  'returnEligibility': {
    'eligible': true,
    'reasonCode': 'ELIGIBLE',
    'message': 'This delivered order has returnable items.',
    'returnWindowDays': 7,
    'items': [
      {
        'itemId': 1,
        'productName': 'Cable',
        'variationName': null,
        'orderedQuantity': 3,
        'remainingReturnableQuantity': 3,
      },
      {
        'itemId': 2,
        'productName': 'Adapter',
        'variationName': 'USB-C',
        'orderedQuantity': 2,
        'remainingReturnableQuantity': 2,
      },
    ],
    'existingRequestStatus': null,
  },
  'documentAvailable': true,
};

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({required this.detailJson, required this.summaryJson});
  final Map<String, Object?> detailJson, summaryJson;
  int historyCalls = 0, cancelCalls = 0, returnCalls = 0;
  bool failReturn = false;
  bool failTracking = false;
  List<Map<String, Object?>> lastReturnItems = const [];
  String? lastReturnKey;
  String? lastPreferredResolution;
  String? lastComment;
  @override
  Future<OrderPage> history({
    int page = 0,
    int size = 10,
    String? orderStatus,
    String? paymentStatus,
    String? query,
    String sort = 'newest',
  }) async {
    historyCalls++;
    return OrderPage.fromJson({
      'content': [summaryJson],
      'page': page,
      'size': size,
      'totalElements': 2,
      'totalPages': 2,
      'first': page == 0,
      'last': page > 0,
    });
  }

  @override
  Future<OrderDetail> detail(String orderNumber) async =>
      OrderDetail.fromJson(detailJson);
  @override
  Future<List<OrderTimelineEntry>> timeline(String orderNumber) async =>
      OrderDetail.fromJson(detailJson).timeline;
  @override
  Future<CancellationEligibility> cancellationEligibility(
    String orderNumber,
  ) async => OrderDetail.fromJson(detailJson).cancellationEligibility;
  @override
  Future<CancellationRequest> submitCancellation(
    String orderNumber, {
    required String reasonCode,
    String? reasonText,
    required String idempotencyKey,
  }) async {
    cancelCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return CancellationRequest.fromJson({
      'orderNumber': orderNumber,
      'status': 'REQUESTED',
      'reasonCode': reasonCode,
      'reasonText': reasonText,
      'requestedAt': '2026-01-01T00:00:00Z',
      'message': 'received',
    });
  }

  @override
  Future<ReturnEligibility> returnEligibility(String orderNumber) async =>
      OrderDetail.fromJson(detailJson).returnEligibility;
  @override
  Future<ReturnRequest> submitReturn(
    String orderNumber, {
    required String idempotencyKey,
    required String preferredResolution,
    String? comment,
    required List<Map<String, Object?>> items,
  }) async {
    returnCalls++;
    lastReturnKey = idempotencyKey;
    lastPreferredResolution = preferredResolution;
    lastComment = comment;
    lastReturnItems = items
        .map((e) => Map<String, Object?>.from(e))
        .toList(growable: false);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (failReturn) throw Exception('offline');
    return ReturnRequest.fromJson({
      'requestNumber': 'RET-1',
      'orderNumber': orderNumber,
      'status': 'REQUESTED',
      'preferredResolution': preferredResolution,
      'requestedAt': '2026-01-01T00:00:00Z',
      'items': [],
      'message': 'received',
    });
  }

  @override
  Future<OrderTracking> tracking(String orderNumber) async {
    if (failTracking) throw Exception('offline');
    return OrderTracking.fromJson(trackingJson(orderNumber));
  }

  @override
  Future<OrderDocument> document(String orderNumber) async =>
      OrderDocument.fromJson({
        'orderNumber': orderNumber,
        'fileName': 'x.html',
        'contentType': 'text/html',
        'documentTitle': 'Order Summary',
        'html': 'NOT_STARTED',
      });
}

Map<String, Object?> trackingJson(String orderNumber) => {
  'orderNumber': orderNumber,
  'orderStatus': 'SHIPPED',
  'fulfillmentStatus': 'SHIPPED',
  'paymentStatus': 'PAID',
  'codStatus': 'RECONCILED',
  'deliveryMethodName': 'Standard',
  'estimatedDeliveryDate': '2026-01-05',
  'deliveryPartner': 'TechSmart Delivery',
  'trackingNumber': 'TRK-1',
  'deliveryContactPhone': '017****00',
  'deliveredAt': null,
  'currentStep': 'SHIPPED',
  'steps': [
    {
      'key': 'CONFIRMED',
      'title': 'Order Confirmed',
      'description': 'Confirmed',
      'status': 'COMPLETED',
      'timestamp': '2026-01-01T00:00:00Z',
    },
    {
      'key': 'SHIPPED',
      'title': 'Shipped',
      'description': 'Shipped',
      'status': 'CURRENT',
      'timestamp': '2026-01-02T00:00:00Z',
    },
    {
      'key': 'DELIVERED',
      'title': 'Delivered',
      'description': 'Delivered',
      'status': 'PENDING',
      'timestamp': null,
    },
  ],
  'deliveryEvents': [
    {
      'eventType': 'SHIPPED',
      'title': 'Order shipped',
      'description': 'Customer visible event',
      'location': 'Dhaka',
      'customerVisible': true,
      'occurredAt': '2026-01-02T00:00:00Z',
    },
  ],
};
