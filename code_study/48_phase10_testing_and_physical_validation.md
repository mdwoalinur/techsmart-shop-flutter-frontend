# 48. Phase 10 Testing and Physical Validation

## Baseline

Before Phase 10 edits:

- Backend `mvnw test`: 72 tests passed.
- Flutter `flutter pub get`: succeeded.
- Flutter `flutter analyze`: no issues.
- Flutter `flutter test`: 104 tests passed.

## Automated tests added

Backend:

- `CustomerNotificationSecurityTest`
- `CustomerNotificationServiceTest`

Coverage includes anonymous/employee denial, customer principal scoping, list/detail/unread/read-all/preferences route shape, notification creation, duplicate event-key prevention, and email-disabled fallback.

Flutter:

- `phase10_notification_test.dart`

Coverage includes model parsing, unknown enum fallback, provider unread/list/load-more/mark-all/logout isolation, bell badge `99+`, and guest-safe notification UI behavior.

## Final validation results

Backend:

- `./mvnw.cmd clean test`: Surefire reports updated with 80 tests, 0 failures, 0 errors, 0 skipped. One tool invocation timed out after reports were produced, so the suite was refreshed and completed normally with `BUILD SUCCESS` and `Tests run: 80, Failures: 0, Errors: 0, Skipped: 0`.
- `./mvnw.cmd clean package`: `BUILD SUCCESS`; included the full 80-test suite with 0 failures, 0 errors, 0 skipped, and produced `target/trademaster_ims-0.0.1-SNAPSHOT.jar`.

Flutter:

- `dart format .`: formatted 97 files, 0 changed.
- `flutter pub get`: succeeded.
- `flutter analyze`: no issues found.
- `flutter test`: all 107 tests passed.
- `flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1`: succeeded.
- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`, 185,882,582 bytes, last written July 9, 2026 12:09:23 AM local time.

Live backend smoke:

- `GET /api/mobile/v1/health`: 200, service status UP.
- Anonymous `GET /api/mobile/v1/notifications`: 401 Unauthorized.
- Authenticated customer account 1, local short-lived JWT smoke:
  - `GET /api/mobile/v1/notifications/unread-count`: 200, `unreadCount: 0`.
  - `GET /api/mobile/v1/notifications?page=0&size=10`: 200, empty page.
  - `GET /api/mobile/v1/notifications/preferences`: 200, category preferences returned.

Physical Samsung validation:

- Device: Samsung SM-A556E, serial `R5CX32F8CJB`.
- `adb devices -l`: device connected.
- `adb reverse --remove-all`, `adb reverse tcp:8080 tcp:8080`, `adb reverse --list`: `UsbFfs tcp:8080 tcp:8080` active.
- `flutter run -d R5CX32F8CJB --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1`: app launched on device; the tool attachment timed out after launch, but the Android process `com.example.tech_smart_shop` was running.
- Home screen loaded live catalog data and displayed the notification bell.
- Notification center opened from the bell and rendered filters plus an empty-state list without 401/403 or crash.
- Notification preferences screen rendered account, cancellation, order, payment, return, and system channel toggles; the account in-app switch remained enabled/locked for safety.

## Remaining limitations

Real push notifications, SMS, WhatsApp, marketing campaigns, and production email credential changes remain out of scope for Phase 10. Email is a safe foundation only and sends only when the existing environment configuration enables it.

Phase 11 fulfillment workflow was not started.