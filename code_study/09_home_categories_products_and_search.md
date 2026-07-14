# 09 - Home, Categories, Products, and Search

Home retains branding and the centered navigation action, then loads real root categories and `createdAt desc` products under **Latest Products**. Search, View All, category products, and details use ordinary Navigator pushes, so Android back works and primary tab state remains in the existing IndexedStack.

Categories is a responsive active-category grid using generic initials, not fake backend images. Product Listing has count, supported sort/filter, responsive cards, refresh, and infinite loading. Search exclusively uses `/products/search`, trims and caps input at 100 characters, debounces, ignores stale responses, and paginates.

Reusable loading, empty, error/retry, image fallback, product grid, and card widgets live under `lib/ui/widget`. Complete backend image URLs use `Image.network`, progress, `BoxFit.contain`, and fallback; no dependency was needed. Cards show only real name, selling price, and stock label—never buying price, quantity, fake rating, discount, brand, or delivery data.
