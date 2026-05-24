# Troubleshooting

## App fails to build/run after dependency updates

```bash
flutter clean
flutter pub get
cd ios
pod deintegrate
pod install
cd ..
flutter run -d <device_id>
```

## Signing issues in Xcode

Verify Team, bundle identifier, and provisioning profile in `Runner` target.

## VM service disconnect warning

Confirm whether app actually launched on device; reconnect tooling if needed.

## Broker unreachable from client

- Ensure broker status is `running`
- Verify client uses correct port
- Ensure client and phone are on the same network
- Check port conflict with another broker

## No reliable background broker uptime

Expected on iOS due to platform lifecycle and background execution limits.
