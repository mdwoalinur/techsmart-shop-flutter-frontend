# 44. Phase 9.1 Testing and Physical Validation

Phase 9.1 adds backend and Flutter coverage for the Bangladesh mobile wallet simulation.

## Backend tests

`MobileWalletPaymentServiceTest` verifies:

- Wallet initiation derives amount from the server order.
- Successful confirmation marks payment paid and posts accounting once.
- Invalid simulated credentials do not post or mark the payment paid.

The full backend suite was expanded from 69 to 72 tests.

## Flutter tests

`phase9_1_mobile_wallet_test.dart` verifies:

- Wallet provider and session models parse safe backend DTOs.
- Service request bodies omit client amount and success flags.
- Provider state becomes paid only after backend confirmation.
- Invalid wallet number validation blocks credential submission.
- The payment screen shows the simulation disclosure and all six wallet providers.

The full Flutter suite was expanded from 99 to 104 tests.

## Validation checklist

Required validation for this phase:

- `dart format .`
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `./mvnw.cmd clean test`
- `./mvnw.cmd clean package`
- backend startup and health check
- mobile wallet provider catalog smoke test
- APK build
- Samsung physical-device run with `adb reverse tcp:8080 tcp:8080`

Physical-device validation should confirm the Mobile Wallet method appears, the six providers render, the simulation notice is visible, and a successful simulated confirmation updates payment state only after backend verification.
