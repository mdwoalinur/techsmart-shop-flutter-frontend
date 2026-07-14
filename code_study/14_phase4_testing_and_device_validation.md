# 14. Phase 4 Testing and Device Validation

## Automated coverage

The original 26 Flutter tests remain. Phase 4 adds model/provider tests for safe models, base and variation identities, exact subtotal math, merging and separation, quantity bounds, totals, removal, clear, Out of Stock rejection, wishlist lifecycle, comparison lifecycle, duplicate protection, and the four-item limit. Widget coverage exercises variation price, quantity, Add-to-Cart confirmation, View Cart, dynamic badge, product-card Wishlist/Compare, Menu screens, and exclusion of unsupported fields. Existing center Home navigation coverage remains.

Flutter tests use FakeCatalogRepository and do not require MySQL. Backend regression tests remain independent.

## Verification commands

Final verification runs directly in `E:\Dart_flutter\flutter_project\tech_smart_shop`: `dart format .`, `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk --debug`. Backend regression runs from `E:\Dart_flutter\flutter_project\trademaster_ims` with the verified cached Maven executable. The debug APK is checked at `build\app\outputs\flutter-apk\app-debug.apk`.

## Device and Web safety

Physical validation targets Samsung SM A556E (`R5CX32F8CJB`) with ADB reverse from device port 8080 to the local backend and API base URL `http://127.0.0.1:8080/api/mobile/v1`. Recorded results cover live Home, Product Details, variation and quantity actions, session Cart/badge, Wishlist, Compare, back/Home navigation, exceptions, and overflow.

Phase 4 adds no `dart:io`, platform channels, platform-specific state code, or Flutter plugins, preserving Web compilation safety. Persistence, authentication, customer accounts, and checkout are intentionally deferred. Phase 5 may start only after all final gates and device checks pass.
