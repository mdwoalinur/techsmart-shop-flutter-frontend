# 17. Flutter Auth Models, Services, and Secure Storage

## Models and API

Null-safe auth models parse pending verification, access/refresh sessions, one-time reset authorization, and customer-safe profiles. Missing required fields throw FormatException. Sensitive model `toString` output is redacted. AuthService maps all twelve `/auth` endpoints and uses the existing mobile envelope.

ApiClient accepts optional authenticated calls. It reads the current access token, attaches Bearer only to protected requests, performs one shared refresh when simultaneous requests receive 401, retries each request once, clears invalid sessions after failure, and never logs headers or payloads. Public catalog behavior is unchanged.

## Secure storage

`flutter_secure_storage` 10.3.1 is the only direct Phase 5 package addition. It requires Dart 3.3 or newer; this project uses Dart 3.11.5. SecureSessionStorage is injectable and stores only access token, refresh token, and their expiry timestamps. It never stores passwords, OTPs, reset authorization, SMTP data, payment data, or the full profile. Corrupt/partial sessions are cleared safely.

Android application backup is disabled to prevent encrypted values from being restored without their Android Keystore keys. Package 10 uses RSA-OAEP and AES-GCM defaults on Android and requires API 23. Tests use MemorySessionStorage and no platform channel.

Windows symlink support is now available: final `flutter pub get` and the Android debug build both succeeded. No insecure storage fallback is used. iOS Runner now declares the required empty `keychain-access-groups` entitlement for Debug, Profile, and Release configurations.


## 2026-07-07 customer authorization 403 fix

ApiClient now normalizes auth failures before they reach production UI. Protected requests still attach `Authorization: Bearer <access-token>` only when `authenticated: true`; public catalog calls remain token-free. A 401 triggers the existing single shared refresh coordinator and retries the original request once. A legitimate 403 does not trigger refresh, preventing a refresh loop for role/permission denial.

AuthService exposes a session-invalid callback used when refresh fails. The callback clears secure storage and allows the app-level AuthProvider to leave authenticated state immediately. The safe UI messages are now centralized: 401 uses `Your session has expired. Please sign in again.`, 403 uses `You do not have permission to perform this action.`, and network failures use `Unable to connect to the server. Please try again.` Raw `ApiException(...)` strings are not intended for Cart, Wishlist, Checkout, Orders, addresses, or order detail UI.
