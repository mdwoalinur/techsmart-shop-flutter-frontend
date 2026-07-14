import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tech_smart_shop/model/address/address_models.dart';
import 'package:tech_smart_shop/model/checkout/checkout_models.dart';
import 'package:tech_smart_shop/service/api/api_client.dart';
import 'package:tech_smart_shop/service/checkout/checkout_service.dart';

void main() {
  final address = {
    'id': 1,
    'label': 'Home',
    'recipientName': 'A',
    'phone': '01700000000',
    'addressLine1': 'Road 1',
    'addressLine2': null,
    'area': null,
    'city': 'Dhaka',
    'district': 'Dhaka',
    'division': 'Dhaka',
    'postalCode': null,
    'country': 'Bangladesh',
    'deliveryInstructions': null,
    'defaultAddress': true,
    'active': true,
  };
  final method = {
    'id': 1,
    'code': 'STANDARD',
    'name': 'Standard',
    'description': 'x',
    'deliveryCharge': 80.0,
    'estimatedMinDays': 3,
    'estimatedMaxDays': 5,
    'eligible': true,
    'ineligibilityReason': null,
  };
  test('address parses safe ownership-free response', () {
    final a = CustomerAddress.fromJson(address);
    expect(a.isDefault, true);
    expect(a.summary, contains('Dhaka'));
  });
  test('delivery method parses server charge and eligibility', () {
    final m = DeliveryMethod.fromJson(method);
    expect(m.charge.value, '80.0');
    expect(m.eligible, true);
  });
  test('checkout review parses authoritative decimal totals', () {
    final r = CheckoutReview.fromJson({
      'reviewId': 'r',
      'reviewExpiresAt': '2030-01-01T00:00:00Z',
      'subtotal': 100.0,
      'taxTotal': 5.0,
      'deliveryCharge': 80.0,
      'discountTotal': 0.0,
      'grandTotal': 185.0,
      'address': address,
      'deliveryMethod': method,
      'blockingIssues': [],
      'warnings': [],
      'readyToSubmit': true,
    });
    expect(r.total.value, '185.0');
    expect(r.ready, true);
  });
  test('submit sends no client totals or status', () async {
    late Map<String, dynamic> body;
    final client = ApiClient(
      client: MockClient((r) async {
        body = jsonDecode(r.body);
        return http.Response(
          jsonEncode({
            'orderNumber': 'TSS-X',
            'submittedAt': '2026-01-01T00:00:00Z',
            'orderStatus': 'PENDING_CONFIRMATION',
            'paymentStatus': 'NOT_STARTED',
            'grandTotal': 185.0,
            'deliveryAddress': 'Dhaka',
            'deliveryMethod': 'Standard',
            'nextStep': 'Awaiting confirmation',
          }),
          200,
        );
      }),
      baseUri: Uri.parse('http://x/api/mobile/v1'),
    );
    final o = await CheckoutService(client).submit('r', 'once', true);
    expect(o.paymentStatus, 'NOT_STARTED');
    expect(body.containsKey('grandTotal'), false);
    expect(body.containsKey('orderStatus'), false);
  });
  test('address request contains no ownership field', () {
    final j = AddressDraft(
      recipientName: 'A',
      phone: '01700000000',
      addressLine1: 'R',
      city: 'D',
      district: 'D',
      division: 'D',
    ).toJson();
    expect(j.containsKey('customerId'), false);
    expect(j.containsKey('accountId'), false);
  });
}
