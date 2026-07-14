# 49 - Fulfillment domain and order lifecycle

Phase 11 adds a fulfillment layer on top of the Phase 8 customer order domain instead of replacing it. The customer order remains the commercial source of truth, while fulfillment records the operational state of preparing, packing, shipping, and delivering the order.

## Backend domain

New backend code lives under `trademaster_ims/src/main/java/com/trademaster/ims/mobile/fulfillment` and introduces:

- `OrderFulfillment`: one fulfillment workflow per customer order.
- `FulfillmentStatusHistory`: auditable fulfillment transitions with actor and note fields.
- `DeliveryEvent`: delivery timeline events, with an explicit customer visibility flag.
- `CODCollection`: Cash on Delivery collection and reconciliation records.

The service intentionally keeps order status and fulfillment status separate, then synchronizes customer-visible order status at meaningful points. Fulfillment can start only after the order is `CONFIRMED`; unpaid non-COD orders are blocked before processing.

## Lifecycle

The implemented operational path is:

1. `CONFIRMED` order starts fulfillment as `PROCESSING`.
2. `PROCESSING` moves to `PACKED` after stock is reserved/deducted.
3. `PACKED` moves to `SHIPPED` with optional carrier, tracking number, and ETA.
4. `SHIPPED` moves to `OUT_FOR_DELIVERY`.
5. `OUT_FOR_DELIVERY` moves to `DELIVERED`.

Delivered orders remain compatible with Phase 8 return eligibility because the service writes the normal customer order delivered history entry. Cancellation remains unavailable after the order leaves early order states, so fulfillment does not reopen cancellation paths.

## API surface

Admin/manager fulfillment operations are exposed under `/api/orders/fulfillment`. Customer tracking is exposed separately under `/api/mobile/v1/orders/{orderNumber}/tracking` and uses the authenticated customer principal rather than a customer id parameter.

The admin API is secured for back-office roles/authorities, while the mobile tracking API is customer-only and ownership scoped.