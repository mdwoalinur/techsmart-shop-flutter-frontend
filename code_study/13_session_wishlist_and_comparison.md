# 13. Session Wishlist and Comparison

## Wishlist

WishlistItem keeps product ID/name, safe image URL, selling price, stock label, and optional category. WishlistProvider adds, removes, toggles, prevents duplicate IDs, clears, checks membership, and exposes count in memory only.

Product cards and Product Details expose accessible heart actions with immediate Provider state. The Menu opens Session Wishlist, where users can open details, remove items, clear with confirmation, and add an in-stock item to the session Cart. It explicitly states that state lasts only while the app is running.

## Comparison

CompareItem keeps only ID/name, image URL, selling price, stock label, category, unit, code, and SKU. CompareProvider prevents duplicates and enforces a four-product maximum; a fifth product produces an understandable message. It supports toggle, remove, contains, count, and clear.

Product-card and Product Details compare controls share the app-level provider. Menu opens a horizontally scrollable phone-safe table with supported rows, individual removal, detail navigation, clear-all confirmation, and an empty state. The screen states that comparison uses only currently available product information.

Rating, reviews, warranty, brand assumptions, detailed specifications, dimensions, features, discounts, and delivery are not compared. Wishlist and comparison are neither persisted nor synchronized and require no login. Bottom navigation remains Categories, Offers, Home, Cart, Menu.
