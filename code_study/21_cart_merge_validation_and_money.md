# Cart Merge, Validation, and Money

Adds validate active products, variation existence/ownership/activity, quantity 1–99, and customer-visible availability. Stock is never reserved and exact quantities are not returned. Current unit price is calculated with `BigDecimal` as product selling price plus variation additional price; line subtotal and cart subtotal are recalculated for every response.

Guest merge accepts only product ID, optional variation ID, quantity, and a client-generated request ID. A unique account/type/request receipt makes retries idempotent. Identical identities sum, values above 99 are capped with `QUANTITY_ADJUSTED`, and invalid/inactive/out-of-stock entries return item warnings without silently converting a variation to a base product. Receipt and mutations share one transaction.

Validation remaps live product, price, variation, image, and stock-label data. Unavailable persisted lines remain visible as warnings rather than causing inventory or order side effects. Phase 7 may add explicit client price-observation snapshots; Phase 6 does not persist an authoritative price snapshot.
