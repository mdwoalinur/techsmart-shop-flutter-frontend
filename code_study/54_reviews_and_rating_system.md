# 54 - Reviews and Rating System

Phase 12 adds customer-facing product reviews and rating summaries without changing the existing catalog, checkout, payment, stock, fulfillment, or order business rules.

## Backend contract

The mobile backend exposes review data through customer-safe endpoints under `/api/mobile/v1`:

- product review summary for product detail rating display
- paged product reviews for the product detail review section
- delivered-order reviewable items for the Write Review flow
- authenticated customer review list for My Reviews
- create/update review operations tied to the authenticated JWT customer

Review ownership is resolved server-side. The mobile client never submits another customer identifier, and reviewable products are derived from delivered orders so the write-review action is constrained to real fulfilled purchases.

## Flutter implementation

Flutter Phase 12 uses a dedicated review layer:

- `ReviewSummary`, `ProductReview`, and `ReviewableItem` parse backend DTOs safely.
- `ReviewService` calls the mobile review APIs through the shared authenticated `ApiClient`.
- `ReviewProvider` keeps product reviews, rating summaries, reviewable order items, and My Reviews state isolated from catalog/order/payment providers.
- Product detail loads the review summary and customer-safe public reviews after the product detail response is available.
- Delivered order detail shows a Product reviews card with Write Review actions only for reviewable delivered items.
- My Reviews is linked from Menu and Profile.

## Customer-safe behavior

The review feature displays product title/image/code, rating, review title/comment, dates, and review status where applicable. It does not expose buying price, warehouse data, exact stock quantity, supplier data, or internal order/payment fields.

## Logout isolation

`ReviewProvider` listens to authentication state and clears customer-owned review lists and reviewable-order state on logout. Public product summaries can be reloaded normally after logout.
