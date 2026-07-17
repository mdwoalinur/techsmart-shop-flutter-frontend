# TechSmart Shop Code Study

TechSmart Shop is the customer-facing Android/iOS Flutter frontend for the existing TradeMaster Spring Boot business system. The Angular application remains the internal management frontend.

Phases 1 and 2 are complete. Phase 3 integrates the public catalog in Flutter with Provider state, real Home/Categories/List/Search/Detail screens, sorting, filtering, pagination, and customer-safe fields.

## Documents

- [01 - Project inspection and baseline](01_project_inspection_and_baseline.md)
- [02 - Flutter foundation](02_flutter_foundation.md)
- [03 - Theme and navigation](03_theme_and_navigation.md)
- [04 - API environment and physical device](04_api_environment_and_physical_device.md)
- [05 - Branding, Android build, and device validation](05_branding_android_build_and_device_validation.md)
- [06 - Mobile API foundation and public catalog](06_mobile_api_foundation_and_public_catalog.md)
- [07 - Flutter catalog models and services](07_flutter_catalog_models_and_services.md)
- [08 - Catalog providers and state management](08_catalog_providers_and_state_management.md)
- [09 - Home, categories, products, and search](09_home_categories_products_and_search.md)
- [10 - Product details, filters, and pagination](10_product_details_filters_and_pagination.md)

## Verified development command

Run Flutter commands directly from the active workspace path:

```cmd
cd /d E:\Dart_flutter\flutter_project\tech_smart_shop
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The retired `T:` alias is no longer required.

## Phase 4

- [11 - Phase 4 baseline and product detail design](11_phase4_baseline_and_product_detail_design.md)
- [12 - Session Cart and money handling](12_session_cart_and_money_handling.md)
- [13 - Session Wishlist and comparison](13_session_wishlist_and_comparison.md)
- [14 - Phase 4 testing and device validation](14_phase4_testing_and_device_validation.md)


## Phase 5

- [15 - Customer authentication backend architecture](15_customer_auth_backend_architecture.md)
- [16 - Email OTP, refresh tokens, and password recovery](16_email_otp_refresh_tokens_and_password_recovery.md)
- [17 - Flutter auth models, services, and secure storage](17_flutter_auth_models_services_and_secure_storage.md)
- [18 - AuthProvider, screens, and session restoration](18_auth_provider_screens_and_session_restoration.md)
- [19 - Phase 5 testing, security, and physical device validation](19_phase5_testing_security_and_physical_device_validation.md)


## Phase 6 - Persistent Customer Cart and Wishlist

- [20 - Persistent Cart Backend Architecture](20_persistent_cart_backend_architecture.md)
- [21 - Cart Merge, Validation, and Money](21_cart_merge_validation_and_money.md)
- [22 - Persistent Wishlist and Auth Integration](22_persistent_wishlist_and_auth_integration.md)
- [23 - Flutter Cart/Wishlist Sync and State](23_flutter_cart_wishlist_sync_and_state.md)
- [24 - Phase 6 Testing and Physical Device Validation](24_phase6_testing_and_physical_device_validation.md)

## Phase 7 - Address, Delivery, and Secure Checkout

- [25 - Customer Address Backend and Security](25_customer_address_backend_and_security.md)
- [26 - Delivery Methods and Checkout Review](26_delivery_methods_and_checkout_review.md)
- [27 - Order Submission Idempotency and Snapshots](27_order_submission_idempotency_and_snapshots.md)
- [28 - Flutter Address and Checkout State](28_flutter_address_and_checkout_state.md)
- [29 - Phase 7 Testing and Physical Device Validation](29_phase7_testing_and_physical_device_validation.md)

## Phase 8 - Customer Orders, Cancellation, Returns, and Documents

- [30 - Order History, Detail, and Ownership](30_order_history_detail_and_ownership.md)
- [31 - Order Timeline and Status Domains](31_order_timeline_and_status_domains.md)
- [32 - Cancellation Request and Idempotency](32_cancellation_request_and_idempotency.md)
- [33 - Return Request Foundation and Eligibility](33_return_request_foundation_and_eligibility.md)
- [34 - Order Document and Flutter Order State](34_order_document_and_flutter_order_state.md)
- [35 - Phase 8 Testing and Physical Device Validation](35_phase8_testing_and_physical_device_validation.md)

## Phase 8 continuation note

The multi-item return UI continuation is implemented and covered by tests. Automated verification is green: backend 56/56, Flutter 85/85, analyze clean, debug APK builds. Physical Samsung connectivity, ADB reverse, backend health, app install/launch, and public API traffic were verified on SM A556E `R5CX32F8CJB`. Full authenticated Customer A/B physical validation still requires safe test credentials or an explicit local test fixture; no secrets are documented here.
## Phase 9 - Hybrid Payment Workflow

- [36 - Payment Domain and Status Separation](36_payment_domain_and_status_separation.md)
- [37 - Payment Attempts, Gateway Verification, and Idempotency](37_payment_attempts_gateway_verification_and_idempotency.md)
- [38 - Manual Payment Review and COD](38_manual_payment_review_and_cod.md)
- [39 - Accounting Posting, Reconciliation, and Refund Foundation](39_accounting_posting_reconciliation_and_refund_foundation.md)
- [40 - Flutter Payment State and UI](40_flutter_payment_state_and_ui.md)
- [41 - Phase 9 Testing and Physical Device Validation](41_phase9_testing_and_physical_device_validation.md)
- [42 - Bangladesh mobile wallet simulation architecture](42_bangladesh_mobile_wallet_simulation_architecture.md)
- [43 - Mobile wallet provider selection and checkout](43_mobile_wallet_provider_selection_and_checkout.md)
- [44 - Phase 9.1 testing and physical validation](44_phase9_1_testing_and_physical_validation.md)

## Phase 10 - Notifications and Communication

- [45 - Notification domain and templates](45_notification_domain_and_templates.md)
- [46 - Customer notification APIs and security](46_customer_notification_apis_and_security.md)
- [47 - Flutter notification center and badge](47_flutter_notification_center_and_badge.md)
- [48 - Phase 10 testing and physical validation](48_phase10_testing_and_physical_validation.md)

## Phase 11 - Fulfillment, Stock Deduction, COD Collection, and Tracking

- [49 - Fulfillment domain and order lifecycle](49_fulfillment_domain_and_order_lifecycle.md)
- [50 - Stock deduction and COD collection policy](50_stock_deduction_and_cod_collection_policy.md)
- [51 - Customer tracking and delivery events](51_customer_tracking_and_delivery_events.md)
- [52 - Phase 11 testing and physical validation](52_phase11_testing_and_physical_validation.md)
- [53 - Local Phase 11 fixtures and safe demo data](53_local_phase11_fixtures_and_safe_demo_data.md)
## Phase 12 - Reviews, Support, and Help Center

- [54 - Reviews and Rating System](54_reviews_and_rating_system.md)
- [55 - Support Ticket and Help Center](55_support_ticket_and_help_center.md)
- [56 - Phase 12 Testing and Physical Validation](56_phase12_testing_and_physical_validation.md)
## Final Polish, Demo, and Release Preparation

- [57 - Final Polish and Release Preparation](57_final_polish_and_release_preparation.md)
- [58 - Final Demo Script](58_final_demo_script.md)
- [59 - Release Checklist](59_release_checklist.md)

