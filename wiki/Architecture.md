# Architecture

PHONE BROKER follows a service-oriented Flutter architecture.

## Main Layers

- UI layer (`screens`, `widgets`)
- Service layer (`BrokerManager`, `NetworkManager`, `SettingsManager`, `LogManager`, `ImportExportService`)
- Runtime/persistence layer (`EmbeddedMqttBroker`, `StorageManager`)

## Bootstrap Sequence

1. Flutter app starts.
2. `AppServices.bootstrapWithProgress()` initializes dependencies.
3. Stored broker configs are loaded.
4. Dashboard and broker controls become available.

## Runtime Model

- Each broker profile maps to one embedded broker runtime instance.
- Runtime state is exposed to UI via `provider` + `ChangeNotifier`.
- Logs are collected and can be exported for analysis.

## Constraints

- Socket runtimes are limited by iOS lifecycle/background restrictions.
