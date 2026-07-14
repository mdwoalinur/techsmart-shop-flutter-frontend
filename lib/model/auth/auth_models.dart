import '../customer/customer_profile.dart';

class PendingVerification {
  const PendingVerification({
    required this.maskedEmail,
    required this.otpExpiresInSeconds,
    required this.resendAvailableInSeconds,
  });
  final String maskedEmail;
  final int otpExpiresInSeconds, resendAvailableInSeconds;
  factory PendingVerification.fromJson(Map<String, Object?> j) =>
      PendingVerification(
        maskedEmail: _s(j, 'maskedEmail'),
        otpExpiresInSeconds: _i(j, 'otpExpiresInSeconds'),
        resendAvailableInSeconds: _i(j, 'resendAvailableInSeconds'),
      );
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
    this.profile,
  });
  final String accessToken, refreshToken;
  final DateTime accessTokenExpiresAt, refreshTokenExpiresAt;
  final CustomerProfile? profile;
  factory AuthSession.fromJson(Map<String, Object?> j) => AuthSession(
    accessToken: _s(j, 'accessToken'),
    refreshToken: _s(j, 'refreshToken'),
    accessTokenExpiresAt: DateTime.parse(_s(j, 'accessTokenExpiresAt')).toUtc(),
    refreshTokenExpiresAt: DateTime.parse(
      _s(j, 'refreshTokenExpiresAt'),
    ).toUtc(),
    profile: j['profile'] is Map<String, Object?>
        ? CustomerProfile.fromJson(j['profile'] as Map<String, Object?>)
        : null,
  );
  @override
  String toString() =>
      'AuthSession(tokens: [REDACTED], profile: ${profile?.email})';
}

class ResetAuthorization {
  const ResetAuthorization(this.token, this.expiresAt);
  final String token;
  final DateTime expiresAt;
  factory ResetAuthorization.fromJson(Map<String, Object?> j) =>
      ResetAuthorization(
        _s(j, 'resetToken'),
        DateTime.parse(_s(j, 'expiresAt')).toUtc(),
      );
  @override
  String toString() => 'ResetAuthorization([REDACTED])';
}

String _s(Map<String, Object?> j, String k) {
  final v = j[k];
  if (v is! String || v.isEmpty) throw FormatException('Missing $k');
  return v;
}

int _i(Map<String, Object?> j, String k) {
  final v = j[k];
  if (v is! num) throw FormatException('Missing $k');
  return v.toInt();
}
