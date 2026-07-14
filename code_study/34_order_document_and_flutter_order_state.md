# Phase 8 - Order Document and Flutter Order State

The customer document endpoint is `GET /api/mobile/v1/orders/{orderNumber}/document`. It returns a safe JSON document payload with an HTML order summary/pro forma, filename, title, and content type. The document truthfully shows `NOT_STARTED` payment status and states that it is not a paid invoice or payment receipt.

Flutter adds `OrderService`, `OrderProvider`, `MyOrdersScreen`, `OrderDetailScreen`, and `ReturnRequestScreen`. Provider state covers history loading, refresh, load-more, filters, selected detail, cancellation submission, return draft/submission, document loading, and logout isolation. On customer change or logout it clears history, selected order, cancellation state, return request state, return draft state, document data, and errors.

`OrderProvider` owns a multi-item `ReturnRequestDraft` with selected items, requested quantities, reason codes, reason text, preferred resolution, customer comment, and idempotency key. It validates the draft before review/submission, submits one backend request, blocks duplicate submissions, retains draft state and idempotency while the outcome is uncertain, and restores the returned request after refreshing order detail/history so the confirmation screen can show the request number and `REQUESTED` status.

The return UI uses keyboard-safe scrolling and expanded dropdown controls for Samsung-width layouts. Widget coverage includes a 360 x 640 constrained viewport to guard against RenderFlex overflow.

The checkout confirmation screen links to the same Order Detail screen using the returned order number. My Orders is linked from the authenticated menu. Guests see a login-required message and no protected order API call is issued.