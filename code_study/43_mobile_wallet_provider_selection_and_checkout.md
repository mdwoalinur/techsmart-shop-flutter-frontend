# 43. Mobile Wallet Provider Selection and Checkout

The Flutter app treats Mobile Wallet as its own payment method while preserving Phase 9 Online Payment, Bank Transfer, Mobile Transfer, and Cash on Delivery behavior.

## User flow

1. Customer opens payment for an unpaid order.
2. Backend payment methods include `Mobile Wallet` when available.
3. Selecting Mobile Wallet exposes a `Choose Mobile Wallet` panel.
4. The app loads provider cards from the backend for bKash, Nagad, Rocket, Upay, SureCash, and Tap.
5. The customer selects a provider and starts a backend wallet session.
6. The checkout panel shows a presentation-only notice and fixed test credentials:
   - Verification code: `123456`
   - Payment PIN: `12345`
7. The app sends wallet number, code, and PIN to the backend confirmation endpoint.
8. The app marks the order paid only when the backend status result returns `PAID`.

## Safety rules

- The Flutter request body never sends amount or a success flag.
- The UI uses generic wallet icons/initials and theme colors, not official wallet logos.
- The app does not retain the verification code or PIN in provider state after submission.
- Invalid wallet numbers are rejected locally before the confirmation call.

## State additions

`PaymentProvider` now tracks wallet providers, selected provider, session result, and wallet-specific idempotency keys. Wallet states are explicit: loading providers, providers ready, provider selected, session ready, and processing wallet confirmation.
