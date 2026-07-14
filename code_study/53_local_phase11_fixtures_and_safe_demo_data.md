# 53 - Local Phase 11 fixtures and safe demo data

Phase 11 physical validation uses a disabled-by-default local fixture tool so no unknown customer, order, payment, or stock records need to be reused or mutated.

## Fixture endpoint

Backend path:

```text
POST /api/dev/phase11-fixtures/customer-fulfillment
GET /api/dev/phase11-fixtures/customer-fulfillment/{orderNumber}/verification
```

The fixture controller is only registered when the backend starts with:

```text
--techsmart.dev-fixtures.enabled=true
```

It also accepts loopback requests only. Normal production/default runs do not expose this tool.

## Disposable records

The fixture creates or refreshes disposable local accounts only:

- Customer A: `phase11.customer.a@example.test`
- Customer B: `phase11.customer.b@example.test`
- Admin/operator: `phase11.admin@example.test`

Returned passwords are temporary local validation values and are not documented here. No real credentials, tokens, OTPs, wallet PINs, courier keys, SMS keys, or payment secrets are stored in documentation.

Each fixture call creates fresh order/product data:

- one prepaid Customer A order in `CONFIRMED / PAID / POSTED` state;
- one COD Customer A order in `CONFIRMED / COD_PENDING / UNPOSTED` state;
- fixture products with enough stock;
- a local fixture warehouse if needed;
- an active local cash account if no posting account exists.

No SQL dump import, reset, truncate, or table drop is used.

## Validation performed

Backend/API smoke verified:

- prepaid start-processing, pack, ship, out-for-delivery, deliver;
- COD start-processing, pack, ship, out-for-delivery;
- wrong COD amount rejected with 409;
- exact COD amount marks payment/order paid and posted;
- stock movement count remains exactly once per order item;
- duplicate pack/deliver retries do not create duplicate stock movements;
- Customer B cannot fetch Customer A tracking/detail;
- Customer B notification list does not contain Customer A order references.

Samsung physical validation verified:

- Samsung SM A556E `R5CX32F8CJB` connected;
- ADB reverse `tcp:8080 tcp:8080` active;
- APK installed and launched;
- fixture products visible on the physical home/catalog screen;
- Customer A login succeeds through the app UI;
- Customer A menu shows My Orders, Notifications, and Logout;
- Customer A fulfillment notification opens notification detail, View Order navigates to the matching order tracking/detail screen, and mark-read decreases the unread count;
- Customer A order list shows fixture prepaid/COD orders;
- COD detail shows Delivery tracking, COD pending before collection, and no warehouse/supplier/buying-price leakage;
- after backend COD fulfillment and exact collection, Refresh tracking shows Delivered, Payment PAID, COD reconciled, courier, tracking number, and deliveredAt;
- Customer A logout returns to guest state;
- Customer B login succeeds;
- Customer B sees no Customer A orders and no Customer A profile data;
- device log scan found no fatal exception, RenderFlex overflow, raw ApiException loop, repeated 401/403 loop, token/password/OTP/PIN logging, or SQL stack traces.