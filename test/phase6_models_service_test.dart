import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tech_smart_shop/model/cart/server_cart.dart';
import 'package:tech_smart_shop/model/wishlist/server_wishlist.dart';
import 'package:tech_smart_shop/service/api/api_client.dart';
import 'package:tech_smart_shop/service/shopping/customer_shopping_service.dart';

void main() {
  final cart = {
    'cartId': 1,
    'items': [
      {
        'itemId': 4,
        'productId': 2,
        'variationId': null,
        'productName': 'Phone',
        'productCode': 'P',
        'sku': 'S',
        'variationName': null,
        'imageUrl': null,
        'unitPrice': 10.25,
        'quantity': 3,
        'lineSubtotal': 30.75,
        'stockLabel': 'In Stock',
        'availableForPurchase': true,
        'validationMessage': null,
      },
    ],
    'totalItemLines': 1,
    'totalQuantity': 3,
    'subtotal': 30.75,
    'validationWarnings': [
      {
        'productId': 2,
        'variationId': null,
        'code': 'QUANTITY_ADJUSTED',
        'message': 'Capped',
      },
    ],
    'updatedAt': '2026-01-01T00:00:00Z',
  };
  test('Cart response parses server totals warnings and base identity', () {
    final value = ServerCart.fromJson(cart);
    expect(value.totalQuantity, 3);
    expect(value.subtotal.value, '30.75');
    expect(value.items.single.identity, '2:base');
    expect(value.warnings.single.code, 'QUANTITY_ADJUSTED');
  });
  test('Wishlist response parses safe current product state', () {
    final value = ServerWishlist.fromJson({
      'wishlistId': 1,
      'items': [
        {
          'productId': 2,
          'productName': 'Phone',
          'imageUrl': null,
          'sellingPrice': 99.50,
          'stockLabel': 'Out of Stock',
          'category': 'Mobile',
        },
      ],
      'totalItems': 1,
      'validationWarnings': [],
      'updatedAt': '2026-01-01T00:00:00Z',
    });
    expect(value.items.single.stockLabel, 'Out of Stock');
    expect(value.items.single.price.value, '99.5');
  });
  test('shopping service GET uses authenticated cart endpoint', () async {
    late http.Request request;
    final client = ApiClient(
      client: MockClient((r) async {
        request = r;
        return http.Response(
          jsonEncode(cart),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
      baseUri: Uri.parse('http://shop/api/mobile/v1'),
    );
    final value = await CustomerShoppingService(client).getCart();
    expect(request.url.path, '/api/mobile/v1/cart');
    expect(value.totalQuantity, 3);
  });
  test(
    'shopping service merge sends request id and safe item fields',
    () async {
      late Map<String, dynamic> body;
      final client = ApiClient(
        client: MockClient((r) async {
          body = jsonDecode(r.body);
          return http.Response(jsonEncode(cart), 200);
        }),
        baseUri: Uri.parse('http://shop/api/mobile/v1'),
      );
      await CustomerShoppingService(client).mergeCart('once-1', [
        {'productId': 2, 'variationId': null, 'quantity': 1},
      ]);
      expect(body['requestId'], 'once-1');
      expect(body['items'][0].containsKey('unitPrice'), isFalse);
    },
  );
  test('shopping service DELETE maps returned server state', () async {
    late String method;
    final client = ApiClient(
      client: MockClient((r) async {
        method = r.method;
        return http.Response(
          jsonEncode({
            ...cart,
            'items': [],
            'totalItemLines': 0,
            'totalQuantity': 0,
            'subtotal': 0,
          }),
          200,
        );
      }),
      baseUri: Uri.parse('http://shop/api/mobile/v1'),
    );
    final value = await CustomerShoppingService(client).removeCart(4);
    expect(method, 'DELETE');
    expect(value.items, isEmpty);
  });
}
