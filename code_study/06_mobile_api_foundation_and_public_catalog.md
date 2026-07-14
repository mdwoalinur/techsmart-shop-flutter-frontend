# 06 - Mobile API Foundation and Public Catalog

## Purpose and inspected architecture

Phase 2 creates a stable customer catalog contract without changing the entity-oriented APIs used by Angular. Inspection covered Spring Boot/security/JWT/CORS, Product, Category, ProductVariation, Inventory, Warehouse and Unit entities, their repositories/services/controllers, auditing, upload resource handlers, application properties, the existing test, and relevant Angular catalog models/services.

Products store category and unit IDs rather than entity relationships. Categories use a Boolean status and parent ID. Variations store `additionalPrice` and a confidential buying price. Inventory stores quantity, reserved quantity and available quantity per product/warehouse. Warehouse status is free text and does not define an approved online-sales warehouse flag.

## Package and DTO strategy

New code lives under `com.trademaster.ims.mobile`:

```text
mobile/common/exception     scoped advice and mobile exceptions
mobile/common/response      success, page, field-error and error envelopes
mobile/catalog/controller   health and catalog HTTP endpoints
mobile/catalog/dto          immutable customer response/query records
mobile/catalog/mapper       explicit safe field mapping
mobile/catalog/service      validation, specifications, images and catalog orchestration
```

No existing entity, service or controller was moved. Mobile controllers never serialize JPA entities.

## Security

Only these GET patterns are public:

```text
/api/mobile/v1/health
/api/mobile/v1/categories
/api/mobile/v1/categories/{id}
/api/mobile/v1/categories/{id}/products
/api/mobile/v1/products
/api/mobile/v1/products/{id}
/api/mobile/v1/products/search
```

The next mobile matcher denies every other method/path. Existing login rules, uploaded public images, Angular CORS origin, JWT filter and protected `/api/**` behavior remain unchanged. Tests prove public GET access, legacy `/api/products` protection and mobile POST denial.

## Response and error contracts

Success uses `success`, `data`, nullable `message`, and an ISO-8601 `timestamp`. Pages contain content, zero-based page, size, total elements/pages, first and last.

Errors use `success=false`, stable code, safe message, field errors, timestamp, request path and nullable trace ID. The mobile-only advice handles validation, missing/invalid parameters, unavailable resources and unexpected errors. Stack traces and internal details stay in server logs, not responses.

## Catalog behavior

- Categories: active-only list; optional `parentId`; `rootOnly`; active detail with active direct children.
- Category products: direct category only, not descendants, with the same page/filter rules as products.
- Products: active-only, database-side pagination/filtering through JPA Specifications.
- Search: trimmed, case-insensitive name/code/SKU/description search; `%`, `_` and escape characters are escaped; maximum 100 characters.
- Page defaults: `page=0`, `size=20`; maximum size 100.
- Sort allow-list: API `name`, `price`, `createdAt`, `updatedAt`; direction `asc` or `desc`.
- Price filters reject negatives and `minPrice > maxPrice`.
- Stock filter uses existence of positive available inventory in the database.

## Safe field mapping

Product responses expose ID, code, SKU, name, description, selling price, tax rate, safe image URL, safe category/unit summaries and stock label. Details additionally expose active variations.

Buying prices, min/max/reorder values, exact inventory quantities, warehouse IDs, company IDs, reserved quantities, audit fields and internal actors are excluded.

Available inventory is aggregated across all warehouse records because the current model has no standardized online/inactive warehouse rule. Negative/missing totals become zero. Labels are `Out of Stock`, `Low Stock`, or `In Stock`; exact totals are never returned. Variation-specific inventory does not exist, so variations inherit product-level availability.

Variation effective selling price is `product.sellingPrice + variation.additionalPrice`. Variation buying price is never read into the response. Negative additional prices are preserved because the current business data uses them as valid adjustments.

## Image strategy

Absolute HTTP(S) URLs are preserved. Only relative product and product-variation upload paths are expanded. Other upload classes, including receipts/payment evidence, return `null`. The origin is the current request unless trusted deployment configuration supplies `TECHSMART_PUBLIC_BASE_URL`; localhost and LAN addresses are not hardcoded.

## Query and test strategy

Filtering/search/pagination run in the database. Page mapping batch-loads category IDs, unit IDs and aggregate inventory totals to avoid per-product queries. Product details load active variations once. No migration or production index was added; indexes on status/category/price/search columns can be reviewed with production query plans later.

The final suite has isolated mapper/service tests and a minimal MockMvc security slice. It does not connect to MySQL. The former generic context test was changed to an entry-point test because its baseline behavior contacted the developer database and ran schema fixers.

## Verified commands and examples

Cached Maven 3.9.12 was used because `mvnw.cmd` has a pre-existing PowerShell null-array defect. Final Maven compile/tests and Flutter analysis/tests passed. `mvn spring-boot:run` also started successfully against local MySQL for short-lived curl checks.

```cmd
curl http://localhost:8080/api/mobile/v1/health
curl "http://localhost:8080/api/mobile/v1/categories"
curl "http://localhost:8080/api/mobile/v1/categories/1/products?page=0&size=20"
curl "http://localhost:8080/api/mobile/v1/products?page=0&size=20"
curl "http://localhost:8080/api/mobile/v1/products/search?q=laptop&page=0&size=20"
curl "http://localhost:8080/api/mobile/v1/products/1"
```

All examples were executed. The first five returned 200 for current data except product `1`, which returned the expected safe 404 because it is unavailable. An active detail (`/products/32`) returned 200. Unsafe `sort=buyingPrice` and `size=101` returned structured 400 errors.

For a USB Android device, a future Flutter phase will use ADB reverse and `http://127.0.0.1:8080/api/mobile/v1`. Phase 2 does not call these APIs from Flutter.

## Limitations and next readiness

Warehouse online eligibility and variation-specific stock are not represented by the current model. Search uses portable case-insensitive LIKE rather than full-text indexing. Product/category public visibility is currently equivalent to active status. Authentication, customer accounts, cart, wishlist, checkout, orders, payment, reviews, promotions, notifications and Flutter catalog UI/providers remain intentionally deferred to later phases.
