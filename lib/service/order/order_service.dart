import '../../model/order/order_models.dart';
import '../../model/tracking/order_tracking_models.dart';
import '../api/api_client.dart';

abstract class OrderRepository {
  Future<OrderPage> history({
    int page = 0,
    int size = 10,
    String? orderStatus,
    String? paymentStatus,
    String? query,
    String sort = 'newest',
  });
  Future<OrderDetail> detail(String orderNumber);
  Future<List<OrderTimelineEntry>> timeline(String orderNumber);
  Future<CancellationEligibility> cancellationEligibility(String orderNumber);
  Future<CancellationRequest> submitCancellation(
    String orderNumber, {
    required String reasonCode,
    String? reasonText,
    required String idempotencyKey,
  });
  Future<ReturnEligibility> returnEligibility(String orderNumber);
  Future<ReturnRequest> submitReturn(
    String orderNumber, {
    required String idempotencyKey,
    required String preferredResolution,
    String? comment,
    required List<Map<String, Object?>> items,
  });
  Future<OrderDocument> document(String orderNumber);
  Future<OrderTracking> tracking(String orderNumber);
}

class OrderService implements OrderRepository {
  OrderService(this.client);
  final ApiClient client;
  @override
  Future<OrderPage> history({
    int page = 0,
    int size = 10,
    String? orderStatus,
    String? paymentStatus,
    String? query,
    String sort = 'newest',
  }) async => OrderPage.fromJson(
    await client.get(
      'orders',
      authenticated: true,
      queryParameters: {
        'page': '$page',
        'size': '$size',
        'orderStatus': orderStatus,
        'paymentStatus': paymentStatus,
        'query': query,
        'sort': sort,
      },
    ),
  );
  @override
  Future<OrderDetail> detail(String n) async =>
      OrderDetail.fromJson(await client.get('orders/$n', authenticated: true));
  @override
  Future<List<OrderTimelineEntry>> timeline(String n) async =>
      (await client.get('orders/$n/timeline', authenticated: true) as List)
          .map(OrderTimelineEntry.fromJson)
          .toList();
  @override
  Future<CancellationEligibility> cancellationEligibility(String n) async =>
      CancellationEligibility.fromJson(
        await client.get(
          'orders/$n/cancellation-eligibility',
          authenticated: true,
        ),
      );
  @override
  Future<CancellationRequest> submitCancellation(
    String n, {
    required String reasonCode,
    String? reasonText,
    required String idempotencyKey,
  }) async => CancellationRequest.fromJson(
    await client.post(
      'orders/$n/cancellation-requests',
      authenticated: true,
      body: {
        'reasonCode': reasonCode,
        'reasonText': reasonText,
        'idempotencyKey': idempotencyKey,
      },
    ),
  );
  @override
  Future<ReturnEligibility> returnEligibility(String n) async =>
      ReturnEligibility.fromJson(
        await client.get('orders/$n/return-eligibility', authenticated: true),
      );
  @override
  Future<ReturnRequest> submitReturn(
    String n, {
    required String idempotencyKey,
    required String preferredResolution,
    String? comment,
    required List<Map<String, Object?>> items,
  }) async => ReturnRequest.fromJson(
    await client.post(
      'orders/$n/return-requests',
      authenticated: true,
      body: {
        'idempotencyKey': idempotencyKey,
        'preferredResolution': preferredResolution,
        'customerComment': comment,
        'items': items,
      },
    ),
  );
  @override
  Future<OrderDocument> document(String n) async => OrderDocument.fromJson(
    await client.get('orders/$n/document', authenticated: true),
  );
  @override
  Future<OrderTracking> tracking(String n) async => OrderTracking.fromJson(
    await client.get('orders/$n/tracking', authenticated: true),
  );
}
