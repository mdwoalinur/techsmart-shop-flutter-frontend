# 04 - API Environment and Physical Device

## API URL choices

```text
Android emulator: http://10.0.2.2:8080/api/mobile/v1
USB phone with ADB reverse: http://127.0.0.1:8080/api/mobile/v1
Wi-Fi phone: http://<PC_LAN_IP>:8080/api/mobile/v1
Production: https://<production-domain>/api/mobile/v1
```

Example: `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/api/mobile/v1`. No current mobile endpoint exists, so Phase 1.1 did not call the backend.

The main Android manifest has Internet permission. Only the debug manifest permits cleartext traffic; release configuration does not globally enable HTTP. Production must use HTTPS.

## Verified device workflow

```cmd
adb devices
flutter devices
adb reverse tcp:8080 tcp:8080
adb reverse --list
flutter run -d R5CX32F8CJB --no-resident
adb reverse --remove tcp:8080
```

The device appeared as `R5CX32F8CJB device`, and Flutter identified it as SM A556E, Android 14/API 34. ADB reverse returned `8080`; its list contained `UsbFfs tcp:8080 tcp:8080`. The rule was removed and a final list was empty.

`flutter run --no-resident` built, installed, launched, and synchronized successfully. The app was force-stopped after validation.

## Troubleshooting

- If unauthorized/offline, restart ADB and accept the phone RSA prompt.
- If Gradle reports `'E:\Dart' is not recognized`, create the documented `T:` alias and build there.
- For emulator access use `10.0.2.2`, not localhost.
- Confirm the backend is listening on port 8080 before using ADB reverse in a future API phase.
