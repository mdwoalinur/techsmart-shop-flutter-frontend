# TechSmart Shop

Flutter customer storefront for the TechSmart Shop / TradeMaster IMS project.

## Current verified scope

Phases 1 through 9 are complete, and Phase 9.1 adds Bangladesh Mobile Wallet Payment Simulation.

Payment options now include:

- Mobile Wallet: backend-driven presentation simulation for bKash, Nagad, Rocket, Upay, SureCash, and Tap.
- Online Payment: local development gateway simulation.
- Bank Transfer: manual reference submission for admin review.
- Mobile Transfer: manual mobile financial service reference submission for admin review.
- Cash on Delivery: backend COD selection without marking the order paid.

## Mobile wallet simulation safety

The mobile wallet flow is presentation-only. It does not call real wallet APIs, use official wallet logos, collect real wallet credentials, or let the client choose amount/success. The backend derives amount and result, masks wallet numbers, and posts accounting only after backend-confirmed success.

Local test credentials:

- Verification code: `123456`
- Payment PIN: `12345`

Backend environment switches:

- `TECHSMART_MOBILE_WALLET_SIMULATION=true`
- `TECHSMART_MOBILE_WALLET_RESULT=SUCCESS|PENDING|FAILED|CANCELLED`

## Validation

Run from `E:\Dart_flutter\flutter_project\tech_smart_shop`:

```bash
dart format .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```
