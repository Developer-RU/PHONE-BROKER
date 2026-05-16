import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../services/broker_manager.dart';
import '../services/import_export_service.dart';
import '../services/log_manager.dart';

/// UI for importing/exporting broker configurations and logs.
class ImportExportScreen extends StatelessWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final manager = context.watch<BrokerManager>();
    final brokers = manager.brokers;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('jsonImportExport'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.tonal(
                      onPressed: brokers.isEmpty
                          ? null
                          : () => context
                                .read<ImportExportService>()
                                .exportAllBrokers(brokers),
                      child: Text(l10n.t('exportAllBrokers')),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _importConfigs(context),
                      child: Text(l10n.t('importBrokers')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('exportsShareDescription'),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final broker in brokers) ...[
          Card(
            child: ListTile(
              title: Text(broker.name),
              subtitle: Text('${l10n.t('port')} ${broker.network.port}'),
              trailing: Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: l10n.t('exportConfig'),
                    onPressed: () => context
                        .read<ImportExportService>()
                        .exportBrokerConfig(broker),
                    icon: const Icon(Icons.settings_ethernet_rounded),
                  ),
                  IconButton(
                    tooltip: l10n.t('exportLogs'),
                    onPressed: () {
                      final payload = context.read<LogManager>().exportPayload(
                        broker,
                        context.read<LogManager>().logsFor(broker.id).toList(),
                      );
                      context.read<ImportExportService>().exportBrokerLogs(
                        config: broker,
                        payload: payload,
                      );
                    },
                    icon: const Icon(Icons.article_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// Imports broker configurations and shows completion feedback.
  Future<void> _importConfigs(BuildContext context) async {
    final l10n = context.l10n;
    final service = context.read<ImportExportService>();
    final configs = await service.importBrokerConfigs();
    if (!context.mounted) {
      return;
    }
    await context.read<BrokerManager>().importConfigs(configs);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.importedConfigs(configs.length)),
      ),
    );
  }
}
