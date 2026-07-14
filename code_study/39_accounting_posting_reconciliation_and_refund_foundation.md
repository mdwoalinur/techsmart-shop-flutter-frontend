# 39 - Accounting Posting, Reconciliation, and Refund Foundation

Phase 9 posts customer payments to accounting only after verified gateway success or admin manual approval. Flutter never posts ledger entries.

## Exactly-once posting

`CustomerPaymentService.postOnce` uses a unique posting key of the form:

`CUSTOMER_PAYMENT:{paymentNumber}`

If the payment is already posted, the service returns without creating a second ledger entry. Duplicate webhook processing also returns an idempotent duplicate result.

The posting path uses existing accounting structures:

- `FinancialAccount`
- `AccountLedgerEntry`
- `Payment.PaymentDirection.RECEIVE`
- `AccountLedgerEntry.EntryType.PAYMENT_RECEIPT`

The ledger entry stores the customer payment number as the voucher number and the order ID as reference. The payment stores the ledger entry ID and posting timestamp.

## Automatic success sequence

For online payments, the successful sequence is:

1. Lock payment/order.
2. Verify gateway event.
3. Mark payment `VERIFIED`.
4. Post accounting once.
5. Mark payment `PAID`.
6. Mark accounting `POSTED`.
7. Mark order payment `PAID`.
8. Confirm the order if it was pending confirmation/payment.
9. Append payment and order histories.
10. Commit transaction.

If posting cannot complete, the payment is moved to review rather than silently claiming paid.

## Reconciliation foundation

Admin reconciliation endpoint:

`POST /api/payments/customer/{paymentNumber}/reconcile`

The reconciliation record stores provider, settlement reference, expected amount, settled amount, status, mismatch reason, and timestamps. Exact settlement amount can mark the reconciliation record as reconciled. Mismatches move the record/payment to review.

## Refund foundation

Admin refund endpoint:

`POST /api/payments/customer/{paymentNumber}/refunds`

Refund requests are linked to the original customer payment, use idempotency keys, enforce maximum refundable amount, and create backend review/audit state. Phase 9 does not expose customer refund approval UI and does not auto-refund cancellation requests.

## Production migration note

Hibernate update can create the Phase 9 tables during development. A production deployment should convert these entity changes to explicit migrations, including all unique constraints and indexes for event IDs, transaction IDs, payment numbers, posting keys, and refund idempotency.
