# 05 - Branding, Android Build, and Device Validation

## Branding correction

The files were visually inspected before alteration. The horizontal image contains the TechSmart Shop name and exact tagline; the square image contains the matching TS shopping/electrical mark.

| Original | Corrected | PNG details |
| --- | --- | --- |
| `techsmart_shop_logo.png.png` | `techsmart_shop_logo.png` | 1536×1024, 24-bit RGB |
| `techsmart_shop_app_icon.png.png` | `techsmart_shop_app_icon.png` | 1254×1254, square, 24-bit RGB |

Both runtime paths are registered in `pubspec.yaml`. No replacement art was generated.

`flutter_launcher_icons 0.14.4` generated five Android density icons and the iOS AppIcon set from the approved square source. iOS alpha removal is enabled defensively, although the inspected source is opaque RGB.

## Android build stabilization

The exact original-path command failed in 2.4 seconds:

```text
'E:\Dart' is not recognized as an internal or external command
```

The safe workaround was:

```cmd
subst T: "E:\Dart&flutter\flutter_project"
cd /d T:\tech_smart_shop
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug -v
```

The verbose build passed in 67.2 seconds. Gradle reported 53 actionable tasks and `BUILD SUCCESSFUL in 1m 2s`.

APK verification after the device run:

```text
Path: E:\Dart&flutter\flutter_project\tech_smart_shop\build\app\outputs\flutter-apk\app-debug.apk
Size: 147,120,129 bytes
Last write: 2026-07-01 02:27:33 +06:00
SHA-256: EA5B3A072EF95C3BBDC5453668604917899754505E270C9AA677A404653C1D67
```

The same file was verified through `T:` before the alias was removed.

## Physical validation result

`flutter run -d R5CX32F8CJB --no-resident` completed in 58.4 seconds, including a 25.0-second incremental build and 21.6-second install. MainActivity became the focused window and the process remained alive.

A cold start verified Home initially selected and the approved logo visible. Device-semantic checks verified Categories, Offers, Cart, Menu, and center-Home return. Safe areas and the navigation bar rendered without an observed overflow. Filtered logs contained no fatal exception, `E/flutter`, RenderFlex, or overflow entry.

ADB reverse was added, listed as `UsbFfs tcp:8080 tcp:8080`, removed, and confirmed absent. No backend request was made. The app, Gradle daemon, and temporary alias were stopped/removed afterward.

## Readiness and limitations

Phase 1 is fully verified and ready for Phase 2 planning. Customer authentication, products, categories, cart logic, checkout, orders, payments, notifications, and all `/api/mobile/v1` contracts remain intentionally unimplemented.
