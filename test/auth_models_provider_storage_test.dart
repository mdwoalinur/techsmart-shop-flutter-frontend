import 'package:flutter_test/flutter_test.dart';
import 'package:tech_smart_shop/model/auth/auth_models.dart';
import 'package:tech_smart_shop/model/customer/customer_profile.dart';
import 'package:tech_smart_shop/provider/auth_provider.dart';
import 'support/fake_auth.dart';

void main() {
  test('auth models parse supported responses and redact secrets', () {
    final p = CustomerProfile.fromJson({
      'customerId': 7,
      'customerCode': 'C7',
      'fullName': 'Test',
      'email': 't@example.com',
      'phone': '01712345678',
      'customerType': 'RETAIL',
      'emailVerified': true,
      'photoUrl': '/uploads/customers/profile/7/avatar.jpg',
    });
    final s = AuthSession.fromJson({
      'accessToken': 'access-secret',
      'refreshToken': 'refresh-secret',
      'accessTokenExpiresAt': '2030-01-01T00:00:00Z',
      'refreshTokenExpiresAt': '2030-02-01T00:00:00Z',
      'profile': {
        'customerId': 7,
        'customerCode': 'C7',
        'fullName': 'Test',
        'email': 't@example.com',
        'phone': '01712345678',
        'customerType': 'RETAIL',
        'emailVerified': true,
      },
    });
    expect(p.email, 't@example.com');
    expect(p.photoUrl, '/uploads/customers/profile/7/avatar.jpg');
    expect(s.toString(), isNot(contains('access-secret')));
    expect(s.toString(), isNot(contains('refresh-secret')));
  });
  test(
    'malformed auth response fails safely',
    () => expect(
      () => AuthSession.fromJson({'accessToken': 'x'}),
      throwsFormatException,
    ),
  );
  test(
    'memory storage saves loads clears and recovers corrupt state',
    () async {
      final store = MemorySessionStorage();
      await store.save(testSession());
      expect((await store.load())!.accessToken, 'access-secret');
      expect(
        store.written.keys,
        containsAll(['access', 'refresh', 'accessExpiry', 'refreshExpiry']),
      );
      expect(
        store.written.values.every((v) => !v.contains('password')),
        isTrue,
      );
      expect(store.written.values.every((v) => !v.contains('otp')), isTrue);
      store.corrupt = true;
      expect(await store.load(), isNull);
      expect(store.written, isEmpty);
    },
  );
  test('provider initializes guest without session', () async {
    final p = AuthProvider(
      FakeAuthRepository(),
      MemorySessionStorage(),
      autoInitialize: false,
    );
    await p.initialize();
    expect(p.state, AuthState.guest);
  });
  test('provider restores valid authenticated session', () async {
    final repo = FakeAuthRepository(),
        store = MemorySessionStorage()..value = testSession();
    final p = AuthProvider(repo, store, autoInitialize: false);
    await p.initialize();
    expect(p.authenticated, isTrue);
    expect(p.profile!.email, 'test@example.com');
  });
  test('expired access refreshes once during restoration', () async {
    final repo = FakeAuthRepository(),
        store = MemorySessionStorage()
          ..value = AuthSession(
            accessToken: 'a',
            refreshToken: 'r',
            accessTokenExpiresAt: DateTime.now().toUtc().subtract(
              const Duration(seconds: 1),
            ),
            refreshTokenExpiresAt: DateTime.now().toUtc().add(
              const Duration(days: 1),
            ),
          );
    final p = AuthProvider(repo, store, autoInitialize: false);
    await p.initialize();
    expect(repo.refreshCalls, 1);
    expect(p.authenticated, isTrue);
  });
  test('refresh failure clears session and becomes guest', () async {
    final repo = FakeAuthRepository()..fail = true,
        store = MemorySessionStorage()
          ..value = AuthSession(
            accessToken: 'a',
            refreshToken: 'r',
            accessTokenExpiresAt: DateTime.now().toUtc().subtract(
              const Duration(seconds: 1),
            ),
            refreshTokenExpiresAt: DateTime.now().toUtc().add(
              const Duration(days: 1),
            ),
          );
    final p = AuthProvider(repo, store, autoInitialize: false);
    await p.initialize();
    expect(p.state, AuthState.guest);
    expect(await store.load(), isNull);
  });
  test('registration verification login logout and recovery state', () async {
    final repo = FakeAuthRepository(),
        store = MemorySessionStorage(),
        p = AuthProvider(repo, store, autoInitialize: false);
    expect(
      await p.register(
        fullName: 'Test',
        email: 'T@example.com',
        phone: '01712345678',
        password: 'Strong1!',
        confirmPassword: 'Strong1!',
        terms: true,
      ),
      isTrue,
    );
    expect(p.state, AuthState.pendingRegistrationVerification);
    expect(await p.verifyRegistration('123456'), isTrue);
    expect(p.authenticated, isTrue);
    await p.logout();
    expect(p.state, AuthState.guest);
    expect(repo.logoutCalls, 1);
    expect(await p.forgotPassword('t@example.com'), isTrue);
    expect(await p.verifyResetOtp('123456'), isTrue);
    expect(p.resetToken, 'reset-secret');
    expect(await p.resetPassword('OtherPass2@', 'OtherPass2@'), isTrue);
    expect(p.resetToken, isNull);
  });
  test('duplicate provider submission is blocked', () async {
    final repo = FakeAuthRepository(),
        p = AuthProvider(repo, MemorySessionStorage(), autoInitialize: false);
    final futures = [p.login('x', 'y'), p.login('x', 'y')];
    final values = await Future.wait(futures);
    expect(values.where((e) => e).length, 1);
    expect(repo.loginCalls, 1);
  });
  test(
    'expireSession clears false authenticated state and stored tokens',
    () async {
      final repo = FakeAuthRepository(),
          store = MemorySessionStorage()..value = testSession();
      final p = AuthProvider(repo, store, autoInitialize: false);
      await p.initialize();
      expect(p.authenticated, isTrue);
      await p.expireSession();
      expect(p.authenticated, isFalse);
      expect(p.state, AuthState.guest);
      expect(await store.load(), isNull);
      expect(p.error, 'Your session has expired. Please sign in again.');
    },
  );
}
