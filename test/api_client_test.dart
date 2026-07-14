import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tech_smart_shop/service/api/api_client.dart';
import 'package:tech_smart_shop/service/api/api_exception.dart';

void main() {
  test('parses JSON and builds a path below the central base URL', () async {
    late Uri requestedUri;
    final mock = MockClient((request) async {
      requestedUri = request.url;
      return http.Response('{"ready":true}', 200);
    });
    final client = ApiClient(
      client: mock,
      baseUri: Uri.parse('https://example.test/api/mobile/v1'),
    );

    final result = await client.get('/health');

    expect(requestedUri.path, '/api/mobile/v1/health');
    expect(result, {'ready': true});
    client.close();
  });

  test('maps unauthorized responses to a structured exception', () async {
    final client = ApiClient(
      client: MockClient((_) async => http.Response('{}', 401)),
      baseUri: Uri.parse('https://example.test/api/mobile/v1'),
    );

    await expectLater(
      client.get('/protected'),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.type,
              'type',
              ApiExceptionType.unauthorized,
            )
            .having((error) => error.statusCode, 'statusCode', 401),
      ),
    );
    client.close();
  });
}
