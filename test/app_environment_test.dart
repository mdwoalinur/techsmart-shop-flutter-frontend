import 'package:flutter_test/flutter_test.dart';
import 'package:tech_smart_shop/service/config/app_environment.dart';

void main() {
  test('uses the ADB reverse URL by default', () {
    expect(
      AppEnvironment.defaultApiBaseUrl,
      'http://127.0.0.1:8080/api/mobile/v1',
    );
  });

  test('normalizes a valid API base URL', () {
    final uri = AppEnvironment.resolveApiBaseUri(
      ' https://shop.example/api/mobile/v1/// ',
    );
    expect(uri.toString(), 'https://shop.example/api/mobile/v1');
  });

  test('rejects non-HTTP API base URLs', () {
    expect(
      () => AppEnvironment.resolveApiBaseUri('file:///temporary/api'),
      throwsFormatException,
    );
  });
}
