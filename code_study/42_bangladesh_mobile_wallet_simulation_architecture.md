# 42. Bangladesh Mobile Wallet Simulation Architecture

Phase 9.1 adds a backend-driven Bangladesh mobile wallet payment simulation on top of the Phase 9 payment spine. It does not integrate any real bKash, Nagad, Rocket, Upay, SureCash, or Tap API, and it does not store real wallet credentials.

## Backend domain additions

- `MobileWalletProviderConfiguration` stores safe provider catalog metadata: code, display name, visual key, labels, hints, active flag, display order, simulation flag, amount limits, currency, and instructions.
- `PaymentMethodConfiguration.MethodType.MOBILE_WALLET` introduces Mobile Wallet as a distinct method from the existing manual `MOBILE_FINANCIAL_SERVICE` / Mobile Transfer flow.
- `PaymentAttempt.failedCredentialAttempts` bounds repeated simulated credential failures without storing verification codes or PINs.

## API surface

- `GET /api/mobile/v1/orders/{orderNumber}/mobile-wallet-providers`
  - Authenticated customer endpoint.
  - Verifies order ownership and returns only safe provider metadata plus eligibility.
- `POST /api/mobile/v1/orders/{orderNumber}/payments/mobile-wallet/initiate`
  - Request contains only `providerCode` and `idempotencyKey`.
  - Amount, currency, customer, order, payment, and attempt are derived server-side.
- `POST /api/mobile/v1/payments/mobile-wallet/{attemptReference}/confirm`
  - Request contains wallet number, verification code, PIN, and idempotency key.
  - The backend validates the presentation credentials and masks the wallet number before persistence.

## Simulation controls

The local/presentation simulation is disabled for production profiles. Runtime behavior can be controlled with:

- `TECHSMART_MOBILE_WALLET_SIMULATION=true`
- `TECHSMART_MOBILE_WALLET_RESULT=SUCCESS|PENDING|FAILED|CANCELLED`

The default non-production result is `SUCCESS`.

## Posting behavior

Only a successful backend-confirmed wallet result transitions the payment through `VERIFIED` to `PAID`, posts accounting once via the existing customer payment posting key, updates the order to `PAID` / `POSTED`, and confirms pending orders. Pending, failed, cancelled, expired, and invalid-credential paths do not post accounting.
