import 'package:flutter/foundation.dart';
import '../model/auth/auth_models.dart';
import '../model/customer/customer_profile.dart';
import '../service/auth/auth_service.dart';
import '../service/storage/secure_session_storage.dart';

enum AuthState {
  initializing,
  guest,
  pendingRegistrationVerification,
  authenticated,
  loading,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.repository, this.storage, {bool autoInitialize = true}) {
    if (autoInitialize) initialize();
  }
  final AuthRepository repository;
  final SessionStorage storage;
  AuthState state = AuthState.initializing;
  CustomerProfile? profile;
  String? pendingEmail;
  String? error;
  ResetAuthorization? _reset;
  bool _busy = false;
  int _generation = 0;
  bool get authenticated => state == AuthState.authenticated && profile != null;
  bool get busy => _busy;
  String? get resetToken => _reset?.token;
  Future<void> initialize() async {
    final g = ++_generation;
    state = AuthState.initializing;
    notifyListeners();
    try {
      final s = await storage.load();
      if (s == null) {
        if (g == _generation) _guest();
        return;
      }
      if (s.accessTokenExpiresAt.isBefore(DateTime.now().toUtc()) &&
          !await repository.refreshSession()) {
        await storage.clear();
        if (g == _generation) _guest();
        return;
      }
      final p = await repository.profile();
      if (g == _generation) {
        profile = p;
        state = AuthState.authenticated;
        error = null;
        notifyListeners();
      }
    } catch (_) {
      await storage.clear();
      if (g == _generation) _guest();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool terms,
  }) => _run(() async {
    await repository.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
      termsAccepted: terms,
    );
    pendingEmail = email.trim().toLowerCase();
    state = AuthState.pendingRegistrationVerification;
  });
  Future<bool> verifyRegistration(String otp) => _run(() async {
    final email = pendingEmail;
    if (email == null) throw StateError('Registration session expired');
    final s = await repository.verifyRegistration(email, otp);
    profile = s.profile ?? await repository.profile();
    pendingEmail = null;
    state = AuthState.authenticated;
  });
  Future<bool> resendRegistration() => _run(() async {
    if (pendingEmail == null) throw StateError('Registration session expired');
    await repository.resendRegistration(pendingEmail!);
    state = AuthState.pendingRegistrationVerification;
  });
  Future<bool> login(String email, String password) => _run(() async {
    final s = await repository.login(email.trim().toLowerCase(), password);
    profile = s.profile ?? await repository.profile();
    state = AuthState.authenticated;
  });
  Future<void> expireSession() async {
    ++_generation;
    await storage.clear();
    profile = null;
    pendingEmail = null;
    _reset = null;
    state = AuthState.guest;
    error = 'Your session has expired. Please sign in again.';
    notifyListeners();
  }

  Future<void> logout() async {
    ++_generation;
    try {
      await repository.logout();
    } finally {
      profile = null;
      pendingEmail = null;
      _reset = null;
      _guest();
    }
  }

  Future<bool> forgotPassword(String email) => _run(() async {
    await repository.forgotPassword(email.trim().toLowerCase());
    pendingEmail = email.trim().toLowerCase();
    state = AuthState.guest;
  });
  Future<bool> verifyResetOtp(String otp) => _run(() async {
    if (pendingEmail == null) {
      throw StateError('Password reset session expired');
    }
    _reset = await repository.verifyResetOtp(pendingEmail!, otp);
    state = AuthState.guest;
  });
  Future<bool> resetPassword(String password, String confirm) => _run(() async {
    final token = _reset?.token;
    if (token == null) throw StateError('Password reset authorization expired');
    try {
      await repository.resetPassword(token, password, confirm);
    } finally {
      _reset = null;
      pendingEmail = null;
    }
    state = AuthState.guest;
  });
  Future<bool> loadProfile() => _run(() async {
    profile = await repository.profile();
    state = AuthState.authenticated;
  });
  Future<bool> updateProfile(Map<String, Object?> values) => _run(() async {
    profile = await repository.updateProfile(values);
    state = AuthState.authenticated;
  });
  Future<bool> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) => _run(() async {
    profile = await repository.uploadProfilePhoto(
      bytes: bytes,
      filename: filename,
    );
    state = AuthState.authenticated;
  });
  Future<bool> changePassword(
    String current,
    String password,
    String confirm,
  ) => _run(() async {
    await repository.changePassword(current, password, confirm);
    profile = null;
    state = AuthState.guest;
  });
  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    _busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      error = authMessage(e);
      if (state == AuthState.loading) state = AuthState.error;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void _guest() {
    profile = null;
    state = AuthState.guest;
    error = null;
    notifyListeners();
  }
}
