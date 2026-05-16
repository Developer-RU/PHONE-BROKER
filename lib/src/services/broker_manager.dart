import 'package:flutter/foundation.dart';

import '../models/broker_models.dart';
import 'log_manager.dart';
import 'mqtt_broker.dart';
import 'network_manager.dart';
import 'storage_manager.dart';

/// Owns broker configurations, runtime states, and embedded broker instances.
class BrokerManager extends ChangeNotifier {
  /// Creates a broker manager with required service dependencies.
  BrokerManager({
    required StorageManager storageManager,
    required NetworkManager networkManager,
    required LogManager logManager,
  }) : _storageManager = storageManager,
       _networkManager = networkManager,
       _logManager = logManager;

  final StorageManager _storageManager;
  final NetworkManager _networkManager;
  final LogManager _logManager;

  final Map<String, BrokerConfig> _configs = {};
  final Map<String, BrokerRuntimeState> _runtime = {};
  final Map<String, EmbeddedMqttBroker> _instances = {};

  /// Broker configurations sorted by TCP port.
  List<BrokerConfig> get brokers {
    final items = _configs.values.toList()
      ..sort((left, right) => left.network.port.compareTo(right.network.port));
    return items;
  }

  /// Latest network snapshot from [NetworkManager].
  NetworkSnapshot get networkSnapshot => _networkManager.snapshot;

  /// Loads persisted broker configurations and initializes runtime state.
  Future<void> initialize() async {
    final stored = await _storageManager.loadBrokerConfigs();
    for (final broker in stored) {
      _configs[broker.id] = broker;
      _runtime[broker.id] = const BrokerRuntimeState.stopped();
    }
    notifyListeners();
  }

  /// Returns runtime state for a broker, defaulting to stopped.
  BrokerRuntimeState runtimeFor(String brokerId) {
    return _runtime[brokerId] ?? const BrokerRuntimeState.stopped();
  }

  /// Returns broker configuration by identifier, or `null` when absent.
  BrokerConfig? brokerById(String brokerId) => _configs[brokerId];

  /// Adds a new broker configuration and persists it.
  Future<void> createBroker(BrokerConfig config) async {
    _configs[config.id] = config;
    _runtime[config.id] = const BrokerRuntimeState.stopped();
    await _storageManager.saveBrokerConfig(config);
    notifyListeners();
  }

  /// Updates an existing broker and restarts it if it was running.
  Future<void> updateBroker(BrokerConfig config) async {
    final previous = _configs[config.id];
    if (previous == null) {
      return;
    }

    final runtime = runtimeFor(config.id);
    final wasRunning =
        runtime.status == BrokerStatus.running ||
        runtime.status == BrokerStatus.starting;
    if (wasRunning) {
      await stopBroker(config.id, reason: 'Applying updated broker settings.');
    }

    _configs[config.id] = config;
    await _storageManager.saveBrokerConfig(config);
    notifyListeners();

    if (wasRunning) {
      await startBroker(config.id);
    }
  }

  /// Clones a broker with a new identifier and next available port.
  Future<void> duplicateBroker(String brokerId) async {
    final existing = _configs[brokerId];
    if (existing == null) {
      return;
    }
    final duplicated = existing.duplicate(
      id: _newId(),
      port: nextAvailablePort(startingFrom: existing.network.port + 1),
    );
    await createBroker(duplicated);
  }

  /// Stops, removes, and deletes a broker from persistent storage.
  Future<void> deleteBroker(String brokerId) async {
    await stopBroker(brokerId, reason: 'Broker deleted.');
    _instances.remove(brokerId);
    _configs.remove(brokerId);
    _runtime.remove(brokerId);
    await _storageManager.deleteBrokerConfig(brokerId);
    notifyListeners();
  }

  /// Starts the embedded broker instance for the given configuration.
  Future<void> startBroker(String brokerId) async {
    final config = _configs[brokerId];
    if (config == null) {
      return;
    }

    final instance = _instances.putIfAbsent(
      brokerId,
      () => EmbeddedMqttBroker(
        config: config,
        logManager: _logManager,
        onStateChanged: (state) {
          _runtime[brokerId] = state;
          notifyListeners();
        },
      ),
    );
    await instance.start();
  }

