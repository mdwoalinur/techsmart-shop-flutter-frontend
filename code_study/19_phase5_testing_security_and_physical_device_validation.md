# 19. Phase 5 Testing, Security, and Physical Device Validation

## Automated verification

Backend baseline was 17 passing tests. Phase 5 adds isolated Mockito service tests, MockMvc authorization tests, and JWT claim tests for registration safety, BCrypt/OTP hashing, activation, generic credentials, lockout, rotation, reuse revocation, enumeration-safe recovery, safe profile, session revocation, endpoint boundaries, employee separation, and JWT audience/expiry. Mail and repositories are mocked; tests do not use production MySQL.

Flutter baseline was 43 tests. New tests cover parsing/redaction, corrupt storage, guest/restored/refresh-failed provider states, complete provider flow, duplicate submission, all endpoint paths, bearer attachment, one retry, simultaneous-refresh coordination, guest/authenticated Menu, validations, OTP length, safe Profile, logout, and Phase 4 state visibility. HTTP and storage are fake.

## Commands and current environment

Final commands are run directly from the new paths: cached Maven compile/test, `dart format .`, `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --debug`. Final package resolution succeeds. Flutter analysis reports no issues, all 63 tests pass, and the debug APK builds at `build\app\outputs\flutter-apk\app-debug.apk` (185,882,582 bytes; 2026-07-02 09:53:31 +06:00). Backend clean compile/package succeed and all 38 tests pass after adding an empty-registration validation regression test. Local startup succeeds; health/catalog return 200, invalid registration/login return 400, and unauthenticated profile/unsupported DELETE return 403. Hibernate update starts without DDL error; no destructive SQL was run.

Physical validation is mandatory on Samsung SM A556E `R5CX32F8CJB`: restart ADB, detect authorized device, start backend, verify health, add `adb reverse tcp:8080 tcp:8080`, and run with `API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1`. Guest, registration/email OTP, login, restoration, profile/edit, recovery, change-password, logout, security boundary, logs, overflow, and Phase 4 regression must be verified without recording secrets. Reverse and services must be cleaned afterward. No physical success is documented until those steps pass.

Phase 6 cart synchronization, checkout, orders, addresses, payments, and persistent Wishlist remain intentionally deferred.

## Final environment result

Local SMTP credentials are not configured, so live email delivery was not attempted; mocked mail tests and failure handling remain the evidence. ADB was killed/restarted twice during continuation. The daemon started, but Samsung R5CX32F8CJB did not produce a device entry and Flutter listed no Samsung target. Therefore reverse, physical run, registration/OTP, login, restoration, profile, recovery, change-password, logout, runtime-log, overflow, and physical Phase 4 regression flows remain unverified. The user must connect/unlock the Samsung, enable USB debugging, select File Transfer, approve RSA authorization, and ensure the Samsung USB driver/data cable works.


## 2026-07-07 auth status-code correction

The current customer-auth security contract supersedes the earlier Phase 5 note that anonymous protected profile/DELETE requests returned 403. Missing, expired, or invalid authentication is now 401. A real authenticated principal without `ROLE_CUSTOMER` remains 403. This distinction is required because Flutter refreshes access tokens on 401 only and must not refresh a legitimate authorization-denied 403.

Additional Flutter auth tests now cover safe 403 messaging without refresh, replacement access-token storage after refresh, refresh-failure session invalidation, raw exception suppression, and false-authenticated-state clearing. The full Flutter suite passed with 90 tests after this correction.
