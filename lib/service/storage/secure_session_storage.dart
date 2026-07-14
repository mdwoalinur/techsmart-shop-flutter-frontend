import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../model/auth/auth_models.dart';

abstract interface class SessionStorage {
  Future<void> save(AuthSession session);
  Future<AuthSession?> load();
  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());
  final FlutterSecureStorage _storage;
  static const _access = 'customer_access_token',
      _refresh = 'customer_refresh_token',
      _accessExpiry = 'customer_access_expiry',
      _refreshExpiry = 'customer_refresh_expiry';
  @override
  Future<void> save(AuthSession s) async {
    await _storage.write(key: _access, value: s.accessToken);
    await _storage.write(key: _refresh, value: s.refreshToken);
    await _storage.write(
      key: _accessExpiry,
      value: s.accessTokenExpiresAt.toIso8601String(),
    );
    await _storage.write(
      key: _refreshExpiry,
      value: s.refreshTokenExpiresAt.toIso8601String(),
    );
  }

  @override
  Future<AuthSession?> load() async {
    try {
      final a = await _storage.read(key: _access),
          r = await _storage.read(key: _refresh),
          ae = await _storage.read(key: _accessExpiry),
          re = await _storage.read(key: _refreshExpiry);
      if ([a, r, ae, re].any((e) => e == null || e.isEmpty)) {
        await clear();
        return null;
      }
      return AuthSession(
        accessToken: a!,
        refreshToken: r!,
        accessTokenExpiresAt: DateTime.parse(ae!).toUtc(),
        refreshTokenExpiresAt: DateTime.parse(re!).toUtc(),
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> clear() => _storage.deleteAll();
}
