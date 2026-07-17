# 58 - Final Demo Script

Use this script for a clean TechSmart Shop presentation. Keep the backend running locally and use ADB reverse for the Samsung device.

## Setup

```cmd
cd /d E:\Dart_flutter\flutter_project\trademaster_ims
.\mvnw.cmd clean package
java -jar target\trademaster_ims-0.0.1-SNAPSHOT.jar

cd /d E:\Dart_flutter\flutter_project\tech_smart_shop
adb reverse tcp:8080 tcp:8080
flutter run -d R5CX32F8CJB --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1
```

## Demo flow

1. Launch the app and show the TechSmart Shop branding.
2. Log in as a prepared local customer account.
3. Show Home: real categories, latest products, and customer-safe product cards.
4. Open Categories and then a category product grid.
5. Open Offers and show backend-driven offer cards.
6. Open an offer and show only products included in that offer.
7. Open Product Detail and point out price, options, review summary, and customer reviews.
8. Add a product to Cart and show server/customer-safe messaging.
9. Open Checkout Review, address selection, delivery method, and backend-authoritative totals.
10. Walk through Payment status / mobile wallet simulation disclosure if using a presentation payment flow.
11. Open My Orders and Order Detail.
12. Show tracking/fulfillment timeline, COD/payment status, and customer-visible delivery updates.
13. Open Notifications and use a notification action such as View Order when available.
14. Open delivered order Write Review and submit/view a product review if the fixture order supports it.
15. Open My Reviews and show review history.
16. Open Help & Support, create/view/reply/close a support ticket if prepared test data is available.
17. Open FAQ, search for a topic, and open FAQ detail.
18. Open Profile, show customer-safe profile fields and profile photo/avatar behavior.
19. Log out.
20. Log in as Customer B and show Customer A orders/tickets/reviews are not visible.

## Presenter notes

- Do not enter or narrate real passwords, OTPs, wallet PINs, or tokens.
- Use prepared disposable local accounts only.
- If live email/SMS is not configured, explain that OTP delivery is represented by backend tests/local fixtures.
- If production release is discussed, mention that real release signing and production API configuration are pending.
