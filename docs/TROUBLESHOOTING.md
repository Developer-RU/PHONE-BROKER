# Troubleshooting

## App Does Not Start After Dependency Changes

Run:

```bash
flutter clean
flutter pub get
cd ios
pod deintegrate
pod install
cd ..
flutter run -d <device_id>
```

## Build Fails in Xcode with Signing Errors

Check in `ios/Runner.xcworkspace`:

- Correct Apple Team selected
- Valid Bundle Identifier
- Provisioning profile available for selected device

## Flutter VM Service Disconnects During Launch

On iOS, transport disconnection does not always mean app crash.

Verify whether the app is running on device. If it is, reconnect from Flutter tooling or restart with USB.

## Broker Does Not Accept Client Connection

Validate:

- Broker is in `running` state
- Correct port is used by client
- Client is on same reachable network
- No local port collision with another broker

## No Background Connectivity

Expected behavior on iOS:

- Long-lived socket activity may be suspended in background/locked states.
- Keep testing scenarios foregrounded when continuous connectivity is required.

## Import Fails for Broker Config JSON

Check that JSON payload structure matches current app model fields.

If IDs or ports conflict, the app will normalize them during import (new ID / next free port).

## Logs Grow Too Fast

Use app settings to reduce global max log entries for newly created brokers.

For existing brokers, adjust limits and clear log history when needed.
