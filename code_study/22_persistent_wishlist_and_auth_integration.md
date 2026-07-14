# Persistent Wishlist and Authentication Integration

Each customer account has one wishlist. Items persist only wishlist ID, product ID, and creation time with a unique wishlist/product constraint. Responses map current customer-safe name, image, selling price, category, and stock label. Out-of-stock products can remain; inactive/deleted products are skipped with warnings.

Wishlist merge is a set union protected by the same account/type/request idempotency receipt pattern as cart merge. Authentication ownership comes exclusively from the customer JWT. Employee authority cannot enter these routes.

Login, verified registration, and restored sessions trigger one edge-based synchronization per customer identity. Logout clears only Flutter's authenticated cache and starts a clean guest session; it never calls backend cart/wishlist clear. Compare is intentionally untouched and remains current-process state.
