# 02 - Flutter Foundation

## Startup and state flow

`main.dart` initializes Flutter and runs `TechSmartShopApp`. `app.dart` registers `NavigationProvider`, applies the Material 3 theme, sets the title, and opens `MainNavigationShell`. The shell uses an `IndexedStack` so future screen state can survive destination changes.

`NavigationProvider` begins at Home and exposes a Home-reselection counter for future scroll-to-top behavior. No empty feature providers were created.

## Service foundation

`AppEnvironment` reads `API_BASE_URL` from `--dart-define`, validates absolute HTTP/HTTPS URLs, and defaults to the ADB-reverse address `http://127.0.0.1:8080/api/mobile/v1`.

`ApiClient` centralizes the base URI, JSON headers, a 20-second timeout, safe JSON decoding, injectable `http.Client`, and structured network, timeout, unauthorized, server, invalid-response, and request errors. Debug logging excludes bodies, headers, tokens, and secrets. It defines no business endpoint and performs no startup request.

## Branding integration

The approved runtime files are registered in `pubspec.yaml`:

```text
assets/branding/techsmart_shop_logo.png
assets/branding/techsmart_shop_app_icon.png
```

Home uses `Image.asset` with `BoxFit.contain`, preserving the logo's 1536×1024 canvas without cropping, recoloring, or distortion. A text/icon fallback is supplied through `errorBuilder`. The widget test verifies the keyed logo widget.

## Dependencies

- `provider 6.1.5+1` for minimal ChangeNotifier state.
- `http 1.6.0` for testable cross-platform HTTP primitives.
- `flutter_launcher_icons 0.14.4` as a development-only launcher resource generator.

The 11 tests cover root rendering, Material 3/title, logo presence, default Home state, all navigation changes, centered Home return, Cart badge readiness, Provider behavior, environment validation, JSON parsing, URL construction, and authorization error mapping.
