# 37 - Payment Attempts, Gateway Verification, and Idempotency

Phase 9 introduces retry-safe customer payment initiation and a local/test gateway architecture. It is a development gateway foundation, not a production card integration.

## Payment method catalog

Customer-safe methods are loaded from the backend through:

`GET /api/mobile/v1/orders/{orderNumber}/payment-methods`

Default seeded methods are:

- `ONLINE_GATEWAY`
- `BANK_TRANSFER`
- `MOBILE_FINANCIAL_SERVICE`
- `CASH_ON_DELIVERY`

The response includes eligibility, amount limits, currency, instructions, proof/reference requirements, and review/auto-verification flags. It does not expose merchant IDs, signing keys, fraud thresholds, or internal ledger details.

## Online initiation

Flutter calls:

`POST /api/mobile/v1/orders/{orderNumber}/payments/initiate`

The request includes only a method code, an idempotency key, and optional controlled return metadata. It does not include customer ID, amount, currency, success flag, order status, payment status, or gateway transaction ID.

The backend:

1. Authenticates the customer.
2. Verifies order ownership.
3. Locks and validates the order.
4. Calculates the amount from `CustomerOrder.total`.
5. Creates or reuses `CustomerPayment`.
6. Creates or reuses a scoped `PaymentAttempt` for the idempotency key.
7. Creates a local/test gateway session.
8. Sets payment/order payment status to `PENDING_GATEWAY`.
9. Returns only safe session data.

## Local/test gateway

`PaymentGatewayAdapter` provides the provider abstraction. `LocalTestPaymentGatewayAdapter` is enabled outside the production profile and uses HMAC-SHA256 signatures for webhook validation. It can verify success, failure, duplicate event, invalid signature, amount mismatch, and currency/order mismatches when driven by tests or safe local smoke scripts.

The default local gateway secret is a non-production development value. It is not returned to Flutter and must be replaced with environment configuration before any real deployment.

## Webhook verification

Webhook endpoint:

`POST /api/mobile/v1/payments/webhooks/{provider}`

This endpoint does not require a customer JWT because server-to-server callbacks are not customer-authenticated. It requires provider support and signature verification.

The service verifies:

- signature validity
- unique event ID
- matching payment number
- matching order number
- amount match against server order total
- currency match
- unique gateway transaction ID
- payable order state
- duplicate/replay protection

Duplicate events return an idempotent duplicate result and do not post accounting again.

## Cancellation

Flutter can call:

`POST /api/mobile/v1/orders/{orderNumber}/payments/cancel`

Only an unpaid `PENDING_GATEWAY` payment can be cancelled by the owning customer. Cancellation records history, cancels the latest active attempt, leaves the order unpaid, and does not refund or reverse anything.
