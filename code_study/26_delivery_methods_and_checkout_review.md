# Delivery Methods and Checkout Review

Delivery methods are backend records, seeded idempotently for standard and express Bangladesh delivery. Eligibility supports country, optional division/district, and optional subtotal limits. Flutter never supplies a charge.

`POST /checkout/review` loads the authenticated cart, active owned address, and delivery method; reloads products, variations, prices, tax rates, and aggregate availability; then calculates line subtotal, tax, delivery, and grand total with `BigDecimal`, scale 2, `HALF_UP`. Prices are treated as tax-exclusive because the existing product tax rate is applied separately. Review does not reserve or deduct stock.

The persisted review expires after fifteen minutes and fingerprints cart identities, quantities, current prices/taxes, address, delivery configuration, and total.
