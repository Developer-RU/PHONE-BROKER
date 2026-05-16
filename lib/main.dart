import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'src/app/app_services.dart';
import 'src/app/mqtt_hub_app.dart';
import 'src/app/startup_splash_screen.dart';
import 'src/services/background_service_manager.dart';
import 'src/services/broker_manager.dart';
import 'src/services/import_export_service.dart';
import 'src/services/log_manager.dart';
import 'src/services/network_manager.dart';
import 'src/services/settings_manager.dart';

/// Entry point for the app.
///
/// Sets up global Flutter and platform error handlers before launching the
/// widget tree.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'app bootstrap',
        context: ErrorDescription('Unhandled asynchronous error'),
      ),
    );
    return true;
  };

  runApp(const AppBootstrapper());
}

/// Initializes application services and renders either the startup splash,
/// an initialization error screen, or the main app.
class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  Future<AppServices>? _bootstrapFuture;
  double _startupProgress = 0;
  String _startupMessage = 'Loading...';

  /// Applies a non-linear mapping to smooth visual startup progress.
  double _displayProgress(double rawProgress) {
    final p = rawProgress.clamp(0.0, 1.0);
    if (p <= 0.5) {
      // Reach about 70% quickly to improve perceived startup responsiveness.
      return p * 1.4;
    }
    // Then progress more gradually toward 100%.
    return 0.7 + ((p - 0.5) * 0.6);
  }

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _startBootstrap();
  }

  /// Starts asynchronous service bootstrap and updates splash status text.
  Future<AppServices> _startBootstrap() {
    return AppServices.bootstrapWithProgress(
      onProgress: (progress, message) {
        if (!mounted) {
          return;
        }
        setState(() {
          _startupProgress = _displayProgress(progress);
          _startupMessage = message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return StartupSplashScreen(
            progress: _startupProgress,
            statusMessage: _startupMessage,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF0B1015),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Failed to initialize app services.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _startupProgress = 0;
                            _startupMessage = 'Loading...';
                            _bootstrapFuture = _startBootstrap();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final services = snapshot.data!;

        return MultiProvider(
          providers: [
            Provider<AppServices>.value(value: services),
            ChangeNotifierProvider<NetworkManager>.value(
              value: services.networkManager,
            ),
            ChangeNotifierProvider<SettingsManager>.value(
              value: services.settingsManager,
            ),
            ChangeNotifierProvider<LogManager>.value(value: services.logManager),
            ChangeNotifierProvider<BrokerManager>.value(
              value: services.brokerManager,
            ),
            ChangeNotifierProvider<BackgroundServiceManager>.value(
              value: services.backgroundServiceManager,
            ),
            Provider<ImportExportService>.value(
              value: services.importExportService,
            ),
          ],
          child: const MqttHubApp(),
        );
      },
    );
  }
}
