# Phase 8 - Order Timeline and Status Domains

Timeline data comes from `CustomerOrderStatusHistory`; the backend does not synthesize completed shipment events. The UI renders actual persisted entries oldest-to-newest and highlights the current order status when the persisted history status matches the order status.

Status domains remain separate:

- Order status: starts as `PENDING_CONFIRMATION`; Phase 8 also defines future-safe values such as `PROCESSING`, `CANCELLED`, and `DELIVERED` for eligibility checks, but customers cannot set them.
- Payment status: remains `NOT_STARTED` for Phase 7/8 customer orders.
- Accounting status: remains `UNPOSTED`.

Flutter shows these as separate labels and never infers paid, delivered, posted, shipped, or refunded from another status domain.
