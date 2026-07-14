# 50 - Stock deduction and COD collection policy

Phase 11 connects fulfillment to inventory and payment without creating POS sales or duplicating Phase 9 accounting flows.

## Stock deduction

Stock is deducted exactly once when a fulfillment reaches `PACKED`.

The service uses three safeguards:

- A fulfillment-level `stockDeducted` flag.
- A stock movement reference shaped as `CUSTOMER_ORDER_FULFILLMENT:{orderNumber}:{itemId}`.
- A repository existence check before writing the movement.

The new stock movement type is `CUSTOMER_ORDER_FULFILLMENT`. A schema compatibility fixer updates existing MySQL enum columns if the local database still stores stock movement types as an enum.

The warehouse policy is conservative:

1. use the requested warehouse when supplied;
2. otherwise use `techsmart.fulfillment.default-warehouse-id` when configured;
3. otherwise use the first active warehouse;
4. block packing when no warehouse is available.

If any item lacks sufficient stock, packing fails before the order is advanced.

## COD delivery and reconciliation

Cash on Delivery orders may enter fulfillment while their payment is `COD_PENDING`. Delivery requires exact collection of the outstanding COD amount.

- Exact amount: record COD collection, reconcile the payment, mark the order paid/posted, write ledger entry once, then deliver.
- Mismatch: record a `COLLECTION_MISMATCH` delivery event and block delivery.

Ledger posting reuses the Phase 9 `CUSTOMER_PAYMENT:{paymentNumber}` posting key rule. This keeps COD reconciliation idempotent and prevents a second ledger entry if a delivery action is retried.

## No Sale creation

Fulfillment does not call the sales/POS service and does not create a Sale. The customer order is already the e-commerce commercial document; stock movement and payment ledger entries are the operational/accounting effects needed for delivery.