import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tech_smart_shop/model/product/catalog_models.dart';
import 'package:tech_smart_shop/service/api/api_client.dart';
import 'package:tech_smart_shop/service/catalog/catalog_service.dart';

const product =
    '{"id":32,"productCode":"ANKER","sku":null,"name":"Hub","description":null,"sellingPrice":5500,"taxRate":15,"imageUrl":null,"category":null,"unit":null,"stock":{"inStock":true,"stockLabel":"In Stock"}}';
String page() =>
    '{"success":true,"data":{"content":[$product],"page":0,"size":20,"totalElements":1,"totalPages":1,"first":true,"last":true},"message":null}';

void main() {
  test('constructs encoded product query from supported filters', () async {
    late Uri uri;
    final api = ApiClient(
      baseUri: Uri.parse('https://example.test/api/mobile/v1'),
      client: MockClient((request) async {
        uri = request.url;
        return http.Response(page(), 200);
      }),
    );
    await CatalogService(api).fetchProducts(
      sort: CatalogSort.priceDesc,
      filters: CatalogFilters(
        categoryId: 4,
        minPrice: DecimalValue.fromInput('100.50'),
        maxPrice: DecimalValue.fromInput('9000'),
        inStockOnly: true,
      ),
    );
    expect(uri.path, '/api/mobile/v1/products');
    expect(uri.queryParameters, containsPair('sort', 'price'));
    expect(uri.queryParameters, containsPair('direction', 'desc'));
    expect(uri.queryParameters, containsPair('categoryId', '4'));
    expect(uri.queryParameters, containsPair('inStock', 'true'));
    api.close();
  });
  test('search safely encodes query', () async {
    late Uri uri;
    final api = ApiClient(
      baseUri: Uri.parse('https://example.test/api/mobile/v1'),
      client: MockClient((request) async {
        uri = request.url;
        return http.Response(page(), 200);
      }),
    );
    await CatalogService(api).searchProducts('usb c & hub');
    expect(uri.queryParameters['q'], 'usb c & hub');
    api.close();
  });
  for (final status in [400, 404, 500]) {
    test('maps $status mobile error', () async {
      final api = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            '{"success":false,"code":"FAIL","message":"Safe message","fieldErrors":[]}',
            status,
          ),
        ),
        baseUri: Uri.parse('https://example.test/api/mobile/v1'),
      );
      await expectLater(
        CatalogService(api).fetchProduct(9),
        throwsA(
          isA<CatalogRequestException>()
              .having((e) => e.statusCode, 'status', status)
              .having((e) => e.message, 'message', 'Safe message'),
        ),
      );
      api.close();
    });
  }
  test('maps timeout without leaking exception', () async {
    final api = ApiClient(
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{}', 200);
      }),
      baseUri: Uri.parse('https://example.test'),
      requestTimeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      CatalogService(api).fetchCategories(),
      throwsA(
        isA<CatalogRequestException>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
    api.close();
  });
  test('maps network failure', () async {
    final api = ApiClient(
      client: MockClient((_) async => throw http.ClientException('secret')),
      baseUri: Uri.parse('https://example.test'),
    );
    await expectLater(
      CatalogService(api).fetchCategories(),
      throwsA(
        isA<CatalogRequestException>().having(
          (e) => e.message,
          'message',
          contains('Unable to connect to the server. Please try again.'),
        ),
      ),
    );
    api.close();
  });
}
