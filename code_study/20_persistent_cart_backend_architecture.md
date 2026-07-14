# Persistent Cart Backend Architecture

Phase 6 adds one `ACTIVE` cart per customer account and customer-owned cart items. Ownership is always derived from `CustomerAuthentication.accountId()`; request DTOs contain no customer, account, or cart identifier.

`customer_carts` has a unique account/status constraint and optimistic version. `customer_cart_items` stores only product identity, optional variation identity, quantity, timestamps, and version. A non-null `variation_key` uses `0` for the base product, preventing duplicate base rows despite MySQL nullable-unique behavior. Names, images, prices, totals, stock, buying price, supplier, and warehouse are never persisted in the cart.

The customer-only API is `GET /cart`, `POST /cart/items`, `PUT /cart/items/{itemId}`, `DELETE /cart/items/{itemId}`, `DELETE /cart`, `POST /cart/merge-session`, and `POST /cart/validate`, below `/api/mobile/v1`. Security rules are placed before the mobile deny-all rule and require `ROLE_CUSTOMER`.

Hibernate remains configured with `ddl-auto=update` for local development. Production needs reviewed migrations creating the five Phase 6 tables, unique constraints, foreign-key/index strategy, and rollback scripts; no SQL dump was executed or modified.
