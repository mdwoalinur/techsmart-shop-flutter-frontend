# 07 - Flutter Catalog Models and Services

Phase 3 is governed by `E:\Dart&flutter\flutter_project\TechSmart_Shop_Full_Project_Plan_Draft_v3.md`. The read-only supporting dump was `E:\Dart&flutter\flutter_project\Dump20260701.sql`. The Java records, controller, mapper, service, exceptions, and `06_mobile_api_foundation_and_public_catalog.md` were read before changes. Java/runtime contracts take priority over the dump.

The dump contains buying price, raw inventory, warehouse, and audit columns; mobile DTOs deliberately omit them. `lib/model/common/api_models.dart` defines success/page/error envelopes, field errors, strict boundary helpers, and useful parse failures. `lib/model/product/catalog_models.dart` defines immutable category, product, detail, variation, unit, and safe stock models.

`DecimalValue` retains the received numeric representation and avoids client currency arithmetic. `MoneyFormatter.taka` adds deterministic grouping and `৳` without device locale behavior. Variation effective price comes directly from the backend.

`CatalogService` implements injectable `CatalogRepository` and uses central `ApiClient`; widgets never call HTTP. Query maps are URI-encoded and nulls omitted. Safe error envelopes map to `CatalogRequestException`. Used GET endpoints are `/categories`, `/categories/{id}`, `/categories/{id}/products`, `/products`, `/products/search`, and `/products/{id}` with only page, size, sort, direction, categoryId, minPrice, maxPrice, inStock, and search `q`.

MockClient tests cover query encoding, filters, successful parsing, 400/404/500, timeout, and network failure without MySQL.
