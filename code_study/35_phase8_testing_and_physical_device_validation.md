# Phase 8 - Testing and Physical Device Validation

Baseline before the Phase 8 continuation was verified as backend 56/56 tests, Flutter 80/80 tests, and Flutter analyze clean.

Phase 8 backend coverage remains 56 tests. It covers order ownership, employee/anonymous denial, detail DTO safety, timeline, cancellation request payload safety, return foundation status, idempotency, and truthful document content. The continuation did not add backend production endpoints or Phase 9 side effects.

Phase 8 Flutter coverage now totals 85 tests. New continuation tests cover multi-item return draft serialization, selected-item omission, per-item quantity/reason/reason text, preferred resolution, overall comment, idempotency key, provider selection/deselection/clamping/validation, `OTHER` explanation validation, no-selection validation, duplicate submit blocking, failure draft preservation, success draft clearing, logout draft clearing, one backend request containing two selected items, review/confirmation UI, and phone-width no-overflow behavior.

Final automated verification on 2026-07-07:

- Backend: `./mvnw.cmd test` -> 56 tests, 0 failures, build success.
- Flutter: `flutter pub get` -> success; dependency updates available but outside current constraints.
- Flutter: `dart format .` -> 83 files checked, 0 changed.
- Flutter: `flutter analyze` -> no issues.
- Flutter: `flutter test --reporter expanded` -> 85 tests passed.
- Flutter: `flutter build apk --debug` -> success, `build\app\outputs\flutter-apk\app-debug.apk`, 185,882,582 bytes.

Physical Samsung setup on SM A556E `R5CX32F8CJB` was partially verified:

- ADB daemon restarted successfully.
- `adb devices -l` listed `R5CX32F8CJB device product:a55xnsxx model:SM_A556E`.
- Local backend health returned HTTP 200 for `http://localhost:8080/api/mobile/v1/health`.
- `adb reverse tcp:8080 tcp:8080` was configured and listed as `UsbFfs tcp:8080 tcp:8080`.
- `flutter run -d R5CX32F8CJB --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1` built, installed, launched on the Samsung, and public categories/products API calls returned 200.

Authenticated Customer A/B physical validation remains incomplete because no safe user-provided test credentials were available in this thread and no existing local Customer A/B fixture was documented. No real passwords, OTPs, access tokens, refresh tokens, or credentials were requested, printed, hardcoded, or committed. No test-only backend fixture/profile was added during this continuation.

Therefore the following interactive physical checklist items still require safe test credentials or an explicit local test fixture: Customer A My Orders/detail/timeline/cancellation/document, delivered-order multi-item return submission, restart/reload return persistence, Customer B isolation, manual forbidden-access checks, authenticated failure/retry checks, and full authenticated runtime-log review.

Runtime log review for the limited unauthenticated launch found no fatal exception, RenderFlex overflow, repeated 401/403 loop, token/password/OTP/idempotency-key logging, buying-price logging, or exact-stock logging. The log contained only normal Android/Flutter rendering messages plus public catalog requests.
## 2026-07-07 physical customer authorization 403 repair

Root cause: `CustomerAuthTokenFilter` was scoped only to `/api/mobile/v1/auth/**`, so valid customer JWTs were not converted into `CustomerAuthentication` for protected customer routes such as cart, wishlist, checkout, addresses, and orders. The employee filter then coexisted with an anonymous/unauthorized context, producing 403 responses even though the Flutter UI had a restored customer session.

The backend now runs the customer JWT filter for `/api/mobile/v1/**`, grants `ROLE_CUSTOMER` from valid customer tokens before authorization, leaves employee tokens to the employee filter, keeps public mobile catalog/health open, and returns 401 for missing/expired/invalid authentication versus 403 for authenticated non-customer principals. JWT signing remains configuration-backed through `TRADEMASTER_JWT_SECRET`; no runtime-generated startup secret or real secret logging was added.

Verification after the repair:

- Backend: `./mvnw.cmd test` -> 61 tests, 0 failures.
- Backend: `./mvnw.cmd package` -> build success and repackaged jar built.
- Backend health: `http://127.0.0.1:8080/api/mobile/v1/health` -> HTTP 200 on the active local backend.
- Flutter: `flutter pub get` -> success.
- Flutter: `dart format .` -> clean after one test expectation update.
- Flutter: `flutter analyze` -> no issues.
- Flutter: `flutter test --reporter expanded` -> 90 tests passed.
- Flutter: `flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1` -> success.
- Samsung SM A556E `R5CX32F8CJB`: ADB connected, reverse `tcp:8080 tcp:8080` configured, debug APK installed, and app launched. Existing customer session refresh returned 200, `/auth/me` returned 200, `/wishlist` returned 200, and `/cart` returned 200. The device was on the Samsung lock screen during further manual navigation, so Checkout/My Orders/order-detail taps were not completed in this pass. The sampled runtime log showed no raw `ApiException(...)`, no token values, and no repeated 401/403 loop.
- Backend startup: packaged jar also started on alternate port 18080 and initialized Tomcat/JPA/MySQL successfully; the verification process was stopped afterward without disturbing the existing 8080 backend.
