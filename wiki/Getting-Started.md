# Getting Started

## Requirements

- macOS
- Xcode
- Flutter SDK (stable)
- CocoaPods

## Setup

```bash
flutter pub get
cd ios
pod install
cd ..
```

## Run

```bash
flutter run -d <device_id>
```

## Run in Xcode

1. Open `ios/Runner.xcworkspace`.
2. Configure signing for `Runner`.
3. Select a device.
4. Run with Product > Run.

## First Broker Checklist

1. Create a broker profile.
2. Start broker.
3. Connect an MQTT client to `<iphone_local_ip>:<broker_port>`.
4. Publish/subscribe test message.
