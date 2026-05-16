import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../services/background_service_manager.dart';
import '../services/broker_manager.dart';
import '../services/log_manager.dart';

class AboutDebugScreen extends StatelessWidget {
  const AboutDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final manager = context.watch<BrokerManager>();
    final background = context.watch<BackgroundServiceManager>();
    final diagnostics = manager.diagnostics();
    final rawEntries = manager.brokers
        .expand((broker) => context.read<LogManager>().logsFor(broker.id))
        .where((entry) => entry.topic == '__raw__')
        .take(20)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('about'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(l10n.t('aboutText')),
                const SizedBox(height: 12),
                Text(
                  l10n.t('networkStateWarning'),
                  softWrap: true,
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
                  l10n.t('networkDiagnostics'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  const JsonEncoder.withIndent('  ').convert({
                    'mode': l10n.networkModeLabel(manager.networkSnapshot.mode),
                    'localAddresses': manager.networkSnapshot.localAddresses,
                    'publicAddress': manager.networkSnapshot.publicAddress,
                    'wifiName': manager.networkSnapshot.wifiName,
                    'lastBackgroundAt': background.lastBackgroundAt
                        ?.toIso8601String(),
                  }),
                  style: Theme.of(context).textTheme.bodySmall,
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
                  l10n.t('rawPacketMonitor'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (rawEntries.isEmpty)
                  Text(l10n.t('noRawPackets'))
                else
                  for (final entry in rawEntries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('${entry.message}: ${entry.payload}'),
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
                  l10n.t('internalBrokerState'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  const JsonEncoder.withIndent('  ').convert(diagnostics),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
