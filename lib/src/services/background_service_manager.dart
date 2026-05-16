import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/broker_models.dart';
import 'broker_manager.dart';
import 'log_manager.dart';
import 'network_manager.dart';

/// Observes app lifecycle and coordinates broker/network recovery.
class BackgroundServiceManager extends ChangeNotifier
    with WidgetsBindingObserver {
  /// Creates a lifecycle manager with required collaborating services.
  BackgroundServiceManager({
    required BrokerManager brokerManager,
    required NetworkManager networkManager,
    required LogManager logManager,
  }) : _brokerManager = brokerManager,
       _networkManager = networkManager,
       _logManager = logManager;

  final BrokerManager _brokerManager;
  final NetworkManager _networkManager;
  final LogManager _logManager;

  bool _isBackground = false;
  bool _hasHandledFirstResume = false;
  DateTime? _lastBackgroundAt;

  void _runSafe(Future<void> Function() task) {
    unawaited(() async {
      try {
        await task();
      } catch (_) {
        // Lifecycle recovery is best-effort and should not crash app.
      }
    }());
  }

  /// Whether the app is currently in a background lifecycle state.
  bool get isBackground => _isBackground;

  /// Timestamp of the most recent transition to background.
  DateTime? get lastBackgroundAt => _lastBackgroundAt;

  /// User-facing warning about iOS background socket limitations.
  String get warningMessage =>
      'iOS may suspend sockets while the app is backgrounded or the screen is locked. MQTT HUB attempts recovery on wake, but background broker uptime cannot be guaranteed by the OS.';

  /// Registers this manager as a widgets binding observer.
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  /// Handles transitions and triggers best-effort wake recovery.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isBackground = false;
        notifyListeners();
        if (_hasHandledFirstResume) {
          _runSafe(_brokerManager.recoverAfterWake);
          _runSafe(_networkManager.refresh);
        } else {
          _hasHandledFirstResume = true;
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _isBackground = true;
        _lastBackgroundAt = DateTime.now();
        notifyListeners();
        for (final broker in _brokerManager.brokers) {
          _logManager.append(
            broker,
            direction: BrokerLogDirection.system,
            message:
                'App entered background; broker sockets may be suspended by iOS.',
          );
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  /// Unregisters the lifecycle observer.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
