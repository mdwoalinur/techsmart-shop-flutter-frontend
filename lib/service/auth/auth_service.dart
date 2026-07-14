import '../../model/auth/auth_models.dart';
import '../../model/customer/customer_profile.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../storage/secure_session_storage.dart';

abstract interface class AuthRepository {
  Future<PendingVerification> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool termsAccepted,
  });
  Future<AuthSession> verifyRegistration(String email, String otp);
  Future<PendingVerification> resendRegistration(String email);
  Future<AuthSession> login(String email, String password);
  Future<bool> refreshSession();
  Future<void> logout();
  Future<void> forgotPassword(String email);
  Future<ResetAuthorization> verifyResetOtp(String email, String otp);
  Future<void> resetPassword(String token, String password, String confirm);
  Future<CustomerProfile> profile();
  Future<CustomerProfile> updateProfile(Map<String, Object?> values);
  Future<CustomerProfile> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  });
  Future<void> changePassword(String current, String password, String confirm);
}

class AuthService implements AuthRepository {
  AuthService(this.client, this.storage) {
    client.configureAuth(
      accessToken: () async => (await storage.load())?.accessToken,
      refresh: refreshSession,
      sessionInvalid: _sessionInvalid,
    );
  }
  final ApiClient client;
  final SessionStorage storage;
  Future<void> Function()? sessionInvalidHandler;

  Future<void> _sessionInvalid() async {
    await storage.clear();
    await sessionInvalidHandler?.call();
  }

  @override
  Future<PendingVerification> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool termsAccepted,
  }) async => PendingVerification.fromJson(
    _data(
      await client.post(
        'auth/register',
        body: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'confirmPassword': confirmPassword,
          'termsAccepted': termsAccepted,
        },
      ),
    ),
  );
  @override
  Future<AuthSession> verifyRegistration(String email, String otp) =>
      _auth('auth/verify-registration', {'email': email, 'otp': otp});
  @override
  Future<PendingVerification> resendRegistration(String email) async =>
      PendingVerification.fromJson(
        _data(
          await client.post(
            'auth/resend-registration-otp',
            body: {'email': email},
          ),
        ),
      );
  @override
  Future<AuthSession> login(String email, String password) =>
      _auth('auth/login', {'email': email, 'password': password});
  Future<AuthSession> _auth(String path, Map<String, Object?> body) async {
    final s = AuthSession.fromJson(_data(await client.post(path, body: body)));
    await storage.save(s);
    return s;
  }

  @override
  Future<bool> refreshSession() async {
    final old = await storage.load();
    if (old == null ||
        old.refreshTokenExpiresAt.isBefore(DateTime.now().toUtc())) {
      await storage.clear();
      return false;
    }
    try {
      final next = AuthSession.fromJson(
        _data(
          await client.post(
            'auth/refresh',
            body: {'refreshToken': old.refreshToken},
          ),
        ),
      );
      await storage.save(next);
      return true;
    } catch (_) {
      await storage.clear();
      return false;
    }
  }

  @override
  Future<void> logout() async {
    final s = await storage.load();
    try {
      if (s != null) {
        await client.post(
          'auth/logout',
          authenticated: true,
          body: {'refreshToken': s.refreshToken},
        );
      }
    } finally {
      await storage.clear();
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    await client.post('auth/forgot-password', body: {'email': email});
  }

  @override
  Future<ResetAuthorization> verifyResetOtp(String email, String otp) async =>
      ResetAuthorization.fromJson(
        _data(
          await client.post(
            'auth/verify-password-reset-otp',
            body: {'email': email, 'otp': otp},
          ),
        ),
      );
  @override
  Future<void> resetPassword(
    String token,
    String password,
    String confirm,
  ) async {
    await client.post(
      'auth/reset-password',
      body: {
        'resetToken': token,
        'newPassword': password,
        'confirmPassword': confirm,
      },
    );
  }

  @override
  Future<CustomerProfile> profile() async => CustomerProfile.fromJson(
    _data(await client.get('auth/me', authenticated: true)),
  );
  @override
  Future<CustomerProfile> updateProfile(Map<String, Object?> values) async =>
      CustomerProfile.fromJson(
        _data(await client.put('auth/me', authenticated: true, body: values)),
      );
  @override
  Future<CustomerProfile> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) async => CustomerProfile.fromJson(
    _data(
      await client.postMultipartFile(
        'profile/photo',
        fieldName: 'photo',
        bytes: bytes,
        filename: filename,
        authenticated: true,
      ),
    ),
  );

  @override
  Future<void> changePassword(
    String current,
    String password,
    String confirm,
  ) async {
    try {
      await client.post(
        'auth/change-password',
        authenticated: true,
        body: {
          'currentPassword': current,
          'newPassword': password,
          'confirmPassword': confirm,
        },
      );
    } finally {
      await storage.clear();
    }
  }

  Map<String, Object?> _data(Object? value) {
    if (value is! Map<String, Object?> ||
        value['success'] != true ||
        value['data'] is! Map<String, Object?>) {
      throw const FormatException('Malformed authentication response');
    }
    return value['data'] as Map<String, Object?>;
  }
}

String authMessage(Object error) => userSafeApiMessage(error);
