# Neck Alert

A cross-platform (Android + iOS) Flutter app that uses the accelerometer to
detect when your phone is being held in a near-horizontal position — a strong
indicator that your neck is bent forward while looking at the screen — and
alerts you if you stay in that posture for too long.

## Features

- Continuous tilt monitoring via accelerometer (low-rate sampling for battery)
- Configurable threshold (default 70 s) and tilt window (default 10°–50°)
- Vibration + sound alerts, with selectable tones or vibrate-only
- **Floating bubble overlay** (Android only) that turns green → amber → red
- History log of every alarm (timestamp, sustained seconds, average tilt)
- Analytics page with a bar chart of alarms per day, plus improvement insights
- Foreground service on Android: keeps running even when other apps are open
- iOS: monitoring runs while the app is foreground; floating bubble is
  permanently disabled (Apple's sandbox forbids drawing over other apps)
- Beautiful gradient + image background, polished Material 3 UI

## Project layout

```
neck_alert/
├── pubspec.yaml
├── lib/
│   ├── main.dart              # entry + overlay isolate entry
│   ├── app.dart               # routes + theme
│   ├── models/
│   │   ├── app_settings.dart
│   │   └── alarm_event.dart
│   ├── services/
│   │   ├── tilt_monitor_service.dart   # core background logic
│   │   ├── alarm_service.dart          # vibration + sound
│   │   ├── settings_service.dart       # SharedPreferences
│   │   └── history_service.dart        # sqflite
│   ├── widgets/
│   │   ├── overlay_bubble.dart         # floating bubble UI
│   │   └── scaffold_background.dart    # gradient + image bg
│   └── screens/
│       ├── home_screen.dart
│       ├── instructions_screen.dart
│       ├── settings_screen.dart
│       ├── analytics_screen.dart
│       └── history_screen.dart
├── android/app/src/main/AndroidManifest.xml
├── ios/Runner/Info.plist.additions.xml  (merge into Info.plist)
└── assets/
    ├── sounds/                # beep.mp3, chime.mp3, gong.mp3
    └── images/                # background.jpg
```

## Setup

You need the Flutter SDK installed (≥ 3.19). From this directory:

```bash
# 1. Generate platform scaffolding (creates android/, ios/ folders & MainActivity)
flutter create . --org com.you.neckalert --project-name neck_alert

# 2. Overwrite the generated AndroidManifest.xml with the one in this repo
#    (it includes the permissions and services this app needs).

# 3. Merge the keys from ios/Runner/Info.plist.additions.xml into
#    ios/Runner/Info.plist (NSMotionUsageDescription, UIBackgroundModes, etc).

# 4. Drop your audio files into assets/sounds/ and a background.jpg into
#    assets/images/ (see READMEs in those folders).

# 5. Fetch dependencies
flutter pub get

# 6. Run on a connected device
flutter run
```

> Note: the accelerometer does not work in emulators/simulators (or only with
> fake values). Test on a real phone.

## How tilt is calculated

The app reads the gravity vector from the accelerometer (`x, y, z` in m/s²).
The "tilt from horizontal" is defined as the angle between the phone's
screen-normal axis (the Z axis) and gravity:

```
tilt = arccos(|z| / |g|)
```

- Phone flat on a table (face up or down) → `tilt ≈ 0°`
- Phone held upright (portrait or landscape, screen vertical) → `tilt ≈ 90°`
- Phone tilted at ~30° while you look down at it → `tilt ≈ 30°`

By default, only `10° ≤ tilt ≤ 50°` counts as "neck bent". Below 10° is
treated as "lying on a table". Above 50° is treated as "upright, fine".

## Battery impact

- Sampling rate: ~5 Hz (vs the default 100 Hz) — about 20× less CPU
- Optional: pause monitoring when the screen is off (recommended; enabled by
  default)
- Foreground service is far more efficient than periodic wakeup polling

Expected impact: ~2–5%/day extra with screen-off pausing on; ~8–15% without.

## Platform differences

| Feature                         | Android | iOS                          |
|---------------------------------|---------|------------------------------|
| Background monitoring (other app open) | ✅ foreground service | ⚠️ limited; best-effort only |
| Floating bubble over other apps | ✅      | ❌ blocked by Apple sandbox  |
| Custom vibration patterns       | ✅      | ✅ (system haptics)          |
| Custom alert tones              | ✅      | ✅                           |
| History + analytics             | ✅      | ✅                           |

## License

MIT
