# Phase 8 - Return Request Foundation and Eligibility

Return requests are customer-side foundation records, not operational `SaleReturn` records. `CustomerReturnRequest` and `CustomerReturnRequestItem` start with status `REQUESTED`. They do not call `SaleReturnService`, do not increase stock, do not create refunds, do not reverse ledger/accounting, and do not process replacement shipment.

Eligibility is backend-authoritative. A normal Phase 7/8 order starts as `PENDING_CONFIRMATION`, so returns are not eligible. A return can become eligible only when the order is actually `DELIVERED` and a real `DELIVERED` status-history timestamp exists. The configurable return window is `techsmart.orders.return-window-days=${TECHSMART_RETURN_WINDOW_DAYS:7}`.

The Flutter return flow now supports the backend multi-item contract. Order Detail opens a dedicated Request Return screen that displays every backend-returnable item, lets the customer select one or more items, configure quantity/reason per selected item, enter per-item explanation text, choose one preferred resolution for the whole request, and add an optional overall customer comment. Unselected items are omitted from the request payload.

Per-item validation enforces quantity minimum 1, quantity maximum equal to the backend `remainingReturnableQuantity`, valid reason codes, and explanation text when the reason is `OTHER`. The review step shows all selected items before submission and labels the preferred resolution as requested, not approved.

Final submission sends exactly one `POST /api/mobile/v1/orders/{orderNumber}/return-requests` request containing all selected items plus one idempotency key. The provider prevents duplicate taps, preserves the draft and idempotency key after recoverable failure, and clears the draft only after confirmed success. The confirmation shows the returned request number and `REQUESTED` status.

The flow intentionally does not approve refunds, restore stock, create `SaleReturn` records, or perform ledger/accounting actions.