# 56 - Phase 12 Testing and Physical Validation

Phase 12 verification covers backend review/support/help behavior, Flutter state isolation, UI entry points, analyzer health, widget/provider tests, and Android debug build output.

## Backend verification

Required commands from `trademaster_ims`:

```cmd
.\mvnw.cmd test
.\mvnw.cmd clean test
.\mvnw.cmd clean package
```

The expected Phase 12 backend suite is approximately 112 passing tests. The review, support, and help-center tests verify ownership, customer scoping, create/reply/close flows, FAQ visibility, and DTO behavior.

## Flutter verification

Required commands from `tech_smart_shop`:

```cmd
dart format .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1
```

Compact Phase 12 Flutter tests cover:

- review/support/help model parsing
- provider logout isolation
- help search state
- Menu/Profile links for My Reviews, Help & Support, and FAQ

## Physical/device smoke checklist

When an emulator or Samsung device is attached, smoke-test:

- app launches
- product detail review section opens
- delivered order Write Review opens
- Help & Support opens
- FAQ opens
- no crash, overflow, or raw `ApiException` appears to the customer

If no device is attached during automated verification, record that physical smoke was not possible and keep the generated debug APK path for manual installation.
## Samsung physical smoke attempt - 2026-07-17 17:06:39 +06:00

Device target: Samsung SM A556E R5CX32F8CJB.

Result: partial physical smoke only; full authenticated Phase 12 smoke is blocked because the device disconnected from ADB during navigation and did not reappear after an ADB server restart.

Verified before disconnect:

- ADB initially detected R5CX32F8CJB as authorized.
- db reverse tcp:8080 tcp:8080 succeeded and listed UsbFfs tcp:8080 tcp:8080.
- Local backend health returned HTTP 200 at /api/mobile/v1/health.
- lutter run -d R5CX32F8CJB --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1 built, installed, launched, attached DevTools, and loaded the app foreground activity.
- Home screen loaded real backend categories/products/offers; visible product data included real catalog items and no raw API error text.
- Captured Flutter run log showed successful category/product/offers calls before disconnect.
- Runtime log scan after disconnect found no RenderFlex overflow, raw ApiException, repeated 401/403 loop, or token/password/OTP logging in the captured Flutter run output; it did record Lost connection to device.

Not completed because the device disconnected:

- Customer login UI verification.
- Product detail review/rating section verification.
- Delivered order Write Review screen.
- My Reviews screen.
- Help & Support ticket flow.
- FAQ screen/search.
- Review/support notification action navigation.
- Logout customer-owned review/support state isolation.
- Customer A/B cross-account isolation on device.

Next physical attempt should reconnect/unlock the Samsung, confirm db devices -l shows R5CX32F8CJB device, re-run db reverse tcp:8080 tcp:8080, and then continue the remaining authenticated checklist.

