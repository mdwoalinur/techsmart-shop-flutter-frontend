# 12. Session Cart and Money Handling

## Safe model and identity

CartItem stores only product ID/name, safe image URL, product code or SKU, nullable variation ID/name, deterministic unit price, quantity, and public stock label. Its stable identity is `productId:base` or `productId:variationId`; it never retains ProductDetail or internal inventory data.

## Decimal arithmetic

DecimalValue was extended with integer multiplication and decimal addition using scaled BigInt arithmetic. No binary floating-point value participates in unit-price multiplication or subtotal addition. MoneyFormatter remains the single Taka formatter and emits the Bangladeshi Taka symbol through a Unicode escape. Focused tests cover multiplication and line subtotal.

## CartProvider

The app-level ChangeNotifierProvider owns session memory. Identical identities merge, different variations remain separate, quantities stay within 1-99, Out of Stock additions are rejected, and line count, total quantity, subtotal, removal, and clear are derived immediately. No disk or backend storage exists. A process restart may clear the Cart.

## User flow

Product Details adds the selected variation and quantity and prevents duplicate submission while processing. A bottom sheet reports product, optional variation, added quantity, total Cart quantity, subtotal, Continue Shopping, and View Cart using explicit current-session wording.

The Cart tab displays the session explanation, images, names, variations, prices, quantity controls, line subtotals, removal, clear confirmation, empty state, subtotal, and the future checkout validation notice. The bottom-navigation badge observes total quantity, hides at zero, and displays `99+` above 99. No checkout, coupon, tax calculation, delivery charge, payment, reservation, or synchronization is claimed.
