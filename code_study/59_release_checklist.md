# 59 - Release Checklist

## Green verification required

Backend:

```cmd
.\mvnw.cmd clean test
.\mvnw.cmd clean package
```

Flutter:

```cmd
dart format .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1
```

Release APK:

```cmd
flutter build apk --release --dart-define=API_BASE_URL=<production-api-base-url>
```

Only run the release build for production when real signing is configured. Do not ship a debug-key-signed release APK.

## Runtime log checklist

Check physical/device logs for:

- fatal crash;
- RenderFlex overflow;
- repeated 401/403 loop;
- raw `ApiException` in customer UI;
- token/password/OTP/PIN logging;
- wallet-number logging;
- SQL stack trace;
- internal stock, warehouse, supplier, buying-price leakage.

## Production items pending

- Real Android release keystore and secure signing process.
- Final production application id/package decision.
- Production API base URL and HTTPS certificate configuration.
- Environment-specific backend secrets outside source control.
- Production mail/SMS/OTP delivery configuration.
- Store listing assets, privacy policy, support contact, and versioning policy.
- Optional Play Integrity / app distribution hardening.

## APK output

Debug APK path:

```text
E:\Dart_flutter\flutter_project\tech_smart_shop\build\app\outputs\flutter-apk\app-debug.apk
```

Size is recorded in the final report for the verification run that produced it.

## Final readiness decision

The app is presentation-ready when backend tests/package, Flutter analyze/test/build, data cleanup checks, and Samsung physical smoke are green. It is production-release-ready only after real release signing and production environment configuration are complete.

## Final build artifact - 2026-07-17 21:20:53 +06:00

Debug APK:

`	ext
E:\Dart_flutter\flutter_project\tech_smart_shop\build\app\outputs\flutter-apk\app-debug.apk
`

Size: 177.27 MB.

Final verification passed for backend tests/package and Flutter format/pub/analyze/test/debug build. Production release signing remains pending because no real release keystore is configured.
