# 11. Phase 4 Baseline and Product Detail Design

## Governing context

Phase 4 was implemented only in `E:\Dart_flutter\flutter_project\tech_smart_shop`, under the approved `TechSmart_Shop_Full_Project_Plan_Draft_v4.md`. The current Java entities, mobile DTOs, Flutter contracts, and runtime API remain the technical source of truth. `Dump20260701.sql` was inspected only as a read-only supporting reference.

The verified pre-edit baseline was 17 passing Spring Boot tests, `flutter analyze` with no issues, and 26 passing Flutter tests. Phase 3 catalog behavior was preserved.

## Scope and data safety

The detail screen uses only ProductDetail and active ProductVariation data: name, image URL, code, SKU, description, customer selling/effective price, category, unit, public tax rate, and customer-safe stock label. Buying price, exact inventory, reservations, warehouses, suppliers, audit data, ratings, discounts, warranties, specifications, delivery claims, and related products are excluded.

## Images and variations

The base URL is the fallback main image. Only distinct backend-provided base or variation URLs become thumbnails; no fake gallery is synthesized. Selecting a variation uses its effective price and SKU. Its real image replaces the main image, while a missing variation image falls back to the base image. Base selection restores base values. Existing ProductImage loading and error fallbacks preserve aspect ratio without a caching plugin.

## Quantity and stock

Quantity is integer state bounded from 1 through 99. Decrement is disabled at 1 and increment at 99. Add to Session Cart is disabled for Out of Stock products. The screen states that final stock and price are verified during checkout. Loading, API failure/not-found with retry, SafeArea, and scrolling behavior remain supported.

No Phase 5 authentication, checkout, account, persistence, backend, Angular, database, or native work was started.