  /// Stops a running broker instance and marks state as stopped.
  Future<void> stopBroker(
    String brokerId, {
    String reason = 'Stopped by user.',
  }) async {
    final instance = _instances.remove(brokerId);
    if (instance == null) {
      _runtime[brokerId] = const BrokerRuntimeState.stopped();
      notifyListeners();
      return;
    }
    await instance.stop(reason: reason);
    await instance.dispose();
  }

  /// Restarts a broker by stop/start sequence.
  Future<void> restartBroker(String brokerId) async {
    await stopBroker(brokerId, reason: 'Restarting broker.');
    await startBroker(brokerId);
  }

  /// Imports broker configs while normalizing conflicting IDs and ports.
  Future<void> importConfigs(List<BrokerConfig> configs) async {
    for (final imported in configs) {
      final normalized = imported.copyWith(
        id: _configs.containsKey(imported.id) ? _newId() : imported.id,
        network: imported.network.copyWith(
          port: portInUse(imported.network.port)
              ? nextAvailablePort(startingFrom: imported.network.port + 1)
              : imported.network.port,
        ),
      );
      await createBroker(normalized);
    }
  }

  /// Attempts to restore expected running brokers after app wake.
  Future<void> recoverAfterWake() async {
    for (final broker in brokers) {
      final runtime = runtimeFor(broker.id);
      final shouldBeRunning =
          broker.automation.autoStart ||
          runtime.status == BrokerStatus.running ||
          runtime.status == BrokerStatus.starting;
      if (shouldBeRunning && !_instances.containsKey(broker.id)) {
        await startBroker(broker.id);
      }
    }
  }

  /// Returns `true` if any broker already uses the specified port.
  bool portInUse(int port) {
    return brokers.any((broker) => broker.network.port == port);
  }

  /// Finds the next free port starting from [startingFrom].
  int nextAvailablePort({int startingFrom = 1883}) {
    var port = startingFrom;
    while (portInUse(port)) {
      port += 1;
    }
    return port;
  }

  /// Returns consolidated diagnostics for all brokers and engines.
  List<Map<String, dynamic>> diagnostics() {
    return brokers
        .map(
          (broker) => {
            'config': broker.toJson(),
            'runtime': {
              'status': runtimeFor(broker.id).status.name,
              'connectedClients': runtimeFor(broker.id).connectedClients,
              'lastActivityAt': runtimeFor(
                broker.id,
              ).lastActivityAt?.toIso8601String(),
              'errorMessage': runtimeFor(broker.id).errorMessage,
            },
            'network': {
              'mode': networkSnapshot.mode.label,
              'localAddresses': networkSnapshot.localAddresses,
              'publicAddress': networkSnapshot.publicAddress,
              'wifiName': networkSnapshot.wifiName,
            },
            'engine': _instances[broker.id]?.diagnostics,
          },
        )
        .toList();
  }

        /// Creates a unique broker ID.
  String newBrokerId() => _newId();

        /// Creates a new draft broker with optional default log limit.
  BrokerConfig newDraftBroker({int? defaultMaxLogEntries}) {
    final draft = BrokerConfig.draft(id: _newId(), port: nextAvailablePort());
    if (defaultMaxLogEntries == null) {
      return draft;
    }
    return draft.copyWith(
      logging: draft.logging.copyWith(maxEntries: defaultMaxLogEntries),
    );
  }

  /// Applies an upper log-entry limit to all broker configs.
  Future<void> applyGlobalLogLimit(int maxEntries) async {
    final updatedConfigs = brokers.map((config) {
      final limited = config.logging.maxEntries > maxEntries
          ? maxEntries
          : config.logging.maxEntries;
      return config.copyWith(logging: config.logging.copyWith(maxEntries: limited));
    }).toList();

    for (final config in updatedConfigs) {
      _configs[config.id] = config;
      await _storageManager.saveBrokerConfig(config);
    }
    notifyListeners();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
