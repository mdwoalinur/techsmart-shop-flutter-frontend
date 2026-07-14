import '../../model/address/address_models.dart';
import '../../model/checkout/checkout_models.dart';
import '../api/api_client.dart';

abstract class CheckoutRepository {
  Future<List<CustomerAddress>> addresses();
  Future<CustomerAddress> createAddress(AddressDraft d);
  Future<CustomerAddress> updateAddress(int id, AddressDraft d);
  Future<void> deleteAddress(int id);
  Future<CustomerAddress> setDefault(int id);
  Future<List<DeliveryMethod>> deliveryMethods({int? addressId});
  Future<CheckoutReview> review(int addressId, int methodId);
  Future<OrderConfirmation> submit(
    String reviewId,
    String key,
    bool terms, {
    String? note,
  });
}

class CheckoutService implements CheckoutRepository {
  CheckoutService(this.client);
  final ApiClient client;
  @override
  Future<List<CustomerAddress>> addresses() async =>
      (await client.get('addresses', authenticated: true) as List)
          .map(CustomerAddress.fromJson)
          .toList();
  @override
  Future<CustomerAddress> createAddress(AddressDraft d) async =>
      CustomerAddress.fromJson(
        await client.post('addresses', authenticated: true, body: d.toJson()),
      );
  @override
  Future<CustomerAddress> updateAddress(int id, AddressDraft d) async =>
      CustomerAddress.fromJson(
        await client.put(
          'addresses/$id',
          authenticated: true,
          body: d.toJson(),
        ),
      );
  @override
  Future<void> deleteAddress(int id) async {
    await client.delete('addresses/$id', authenticated: true);
  }

  @override
  Future<CustomerAddress> setDefault(int id) async => CustomerAddress.fromJson(
    await client.post('addresses/$id/default', authenticated: true),
  );
  @override
  Future<List<DeliveryMethod>> deliveryMethods({int? addressId}) async =>
      (await client.get(
                'delivery-methods',
                authenticated: addressId != null,
                queryParameters: {'addressId': addressId?.toString()},
              )
              as List)
          .map(DeliveryMethod.fromJson)
          .toList();
  @override
  Future<CheckoutReview> review(int a, int m) async => CheckoutReview.fromJson(
    await client.post(
      'checkout/review',
      authenticated: true,
      body: {'addressId': a, 'deliveryMethodId': m},
    ),
  );
  @override
  Future<OrderConfirmation> submit(
    String r,
    String k,
    bool t, {
    String? note,
  }) async => OrderConfirmation.fromJson(
    await client.post(
      'checkout/submit',
      authenticated: true,
      body: {
        'reviewId': r,
        'idempotencyKey': k,
        'termsAccepted': t,
        'customerNote': note,
      },
    ),
  );
}
