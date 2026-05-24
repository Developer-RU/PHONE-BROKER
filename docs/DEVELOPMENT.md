# Development Guide

## Prerequisites

- macOS
- Xcode
- Flutter SDK (stable)
- CocoaPods

## Initial Setup

```bash
flutter pub get
cd ios
pod install
cd ..
```

## Run the App

```bash
flutter run -d <device_id>
```

## Run with Xcode

1. Open `ios/Runner.xcworkspace`.
2. Configure signing for `Runner` target.
3. Select a simulator/device.
4. Run from Xcode.

## Quality Gates

Run before every pull request:

```bash
flutter analyze
flutter test
```

## iOS Dependency Recovery

Use when iOS build metadata is out of sync:

```bash
flutter clean
flutter pub get
cd ios
pod deintegrate
pod install
cd ..
flutter run -d <device_id>
```

## Recommended PR Scope

- Keep each PR focused on one change set.
- Include docs updates when user-visible behavior changes.
- Include screenshots for UI modifications.

## Localization Notes

Supported locales are configured in `app_localizations.dart`.

When adding user-facing strings:

- Keep keys consistent and descriptive.
- Update locale mappings for all supported languages where possible.
