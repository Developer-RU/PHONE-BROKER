import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../services/broker_manager.dart';
import '../services/settings_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsManager>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('language'), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: settings.languageCode,
                    items: const [
                      'system',
                      'en',
                      'ru',
                      'es',
                      'fr',
                      'de',
                      'zh',
                      'ar',
                    ].map((code) {
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(l10n.nativeLanguageName(code)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      settings.updateLanguageCode(value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('maxBrokers'), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _StepperTile(
                    value: settings.maxBrokers,
                    min: 1,
                    max: 100,
                    onChanged: settings.updateMaxBrokers,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('messageRetentionHours'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _StepperTile(
                    value: settings.messageRetentionHours,
                    min: 1,
                    max: 24 * 365,
                    onChanged: settings.updateMessageRetentionHours,
                    step: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('maxLogEntries'), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _StepperTile(
                    value: settings.maxLogEntries,
                    min: 50,
                    max: 100000,
                    step: 50,
                    onChanged: (value) async {
                      await settings.updateMaxLogEntries(value);
                      if (!context.mounted) {
                        return;
                      }
                      await context.read<BrokerManager>().applyGlobalLogLimit(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.t('appliesToNewBrokers')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: value <= min ? null : () => onChanged((value - step).clamp(min, max)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Expanded(
          child: Center(
            child: Text(
              '$value',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        IconButton(
          onPressed: value >= max ? null : () => onChanged((value + step).clamp(min, max)),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
