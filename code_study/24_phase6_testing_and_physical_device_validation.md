# Phase 6 Testing and Physical Device Validation

Baseline before edits: backend 38/38 tests, Flutter 63/63 tests, and Flutter analysis with no issues.

Phase 6 adds backend customer-route security and safe DTO/decimal tests, plus Flutter server model, endpoint, merge payload, DELETE, and authoritative-response parsing tests. Final clean compile/test/package, APK metadata, runtime health, authenticated smoke tests, and Samsung SM A556E verification are recorded in the completion report when executed.

Device procedure uses only `D:\androidSettring\platform-tools-latest-windows\platform-tools\adb.exe`, removes prior reverse rules, reverses `tcp:8080`, and runs with `API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1`. Verification covers guest operations, one-time login merge, persistence, customer isolation, mutations, retry behavior, local Compare, and absence of checkout, exact inventory, buying price, fatal exceptions, overflows, or credential logging.

Phase 6 does not reserve stock, create orders, process payment, or persist Compare. Production database migration remains an operational prerequisite.
