# 01 - Project Inspection and Baseline

## Relationship and scope

The Flutter app is customer-facing. TradeMaster Spring Boot remains the business-data and rules source, while Angular remains the internal frontend. Phase 1/1.1 did not modify either existing application and did not add mobile business APIs.

The retained Flutter structure is `lib/model`, `lib/provider`, `lib/service`, and `lib/ui`. Phase 1 removed the counter starter and introduced only foundation code.

## Backend read-only findings

The backend uses Spring Boot 4.0.3, Java 17, JPA/MySQL, Spring Security, BCrypt, bearer JWT, mail, and multipart uploads. Current controllers cover authentication, products, categories, inventory, customers, sales, payments, notifications, and internal operations. Current CORS targets Angular at `http://localhost:4200`; most existing APIs require authentication. No `/api/mobile/v1` controller exists and no backend file was changed.

## Phase 1.1 environment

- Flutter 3.41.9 stable; Dart 3.11.5.
- Android SDK and Build-Tools 36.1.0; all Android licenses accepted.
- Android Studio bundled OpenJDK 21.0.10 is used by Flutter/Gradle.
- Samsung SM A556E, device ID `R5CX32F8CJB`, Android 14/API 34 was authorized and connected.
- The remaining Visual Studio warning applies only to Windows desktop development.

## Baseline and final checks

The original Phase 1 baseline analysis and starter test passed. The Maven wrapper has a pre-existing PowerShell null-array defect, but cached Maven 3.9.12 successfully compiled all 189 backend sources.

After Phase 1.1 branding changes:

- `dart format .`: passed, 19 files checked; one edited source was formatted.
- `flutter analyze`: passed with no issues through both original and aliased paths.
- `flutter test`: all 11 tests passed through both paths.
- `flutter build apk --debug` from the original path: failed because Windows split `E:\Dart&flutter` at `&`.
- `flutter build apk --debug -v` from `T:\tech_smart_shop`: passed in about 67 seconds; Gradle reported `BUILD SUCCESSFUL in 1m 2s`.

The path failure is environmental and reproducible. `subst T:` is a drive view of the same files, not a copy or replacement project.
