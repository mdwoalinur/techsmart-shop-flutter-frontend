class AuthValidation {
  static const passwordPolicy =
      '8-72 characters with uppercase, lowercase, number, and special character.';
  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? v) {
    final s = v ?? '';
    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,72}$',
    ).hasMatch(s)) {
      return 'Use $passwordPolicy';
    }
    return null;
  }

  static String? otp(String? v) =>
      RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'Enter the six-digit code.';
  static String? phone(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'[\s()-]'), '');
    return RegExp(r'^(?:\+8801|01)[3-9]\d{8}$').hasMatch(s)
        ? null
        : 'Enter a valid Bangladesh phone number.';
  }
}
