# 10 - Product Details, Filters, and Pagination

Detail shows the safe image, name, code/SKU, price, category, unit, stock label, description, and active variation chips. Selection updates image, backend effective price, and inherited safe stock. Not-found/network states retry safely. Cart is disabled and explicitly deferred; Phase 4 was not started.

Sort labels map only to `name`, `price`, `createdAt`, and `updatedAt` with asc/desc. Filters are category, minimum/maximum price, and in-stock. Validation rejects non-numbers, negatives, and minimum above maximum. Reset preserves a listing's fixed category.

Pages start at zero and trust API `last`. Duplicate/concurrent pages are blocked, duplicate IDs are excluded, and load-more failure preserves content. Mocked tests cover stopped/unreachable backend behavior, invalid data, 400/404/500, timeout, empty states, retry, and failed images without changing database data.

USB development uses `adb reverse tcp:8080 tcp:8080` and `flutter run -d R5CX32F8CJB --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1`. Emulator uses `10.0.2.2`; LAN requires firewall/address setup; production must use HTTPS. Run `dart format .`, `flutter pub get`, `flutter analyze`, `flutter test`, backend Maven tests, and `flutter build apk --debug` directly from `E:\Dart_flutter\flutter_project\tech_smart_shop`.

Known model limits: active status doubles as online visibility, stock aggregates warehouses, variations inherit product stock, and search uses LIKE. Authentication, cart, wishlist, checkout, orders, payments, reviews, promotions, and Phase 4 remain deferred.
