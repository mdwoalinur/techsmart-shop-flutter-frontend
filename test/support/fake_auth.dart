import 'package:tech_smart_shop/model/auth/auth_models.dart';
import 'package:tech_smart_shop/model/customer/customer_profile.dart';
import 'package:tech_smart_shop/service/auth/auth_service.dart';
import 'package:tech_smart_shop/service/storage/secure_session_storage.dart';

final testProfile = CustomerProfile(
  customerId: 7,
  customerCode: 'CUST-7',
  fullName: 'Test Customer',
  email: 'test@example.com',
  phone: '01712345678',
  customerType: 'RETAIL',
  emailVerified: true,
);
AuthSession testSession({CustomerProfile? profile}) => AuthSession(
  accessToken: 'access-secret',
  refreshToken: 'refresh-secret',
  accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
  refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 10)),
  profile: profile,
);

class MemorySessionStorage implements SessionStorage {
  AuthSession? value;
  bool corrupt = false;
  final Map<String, String> written = {};
  @override
  Future<void> save(AuthSession s) async {
    value = s;
    written['access'] = s.accessToken;
    written['refresh'] = s.refreshToken;
    written['accessExpiry'] = s.accessTokenExpiresAt.toIso8601String();
    written['refreshExpiry'] = s.refreshTokenExpiresAt.toIso8601String();
  }

  @override
  Future<AuthSession?> load() async {
    if (corrupt) {
      await clear();
      return null;
    }
    return value;
  }

  @override
  Future<void> clear() async {
    value = null;
    written.clear();
  }
}

class FakeAuthRepository implements AuthRepository {
  bool fail = false;
  int loginCalls = 0, refreshCalls = 0, logoutCalls = 0;
  CustomerProfile current = testProfile;
  Future<T> _result<T>(T value) async {
    if (fail) throw Exception('failed');
    return value;
  }

  @override
  Future<AuthSession> login(String email, String password) {
    loginCalls++;
    return _result(testSession(profile: current));
  }

  @override
  Future<AuthSession> verifyRegistration(String email, String otp) =>
      _result(testSession(profile: current));
  @override
  Future<PendingVerification> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool termsAccepted,
  }) => _result(
    const PendingVerification(
      maskedEmail: 't***@example.com',
      otpExpiresInSeconds: 600,
      resendAvailableInSeconds: 45,
    ),
  );
  @override
  Future<PendingVerification> resendRegistration(String email) => _result(
    const PendingVerification(
      maskedEmail: 't***@example.com',
      otpExpiresInSeconds: 600,
      resendAvailableInSeconds: 45,
    ),
  );
  @override
  Future<bool> refreshSession() async {
    refreshCalls++;
    return !fail;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  Future<void> forgotPassword(String email) => _result(null);
  @override
  Future<ResetAuthorization> verifyResetOtp(String email, String otp) =>
      _result(
        ResetAuthorization(
          'reset-secret',
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      );
  @override
  Future<void> resetPassword(String token, String password, String confirm) =>
      _result(null);
  @override
  Future<CustomerProfile> profile() => _result(current);
  @override
  Future<CustomerProfile> updateProfile(Map<String, Object?> values) {
    current = current.copyWith(
      fullName: values['fullName'] as String,
      phone: values['phone'] as String,
    );
    return _result(current);
  }

  @override
  Future<CustomerProfile> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) {
    current = current.copyWith(
      photoUrl: '/uploads/customers/profile/7/$filename',
    );
    return _result(current);
  }

  @override
  Future<void> changePassword(
    String current,
    String password,
    String confirm,
  ) => _result(null);
}
