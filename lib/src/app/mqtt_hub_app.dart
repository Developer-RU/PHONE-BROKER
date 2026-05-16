import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../screens/dashboard_screen.dart';
import '../services/settings_manager.dart';

/// Root `MaterialApp` widget with theming and localization configuration.
class MqttHubApp extends StatelessWidget {
  const MqttHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    const background = Color(0xFF0B1015);
    const panel = Color(0xFF151B23);
    const surface = Color(0xFF1E252E);
    const accent = Color(0xFF36C2A0);
    const warning = Color(0xFFE7B35A);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      primary: accent,
      secondary: warning,
      surface: panel,
    );

    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.t('appTitle'),
      debugShowCheckedModeBanner: false,
      locale: settings.languageCode == 'system'
          ? null
          : Locale(settings.languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: background,
        cardTheme: const CardThemeData(
          color: panel,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: Color(0xFF25303C)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surface,
          selectedColor: accent.withValues(alpha: 0.22),
          disabledColor: surface,
          labelStyle: const TextStyle(color: Colors.white),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          side: const BorderSide(color: Color(0xFF2A3541)),
          shape: const StadiumBorder(),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2A3541)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2A3541)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: accent),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
