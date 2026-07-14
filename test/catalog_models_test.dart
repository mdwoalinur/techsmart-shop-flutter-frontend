import 'package:flutter_test/flutter_test.dart';
import 'package:tech_smart_shop/model/common/api_models.dart';
import 'package:tech_smart_shop/model/product/catalog_models.dart';

Map<String, Object?> productJson() => {
  'id': 32,
  'productCode': 'ANKER',
  'sku': null,
  'name': 'Hub',
  'description': null,
  'sellingPrice': 24590.50,
  'taxRate': 15,
  'imageUrl': null,
  'category': null,
  'unit': null,
  'stock': {'inStock': true, 'stockLabel': 'In Stock'},
};
void main() {
  test('parses success page and product safely', () {
    final value = {
      'success': true,
      'data': {
        'content': [productJson()],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
        'first': true,
        'last': true,
      },
      'message': null,
    };
    final envelope = ApiEnvelope<ApiPage<ProductSummary>>.fromJson(
      value,
      (v) => ApiPage.fromJson(v, ProductSummary.fromJson),
    );
    expect(envelope.data.content.single.name, 'Hub');
    expect(
      MoneyFormatter.taka(envelope.data.content.single.sellingPrice),
      '৳24,590.5',
    );
  });
  test('parses detail and variation', () {
    final json = {
      ...productJson(),
      'variations': [
        {
          'id': 1,
          'name': 'Silver',
          'sku': null,
          'effectivePrice': 25000,
          'additionalPrice': 409.5,
          'imageUrl': null,
          'stock': {'inStock': true, 'stockLabel': 'Low Stock'},
        },
      ],
    };
    final d = ProductDetail.fromJson(json);
    expect(d.variations.single.effectivePrice.value, '25000');
    expect(d.variations.single.stock.stockLabel, 'Low Stock');
  });
  test('malformed required field throws useful parse exception', () {
    final json = productJson()..remove('name');
    expect(
      () => ProductSummary.fromJson(json),
      throwsA(isA<CatalogParseException>()),
    );
  });
  test('parses mobile validation error', () {
    final e = MobileApiError.fromJson({
      'success': false,
      'code': 'VALIDATION_ERROR',
      'message': 'Invalid',
      'fieldErrors': [
        {'field': 'minPrice', 'message': 'Bad'},
      ],
    });
    expect(e.fieldErrors.single.field, 'minPrice');
  });
  test('money formatter preserves meaningful decimal digits', () {
    expect(MoneyFormatter.taka(DecimalValue.fromInput('25000.00')), '৳25,000');
    expect(
      MoneyFormatter.taka(DecimalValue.fromInput('24590.50')),
      '৳24,590.50',
    );
  });
}
