# 38 - Manual Payment Review and COD

Phase 9 supports manual bank/mobile transfer references and cash-on-delivery without allowing Flutter to mark payments as approved or paid.

## Manual payment submission

Flutter calls:

`POST /api/mobile/v1/orders/{orderNumber}/payments/manual`

The customer may submit:

- payment method code
- transaction/reference number
- submitted amount displayed from backend status
- payer name
- payer phone
- customer note
- idempotency key

The customer may not submit approval status, reviewer identity, paid status, accounting status, customer ID, or order status.

The backend verifies ownership and payable amount, checks duplicate manual references, creates a `CustomerPayment`, creates a review-required attempt, records `ManualPaymentSubmission`, creates `PaymentReview`, sets payment/order payment status to `REVIEW_REQUIRED`, and does not post accounting.

Proof upload is intentionally deferred. The current implementation supports reference-only manual payment. A future proof upload should use authenticated private storage, MIME/extension validation, generated filenames, size/count limits, and authorized download.

## Admin review

Admin-compatible review APIs are under `/api/payments`:

- `GET /api/payments/reviews`
- `POST /api/payments/reviews/{id}/approve`
- `POST /api/payments/reviews/{id}/reject`

Review endpoints are role/authority protected. Approval transitions the payment through verified/paid, posts accounting exactly once, and confirms the order when safe. Rejection marks the payment failed, keeps the order unpaid, and does not post accounting.

## Cash on Delivery

Flutter calls:

`POST /api/mobile/v1/orders/{orderNumber}/payments/cod`

COD creates a payment record with `COD_PENDING`, confirms the order for delivery processing when applicable, and keeps accounting `UNPOSTED`. The customer UI explains that cash is collected on delivery and does not show `PAID`.

Collection and reconciliation controls are backend/admin responsibilities. Phase 9 lays the foundation for later role-protected collection/reconciliation flows without exposing collection controls in Flutter.
