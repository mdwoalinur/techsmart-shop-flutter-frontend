# 36 - Payment Domain and Status Separation

Phase 9 adds a customer-payment domain for the mobile shop while preserving the internal TradeMaster payment module used by Angular workflows. The mobile payment layer is intentionally separate from order fulfillment, accounting posting, manual review, reconciliation, and refund state.

## Domain boundaries

- `CustomerOrder` remains the customer order aggregate created in Phase 7 and surfaced in Phase 8.
- `CustomerPayment` is the mobile/customer payment aggregate for one order payment lifecycle.
- `PaymentAttempt` records each retry/session/idempotency attempt.
- `PaymentEvent` records gateway callbacks and their processing result.
- `PaymentStatusHistory` records customer-safe payment timeline entries.
- Existing `Payment`, `PaymentAllocation`, `PaymentApprovalHistory`, `FinancialAccount`, and `AccountLedgerEntry` remain available for internal workflows; Phase 9 does not rewrite Angular payment behavior.

## Status domains

Order status, payment status, attempt status, and accounting status are not collapsed into one enum.

Order examples:

- `PENDING_CONFIRMATION`
- `PENDING_PAYMENT`
- `CONFIRMED`
- `PROCESSING`
- `DELIVERED`
- `CANCELLED`
- `RETURN_REQUESTED`
- `RETURNED`
- `REFUNDED`

Payment examples:

- `NOT_STARTED`
- `INITIATED`
- `PENDING_GATEWAY`
- `VERIFIED`
- `PAID`
- `FAILED`
- `CANCELLED`
- `REVIEW_REQUIRED`
- `COD_PENDING`
- `CASH_COLLECTED`
- `RECONCILED`
- `REFUNDED`
- `REVERSED`

Attempt examples:

- `CREATED`
- `SESSION_CREATED`
- `PENDING`
- `SUCCEEDED`
- `FAILED`
- `CANCELLED`
- `EXPIRED`
- `REVIEW_REQUIRED`

Accounting examples:

- `UNPOSTED`
- `POSTED`
- `REVERSED`

## Why the separation matters

Flutter can display status, retry, cancellation, manual review, and COD information, but it cannot mark a payment as paid. The backend only marks `PAID` after gateway/manual review rules and accounting posting rules pass.

A COD order may be `CONFIRMED` while payment is still `COD_PENDING` and accounting is still `UNPOSTED`. An online payment may be `PENDING_GATEWAY` while the order remains unpaid. A manual payment can be `REVIEW_REQUIRED` with no ledger posting.

## Schema impact

Phase 9 adds mobile payment tables for methods, payments, attempts, events, histories, manual submissions, reviews, refunds, and reconciliation records. The design relies on unique payment numbers, gateway event IDs, gateway transaction IDs, idempotency keys scoped by customer/order, posting keys, and refund idempotency keys.
