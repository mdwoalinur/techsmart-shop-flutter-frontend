# Phase 8 - Order History, Detail, and Ownership

Phase 8 extends the dedicated Phase 7 `CustomerOrder` aggregate instead of creating Sale records. Mobile order endpoints live under `/api/mobile/v1/orders` and always derive ownership from `CustomerAuthentication.accountId()`. No request body accepts customer ID, account ID, employee ID, payment status, accounting status, or order transition target.

`GET /orders` returns a customer-owned paginated page with safe filters for order status, payment status, dates, query/order number, and controlled sorting (`newest`, `oldest`, `total_desc`, `total_asc`). Page size is capped at 50. Summaries expose order number, submitted date, visible status label, payment status, grand total, quantity counts, first item snapshot, delivery method snapshot, and backend-calculated cancellation/return eligibility.

`GET /orders/{orderNumber}` returns customer-safe snapshots only: product names/codes, variation names, unit price, tax, quantities, delivery-address snapshot, delivery-method snapshot, totals, note, timeline, eligibility blocks, and document availability. It does not expose buying price, profit, warehouse, supplier, employee, idempotency key, checkout fingerprint, review token, or internal audit payloads.
