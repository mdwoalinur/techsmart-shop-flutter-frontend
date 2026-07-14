# 52 - Phase 11 testing and physical validation

Phase 11 validation covers backend lifecycle rules, Flutter tracking behavior, builds, and physical-device readiness.

## Automated backend validation

Backend tests include service-level fulfillment coverage and security coverage.

Covered cases include:

- paid and posted confirmed orders can start fulfillment;
- unpaid non-COD orders cannot start;
- packing deducts stock exactly once;
- duplicate packing does not double-deduct;
- insufficient stock blocks packing;
- customer tracking filters internal events;
- COD exact collection posts and delivers;
- COD mismatch blocks delivery;
- anonymous/customer tokens are denied on admin fulfillment APIs;
- customer tracking requires the customer principal.

Commands verified from `E:\Dart_flutter\flutter_project\trademaster_ims`:

```cmd
.\mvnw.cmd clean test
.\mvnw.cmd clean package
```

Result: 93 backend tests passed, 0 failures/errors, package build succeeded.

## Automated Flutter validation

Commands verified from `E:\Dart_flutter\flutter_project\tech_smart_shop`:

```cmd
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1
```

Result: analyze found no issues, 111 Flutter tests passed, and the debug APK was built at `build\app\outputs\flutter-apk\app-debug.apk`.

## Physical-device validation notes

The debug APK was built with the same `127.0.0.1` mobile API base used with ADB reverse for Samsung-device testing.

Verified on 2026-07-09:

- `adb devices` detected Samsung SM A556E `R5CX32F8CJB`.
- `adb reverse --remove-all` completed.
- `adb reverse tcp:8080 tcp:8080` returned `8080`.
- `adb reverse --list` showed `UsbFfs tcp:8080 tcp:8080`.
- The debug APK installed on the device.
- The app launched as package `com.example.tech_smart_shop`.
- The app process was running and a UI hierarchy dump showed the TechSmart Shop home/catalog UI with live product data.

Phase 11's authenticated customer tracking UI is covered by unit/widget tests and the API is ownership scoped. Full manual Customer A/B fulfillment walkthrough still depends on safe local customer/admin credentials and suitable confirmed test orders in the local database; no SQL reset/import/drop/truncate was used for this phase.
## Completed continuation validation

Continuation validation on 2026-07-09 completed the previous blocker with disposable local fixture data.

- Backend/API smoke passed for prepaid fulfillment, COD fulfillment, stock exactly-once checks, COD wrong-amount rejection, exact COD reconciliation/posting, and Customer B ownership denial.
- Samsung physical validation passed for app launch, fixture catalog data, Customer A login, order list/detail/tracking, notification detail `View Order` action navigation to order tracking, mark-read/unread-count decrease, COD delivered/paid/reconciled tracking refresh, logout, Customer B login, and Customer B isolation.
- Runtime log scan found no fatal exception, RenderFlex overflow, raw ApiException loop, repeated 401/403 loop, token/password/OTP/PIN logging, or SQL stack traces.

The local fixture tool is documented in `53_local_phase11_fixtures_and_safe_demo_data.md` and remains disabled by default unless `techsmart.dev-fixtures.enabled=true` is explicitly provided for local validation.