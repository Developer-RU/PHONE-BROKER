# PHONE BROKER

[![Release](https://img.shields.io/github/v/release/Developer-RU/PHONE-BROKER?label=release)](https://github.com/Developer-RU/PHONE-BROKER/releases)
[![License: MIT](https://img.shields.io/github/license/Developer-RU/PHONE-BROKER)](https://github.com/Developer-RU/PHONE-BROKER/blob/main/LICENSE)
[![Platform: iOS](https://img.shields.io/badge/platform-iOS-blue)](https://developer.apple.com/ios/)
[![Flutter](https://img.shields.io/badge/flutter-3.x-02569B?logo=flutter)](https://flutter.dev)

PHONE BROKER is an iOS Flutter application that runs one or more embedded MQTT brokers directly on an iPhone.

It is designed for local IoT testing, demos, and diagnostics when you need a portable broker endpoint without external server infrastructure.

## Highlights

- Run multiple broker instances on independent ports.
- Start, stop, restart, duplicate, and delete broker profiles.
- Inspect runtime state, connected clients, and packet-level logs.
- Import and export broker configurations as JSON.
- Export broker logs for diagnostics and support.
- Use built-in network diagnostics (local/public IP, Wi-Fi metadata).
- Configure app language and global defaults for broker creation.

## Screenshots

<p align="center">
  <img src="docs/screenshots/brokers.png" width="19%" alt="Brokers screen" />
  <img src="docs/screenshots/settings.png" width="19%" alt="Settings screen" />
  <img src="docs/screenshots/debug.png" width="19%" alt="Debug screen" />
  <img src="docs/screenshots/broker-settings.png" width="19%" alt="Broker settings screen" />
  <img src="docs/screenshots/import-export.png" width="19%" alt="Import and export screen" />
</p>

## Repository Structure

- `lib/`: Flutter/Dart application source.
- `ios/`: iOS host app, Xcode project/workspace, CocoaPods integration.
- `assets/`: App images and visual resources.
- `docs/`: Project documentation, architecture notes, and generated API docs.
- `test/`: Widget and future test suites.

## Requirements

1. macOS (recent stable version)
2. Xcode (recent stable version)
3. Flutter SDK (stable channel)
4. CocoaPods (`pod` CLI available)

## Quick Start

From repository root:

```bash
flutter pub get
cd ios
pod install
cd ..
flutter run -d <device_id>
```

## Build and Run

Run in debug:

```bash
flutter run -d <device_id>
```

Run in profile:

```bash
flutter run --profile -d <device_id>
```

Run in release:

```bash
flutter run --release -d <device_id>
```

Build iOS debug without signing:

```bash
flutter build ios --debug --no-codesign
```

Build iOS release:

```bash
flutter build ios --release
```

## Running in Xcode

1. Open `ios/Runner.xcworkspace`.
2. Select the `Runner` target.
3. Configure `Signing & Capabilities`.
4. Select simulator or physical iPhone.
5. Run using `Product -> Run`.

## Operational Notes

- The app is intended for local/edge usage.
- iOS background policies may suspend long-lived socket activity.
- Wireless debugging can be less reliable than USB deployment.
- Startup is protected by timeout and storage recovery safeguards.

## Documentation Index

- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)
- [Support Guide](SUPPORT.md)
- [Changelog](CHANGELOG.md)
- [Development Guide](docs/DEVELOPMENT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Release Process](docs/RELEASE_PROCESS.md)
- [Code API Reference](docs/CODE_API_REFERENCE.md)

## GitHub Wiki

Wiki source pages are included in this repository under `wiki/`:

- `wiki/Home.md`
- `wiki/Getting-Started.md`
- `wiki/Architecture.md`
- `wiki/Troubleshooting.md`
- `wiki/FAQ.md`
- `wiki/Release-Process.md`

You can copy these pages into the GitHub Wiki repository (`PHONE-BROKER.wiki.git`) to publish them.

## Quality Checks

Static analysis:

```bash
flutter analyze
```

Tests:

```bash
flutter test
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
