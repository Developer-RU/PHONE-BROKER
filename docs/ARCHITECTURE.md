# Architecture

## Overview

PHONE BROKER is a Flutter iOS application that manages multiple embedded MQTT broker instances in-process.

The app has three main layers:

- Presentation layer: screens/widgets in `lib/src/screens` and `lib/src/widgets`
- Application/service layer: service orchestration and business logic in `lib/src/services`
- Persistence/runtime layer: SQLite-backed storage and TCP socket-based MQTT runtime

## Startup Flow

1. `main.dart` initializes Flutter and error handlers.
2. `AppServices.bootstrapWithProgress()` initializes long-lived managers.
3. The UI starts with a splash screen and then loads the dashboard.
4. Broker configurations are restored from local storage.

## Core Components

- `StorageManager`: SQLite persistence (`brokers`, `app_settings` tables)
- `SettingsManager`: global app defaults and localization settings
- `NetworkManager`: network snapshot data and diagnostics inputs
- `LogManager`: in-memory log retention and export payload generation
- `BrokerManager`: broker CRUD lifecycle, runtime state, and orchestration
- `EmbeddedMqttBroker`: low-level MQTT packet handling and TCP socket runtime
- `ImportExportService`: JSON config import/export and log exports
- `BackgroundServiceManager`: lifecycle hooks and wake/recovery behavior

## Data Flow

1. UI actions dispatch commands to `BrokerManager`.
2. `BrokerManager` updates storage through `StorageManager`.
3. `BrokerManager` starts/stops `EmbeddedMqttBroker` instances.
4. Runtime state changes are propagated via `ChangeNotifier`.
5. UI rebuilds through `provider` subscriptions.

## Runtime and Lifecycle Constraints

- Broker sockets run inside the app process.
- iOS background restrictions can pause or terminate socket activity.
- Recovery logic attempts to restore expected broker state after resume.

## Reliability Considerations

- App bootstrap timeout prevents hanging initialization.
- Database initialization includes corruption fallback path.
- Runtime state is explicit (`stopped`, `starting`, `running`, `error`).
- Broker updates restart running instances to apply new settings safely.
