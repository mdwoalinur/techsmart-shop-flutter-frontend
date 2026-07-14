# 51 - Customer tracking and delivery events

Phase 11 adds customer-facing delivery tracking without leaking warehouse, supplier, internal audit, or back-office-only details.

## Customer API

`GET /api/mobile/v1/orders/{orderNumber}/tracking` returns a safe tracking summary for the authenticated customer. The endpoint rejects employee/admin tokens and does not accept a customer id in the request.

The response includes:

- order number;
- fulfillment status;
- order and payment status labels;
- COD tracking state when relevant;
- delivery partner/tracking number/ETA when available;
- delivered timestamp;
- customer-safe tracking steps;
- customer-visible delivery events only.

Internal delivery events can still be recorded by fulfillment staff, but they are filtered out of the mobile response unless explicitly marked visible.

## Flutter integration

Flutter adds `lib/model/tracking/order_tracking_models.dart` and extends the order repository/service/provider with `tracking(orderNumber)`.

`OrderProvider.loadDetail()` now starts a tracking load for the selected order. Tracking data is cached by order number, supports refresh, and is cleared on logout/customer changes to avoid account bleed.

`OrderDetailScreen` now renders a `Delivery tracking` section with:

- fulfillment, payment, and COD labels;
- carrier/tracking/ETA metadata;
- step status icons;
- delivery events;
- safe retry/error messaging.

Widget tests confirm the section renders tracking data while excluding internal words such as warehouse and supplier.

## Notifications

Fulfillment transitions create Phase 10 customer notifications for processing, packed, shipped, out for delivery, delivered, COD collected, and COD reconciled events. A customer notification schema fixer mirrors the existing notification enum guard for local upgraded MySQL databases.