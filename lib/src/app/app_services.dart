import 'dart:async';

import '../services/background_service_manager.dart';
import '../services/broker_manager.dart';
import '../services/import_export_service.dart';
import '../services/log_manager.dart';
import '../services/network_manager.dart';
import '../services/settings_manager.dart';
import '../services/storage_manager.dart';

/// Aggregates long-lived services used across the app.
///
/// This class also contains bootstrap helpers that initialize all dependencies
/// in a safe startup order.
class AppServices {
  AppServices({
    required this.storageManager,
    required this.settingsManager,
    required this.networkManager,
    required this.logManager,
    required this.brokerManager,
    required this.backgroundServiceManager,
    required this.importExportService,
  });

  final StorageManager storageManager;
  final SettingsManager settingsManager;
  final NetworkManager networkManager;
  final LogManager logManager;
  final BrokerManager brokerManager;
  final BackgroundServiceManager backgroundServiceManager;
  final ImportExportService importExportService;

  /// Bootstraps services without progress callbacks.
  static Future<AppServices> bootstrap() async {
    return bootstrapWithProgress();
  }

  /// Bootstraps services and reports startup progress to the caller.
  ///
  /// A global timeout guards against hanging initialization.
  static Future<AppServices> bootstrapWithProgress({
    void Function(double progress, String message)? onProgress,
  }) async {
    return _bootstrapWithProgressImpl(onProgress: onProgress).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw TimeoutException('App bootstrap timed out.');
      },
    );
  }

  /// Internal bootstrap implementation with ordered dependency initialization.
  static Future<AppServices> _bootstrapWithProgressImpl({
    void Function(double progress, String message)? onProgress,
  }) async {
    void report(double progress, String message) {
      onProgress?.call(progress.clamp(0, 1).toDouble(), message);
    }

    report(0.05, 'Preparing local storage');
    final storageManager = StorageManager();
    await storageManager.initialize();

    report(0.28, 'Starting network services');
    final logManager = LogManager();
    final settingsManager = SettingsManager(storageManager: storageManager);
    await settingsManager.initialize();
    final networkManager = NetworkManager();
    await networkManager.initialize();

    report(0.5, 'Preparing broker manager');
    final brokerManager = BrokerManager(
      storageManager: storageManager,
      networkManager: networkManager,
      logManager: logManager,
    );

    // Load stored brokers in background so first screen can appear immediately.
    Future<void>(() async {
      try {
        await brokerManager.initialize();
      } catch (_) {
        // Keep startup resilient even if broker restore fails.
      }
    });

    report(0.72, 'Preparing background recovery');
    final backgroundServiceManager = BackgroundServiceManager(
      brokerManager: brokerManager,
      networkManager: networkManager,
      logManager: logManager,
    );
    await backgroundServiceManager.initialize();

    report(0.9, 'Finalizing import/export tools');
    final importExportService = ImportExportService();

    report(1.0, 'Ready');

    return AppServices(
      storageManager: storageManager,
      settingsManager: settingsManager,
      networkManager: networkManager,
      logManager: logManager,
      brokerManager: brokerManager,
      backgroundServiceManager: backgroundServiceManager,
      importExportService: importExportService,
    );
  }
}
