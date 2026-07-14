# Flutter Address and Checkout State

`CheckoutProvider` integrates with `AuthProvider`, loads addresses and server delivery methods, selects prerequisites, requests reviews, requires terms, and retains one idempotency key across uncertain retries. Logout clears all address, review, key, and confirmation memory without deleting server data.

The address form uses keyboard-safe scrolling and backend-authoritative validation. Checkout displays only server totals, disables submission until review and terms are valid, prevents duplicate taps, and shows a customer-safe confirmation. Guest Cart checkout opens Login while preserving the guest cart for the existing merge. Payment is explicitly deferred and Order History remains disabled for Phase 8.
