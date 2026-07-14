# 41 - Phase 9 Testing and Physical Device Validation

This document records Phase 9 validation for the hybrid customer payment workflow.

## Automated tests

Baseline before Phase 9:

- Backend: 61 tests passed.
- Flutter: 90 tests passed.
- Flutter analyze: no issues.

After Phase 9 implementation:

- Backend `./mvnw.cmd clean test`: 69 tests passed, 0 failed.
- Backend `./mvnw.cmd clean package`: 69 tests passed, package built successfully.
- Flutter `flutter test --reporter expanded`: 99 tests passed, 0 failed.
- Flutter `flutter analyze`: no issues.
- Flutter `flutter pub get`: completed successfully.

Phase 9 added backend service tests for method eligibility, online initiation, idempotent attempt reuse, webhook success with exactly-once posting, manual review-required state, COD pending/no posting, cancellation of pending attempts, and customer ownership isolation.

Phase 9 added Flutter tests for model parsing, safe initiation request body, provider paid-only-from-backend behavior, manual review state, COD pending state, pending cancellation, logout isolation, and payment screen rendering of backend amount/ineligible methods.

## Build verification

Backend packaged successfully as:

`E:\Dart_flutter\flutter_project\trademaster_ims\target\trademaster_ims-0.0.1-SNAPSHOT.jar`

Flutter debug APK built successfully with:

`flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1`

APK artifact:

- Path: `E:\Dart_flutter\flutter_project\tech_smart_shop\build\app\outputs\flutter-apk\app-debug.apk`
- Size: 147,507,608 bytes
- Timestamp: 2026-07-07 23:07:20

## Packaged backend startup and schema verification

The packaged backend was started on `127.0.0.1:8080` and health returned `UP`.

A packaged-start issue was found and fixed during physical verification: the local test gateway now owns its `ObjectMapper` instead of requiring a missing Spring bean.

A MySQL enum compatibility issue was also found and fixed: `CustomerOrderSchemaFixer` verifies `customer_orders.order_status`, `customer_orders.payment_status`, and `customer_orders.accounting_status` at startup. Startup logs confirmed these columns support the Phase 9 values, including `PENDING_GATEWAY`, `PAID`, `COD_PENDING`, and `POSTED`.

## Samsung physical verification

Target device:

- Samsung SM A556E
- Device ID: `R5CX32F8CJB`

ADB verification:

- `adb devices -l` listed `R5CX32F8CJB device product:a55xnsxx model:SM_A556E`.
- `adb reverse --remove-all` completed.
- `adb reverse tcp:8080 tcp:8080` returned `8080`.
- `adb reverse --list` showed `UsbFfs tcp:8080 tcp:8080`.

Flutter physical run:

`flutter run -d R5CX32F8CJB --no-resident --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1`

The app installed and launched. Runtime logs showed public categories/products requests returning 200, customer session refresh returning 200, `/auth/me` returning 200, cart/wishlist returning 200, orders returning 200, order detail returning 200, payment methods returning 200, and payment status returning 200.

Physical payment UI verification on order `TSS-20260707-BF17019F`:

- Payment section appeared in Order Detail.
- Payment screen loaded all backend methods: Online Gateway, Bank Transfer, Mobile Financial Service, and Cash on Delivery.
- Amount displayed as backend-calculated and not editable.
- Initial payment status was `NOT_STARTED` with accounting `UNPOSTED`.
- Online initiation returned 201.
- App moved to `PENDING_GATEWAY` and `UNPOSTED`, showing that Flutter did not claim success locally.
- A signed local-test backend webhook moved payment to `PAID`, order to `CONFIRMED`, and accounting to `POSTED`.
- Duplicate webhook event returned `DUPLICATE` and did not create a second success transition.
- After explicit status refresh, the Samsung UI showed `Payment status: PAID`, `Accounting: POSTED`, and `Paid after backend verification`.

Runtime log review found no app fatal exception, no RenderFlex overflow, no raw card data, no gateway secret logging, no password/OTP logging, and no repeated auth failure loop. Some Android system/Google service warnings appeared outside the TechSmart Shop app process and were not app failures.

## Limitations

- Manual proof upload is deferred to a future safe private-upload implementation.
- The local/test gateway is a development adapter, not a production gateway.
- Manual-payment and COD screens were physically visible and backed by automated tests; the completed physical paid order could not also be used to submit manual/COD states without creating another order.
- Production deployment requires explicit migrations and real provider credentials supplied through secure configuration.
- Phase 10 notifications were not started.
