import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tech_smart_shop/model/auth/auth_models.dart';
import 'package:tech_smart_shop/service/api/api_client.dart';
import 'package:tech_smart_shop/service/api/api_exception.dart';
import 'package:tech_smart_shop/service/auth/auth_service.dart';
import 'support/fake_auth.dart';

http.Response jsonResponse(Object body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
Map<String, Object?> envelope(Object data) => {
  'success': true,
  'data': data,
  'message': null,
  'timestamp': '2026-07-01T00:00:00Z',
};
Map<String, Object?> profile() => {
  'customerId': 7,
  'customerCode': 'C7',
  'fullName': 'Test Customer',
  'email': 'test@example.com',
  'phone': '01712345678',
  'customerType': 'RETAIL',
  'emailVerified': true,
};
Map<String, Object?> session() => {
  'accessToken': 'access',
  'refreshToken': 'refresh',
  'accessTokenExpiresAt': '2030-01-01T00:00:00Z',
  'refreshTokenExpiresAt': '2030-02-01T00:00:00Z',
  'profile': profile(),
};
void main() {
  test('authenticated request attaches bearer token', () async {
    late http.Request seen;
    final c = ApiClient(
      client: MockClient((r) async {
        seen = r;
        return jsonResponse(envelope({'ok': true}));
      }),
      baseUri: Uri.parse('http://test/api/mobile/v1'),
    );
    c.configureAuth(
      accessToken: () async => 'secret',
      refresh: () async => false,
      sessionInvalid: () async {},
    );
    await c.get('auth/me', authenticated: true);
    expect(seen.headers['Authorization'], 'Bearer secret');
  });
  test('401 performs a single refresh and retries once', () async {
    var token = 'old', requests = 0, refreshes = 0;
    final c = ApiClient(
      client: MockClient((r) async {
        requests++;
        return r.headers['Authorization'] == 'Bearer old'
            ? jsonResponse({'message': 'expired'}, status: 401)
            : jsonResponse(envelope({'ok': true}));
      }),
      baseUri: Uri.parse('http://test/api/mobile/v1'),
    );
    c.configureAuth(
      accessToken: () async => token,
      refresh: () async {
        refreshes++;
        token = 'new';
        return true;
      },
      sessionInvalid: () async {},
    );
    await c.get('auth/me', authenticated: true);
    expect(refreshes, 1);
    expect(requests, 2);
  });
  test('simultaneous 401 responses share one refresh', () async {
    var token = 'old', refreshes = 0;
    final gate = Completer<void>();
    final c = ApiClient(
      client: MockClient(
        (r) async => r.headers['Authorization'] == 'Bearer old'
            ? jsonResponse({'message': 'expired'}, status: 401)
            : jsonResponse(envelope({'ok': true})),
      ),
      baseUri: Uri.parse('http://test/api/mobile/v1'),
    );
    c.configureAuth(
      accessToken: () async => token,
      refresh: () async {
        refreshes++;
        await gate.future;
        token = 'new';
        return true;
      },
      sessionInvalid: () async {},
    );
    final calls = [
      c.get('auth/me', authenticated: true),
      c.get('auth/me', authenticated: true),
    ];
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    await Future.wait(calls);
    expect(refreshes, 1);
  });
  test('public request remains token free', () async {
    late http.Request seen;
    final c = ApiClient(
      client: MockClient((r) async {
        seen = r;
        return jsonResponse(envelope([]));
      }),
      baseUri: Uri.parse('http://test/api/mobile/v1'),
    );
    await c.get('products');
    expect(seen.headers.containsKey('Authorization'), isFalse);
  });
  test(
    'AuthService maps every endpoint and clears after logout/change',
    () async {
      final paths = <String>[], store = MemorySessionStorage();
      final client = ApiClient(
        client: MockClient((r) async {
          paths.add('${r.method} ${r.url.path}');
          final p = r.url.path;
          if (p.endsWith('/register') ||
              p.endsWith('/resend-registration-otp')) {
            return jsonResponse(
              envelope({
                'maskedEmail': 't***@example.com',
                'otpExpiresInSeconds': 600,
                'resendAvailableInSeconds': 45,
              }),
            );
          }
          if (p.endsWith('/verify-registration') ||
              p.endsWith('/login') ||
              p.endsWith('/refresh')) {
            return jsonResponse(envelope(session()));
          }
          if (p.endsWith('/verify-password-reset-otp')) {
            return jsonResponse(
              envelope({
                'resetToken': 'reset',
                'expiresAt': '2030-01-01T00:00:00Z',
              }),
            );
          }
          if (p.endsWith('/me')) return jsonResponse(envelope(profile()));
          return jsonResponse(envelope({'message': 'ok'}));
        }),
        baseUri: Uri.parse('http://test/api/mobile/v1'),
      );
      final s = AuthService(client, store);
      await s.register(
        fullName: 'Test',
        email: 't@example.com',
        phone: '01712345678',
        password: 'Strong1!',
        confirmPassword: 'Strong1!',
        termsAccepted: true,
      );
      await s.verifyRegistration('t@example.com', '123456');
      await s.resendRegistration('t@example.com');
      await s.login('t@example.com', 'Strong1!');
      await s.refreshSession();
      await s.forgotPassword('t@example.com');
      await s.verifyResetOtp('t@example.com', '123456');
      await s.resetPassword('reset', 'OtherPass2@', 'OtherPass2@');
      await s.profile();
      await s.updateProfile({'fullName': 'Test', 'phone': '01712345678'});
      await s.changePassword('Strong1!', 'OtherPass2@', 'OtherPass2@');
      expect(await store.load(), isNull);
      expect(
        paths,
        containsAll([
          'POST /api/mobile/v1/auth/register',
          'POST /api/mobile/v1/auth/login',
          'POST /api/mobile/v1/auth/refresh',
          'GET /api/mobile/v1/auth/me',
          'PUT /api/mobile/v1/auth/me',
          'POST /api/mobile/v1/auth/change-password',
        ]),
      );
    },
  );
  test('403 does not refresh and exposes a safe permission message', () async {
    var refreshes = 0;
    final c = ApiClient(
      client: MockClient(
        (r) async => jsonResponse({'message': 'denied'}, status: 403),
      ),
      baseUri: Uri.parse('http://test/api/mobile/v1'),
    );
    c.configureAuth(
      accessToken: () async => 'secret',
      refresh: () async {
        refreshes++;
        return true;
      },
      sessionInvalid: () async {},
    );
    await expectLater(
      c.get('cart', authenticated: true),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 403)
            .having(
              (e) => e.message,
              'message',
              'You do not have permission to perform this action.',
            ),
      ),
    );
    expect(refreshes, 0);
  });

  test('refresh stores the replacement access token', () async {
    final store = MemorySessionStorage()
      ..value = testSession().copyWithForTest(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
    final client = ApiClient(
      client: MockClient(
        (r) async => jsonResponse(
          envelope({
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'accessTokenExpiresAt': '2030-01-01T00:00:00Z',
            'refreshTokenExpiresAt': '2030-02-01T00:00:00Z',
            'profile': profile(),
          }),
        ),
      ),
      baseUri: Uri.parse('http://test/api/mobile/v1'),
    );
    final service = AuthService(client, store);
    expect(await service.refreshSession(), isTrue);
    final saved = await store.load();
    expect(saved!.accessToken, 'new-access');
    expect(saved.refreshToken, 'new-refresh');
  });

  test('401 refresh failure invokes session invalid callback', () async {
    final store = MemorySessionStorage()..value = testSession();
    var invalidated = false;
    final client = ApiClient(
      client: MockClient(
        (r) async => jsonResponse({'message': 'expired'}, status: 401),
      ),
      baseUri: Uri.parse('http://test/api/mobile/v1'),
    );
    final service = AuthService(client, store)
      ..sessionInvalidHandler = () async => invalidated = true;
    expect(service.sessionInvalidHandler, isNotNull);
    await expectLater(
      client.get('cart', authenticated: true),
      throwsA(isA<ApiException>()),
    );
    expect(invalidated, isTrue);
    expect(await store.load(), isNull);
  });

  test('profile photo upload uses authenticated multipart endpoint', () async {
    late http.BaseRequest seen;
    final store = MemorySessionStorage()..value = testSession();
    final client = ApiClient(
      client: MockClient((r) async {
        seen = r;
        return jsonResponse(
          envelope({
            'customerId': 7,
            'customerCode': 'C7',
            'fullName': 'Test Customer',
            'email': 'test@example.com',
            'phone': '01712345678',
            'customerType': 'RETAIL',
            'emailVerified': true,
            'photoUrl': '/uploads/customers/profile/7/avatar.jpg',
          }),
        );
      }),
      baseUri: Uri.parse('http://test/api/mobile/v1'),
    );
    final service = AuthService(client, store);
    final updated = await service.uploadProfilePhoto(
      bytes: [0xFF, 0xD8, 0xFF, 0],
      filename: 'avatar.jpg',
    );
    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/mobile/v1/profile/photo');
    expect(seen.headers['Authorization'], 'Bearer access-secret');
    expect(seen.headers['content-type'], contains('multipart/form-data'));
    expect(seen.headers['content-type'], contains('boundary='));
    expect(updated.photoUrl, '/uploads/customers/profile/7/avatar.jpg');
  });
  test('raw ApiException text is never the user safe message', () {
    const error = ApiException(
      type: ApiExceptionType.unauthorized,
      message: 'server detail',
      statusCode: 401,
    );
    expect(
      userSafeApiMessage(error),
      'Your session has expired. Please sign in again.',
    );
    expect(userSafeApiMessage(error), isNot(contains('ApiException')));
  });
}

extension on AuthSession {
  AuthSession copyWithForTest({String? accessToken, String? refreshToken}) =>
      AuthSession(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        accessTokenExpiresAt: accessTokenExpiresAt,
        refreshTokenExpiresAt: refreshTokenExpiresAt,
        profile: this.profile,
      );
}
