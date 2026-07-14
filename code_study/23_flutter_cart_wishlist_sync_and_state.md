# Flutter Cart and Wishlist Synchronization

The existing Provider architecture and screens remain. `CartProvider` and `WishlistProvider` now have guest and authenticated modes. Guest operations retain Phase 4 in-memory behavior. Authenticated operations use `CustomerShoppingService`, and every successful response replaces local items and server-authoritative totals.

Providers expose loading, mutation, merge, error, warning, and retry state. An auth listener detects customer transitions rather than rebuilds or token refreshes. It snapshots guest items, loads server state, submits one unique merge request, and clears the snapshot only after success. Failed merge state remains retryable. A generation guard prevents stale responses crossing logout/customer transitions.

Cart badges use current provider quantity; Wishlist Menu counts use current provider items. Logout discards authenticated cached values and avoids exposing them to a guest or subsequent customer. UI copy distinguishes session-only from account-saved data. Checkout remains disabled and no order/payment call exists.
