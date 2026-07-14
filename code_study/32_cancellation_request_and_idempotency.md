# Phase 8 - Cancellation Request and Idempotency

Cancellation uses a separate `CustomerOrderCancellationRequest` table. A request starts as `REQUESTED`; it does not change payment, ledger, stock, Sale, or refund state. The conservative policy is request-only: eligible customers can request cancellation while the order is `PENDING_CONFIRMATION`, and operations/admin approval can be added later.

Controlled cancellation reasons are `ORDERED_BY_MISTAKE`, `NEED_TO_CHANGE_ADDRESS`, `NEED_TO_CHANGE_ITEMS`, `FOUND_BETTER_PRICE`, `DELIVERY_TIME_TOO_LONG`, and `OTHER`. `OTHER` requires explanation. Text is trimmed and HTML tags are not trusted.

Idempotency uses `(customer_account_id, idempotency_key)`. Repeating the same key for the same order returns the same request; reusing it for another order is rejected. One active `REQUESTED` or `UNDER_REVIEW` request per order is enforced in service logic.
