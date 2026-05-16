import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/broker_models.dart';
import '../services/broker_manager.dart';

class BrokerListScreen extends StatelessWidget {
  const BrokerListScreen({
    super.key,
    required this.onOpenBroker,
    required this.onEditBroker,
  });

  final ValueChanged<String> onOpenBroker;
  final ValueChanged<String> onEditBroker;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final manager = context.watch<BrokerManager>();
    final brokers = manager.brokers;
    final snapshot = manager.networkSnapshot;
    final dateFormat = DateFormat('HH:mm:ss');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('networkSnapshot'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      label: l10n.t('mode'),
                      value: l10n.networkModeLabel(snapshot.mode),
                    ),
                    _Badge(
                      label: l10n.t('localIp'),
                      value: snapshot.primaryLocalAddress,
                    ),
                    _Badge(
                      label: l10n.t('publicIp'),
                      value: snapshot.publicAddress ?? l10n.t('unavailable'),
                    ),
                    _Badge(
                      label: l10n.t('wifi'),
                      value: snapshot.wifiName ?? l10n.t('unknown'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('networkStateWarning'),
                  style: Theme.of(context).textTheme.bodySmall,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (brokers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.t('noBrokers'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        for (final broker in brokers) ...[
          _BrokerCard(
            config: broker,
            runtime: manager.runtimeFor(broker.id),
            localIp: snapshot.primaryLocalAddress,
            publicIp: snapshot.publicAddress ?? l10n.t('unavailable'),
            lastActivityFormatter: (value) =>
              value == null ? l10n.t('noActivity') : dateFormat.format(value),
            onOpen: () => onOpenBroker(broker.id),
            onEdit: () => onEditBroker(broker.id),
            onDuplicate: () => manager.duplicateBroker(broker.id),
            onDelete: () => _confirmDelete(context, manager, broker),
            onStart: () => manager.startBroker(broker.id),
            onStop: () => manager.stopBroker(broker.id),
            onRestart: () => manager.restartBroker(broker.id),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BrokerManager manager,
    BrokerConfig broker,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.t('deleteBroker')),
        content: Text(
          context.l10n.deletePrompt(broker.name, broker.network.port),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await manager.deleteBroker(broker.id);
    }
  }
}

class _BrokerCard extends StatelessWidget {
  const _BrokerCard({
    required this.config,
    required this.runtime,
    required this.localIp,
    required this.publicIp,
    required this.lastActivityFormatter,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onOpen,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final BrokerConfig config;
  final BrokerRuntimeState runtime;
  final String localIp;
  final String publicIp;
  final String Function(DateTime?) lastActivityFormatter;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = switch (runtime.status) {
      BrokerStatus.running => colorScheme.primary,
      BrokerStatus.starting => colorScheme.secondary,
      BrokerStatus.error => Colors.redAccent,
      BrokerStatus.stopped => Colors.blueGrey,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(config.description),
                    ],
                  ),
                ),
                Chip(
                  avatar: CircleAvatar(backgroundColor: statusColor, radius: 4),
                  label: Text(l10n.statusLabel(runtime.status)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Badge(label: l10n.t('port'), value: '${config.network.port}'),
                _Badge(label: l10n.t('localIp'), value: localIp),
                _Badge(label: l10n.t('publicIp'), value: publicIp),
                _Badge(
                  label: l10n.t('clients'),
                  value: '${runtime.connectedClients}',
                ),
                _Badge(
                  label: l10n.t('lastActivity'),
                  value: lastActivityFormatter(runtime.lastActivityAt),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonal(
                  onPressed: onStart,
                  child: Text(l10n.t('start')),
                ),
                FilledButton.tonal(
                  onPressed: onStop,
                  child: Text(l10n.t('stop')),
                ),
                FilledButton.tonal(
                  onPressed: onRestart,
                  child: Text(l10n.t('restart')),
                ),
                OutlinedButton(onPressed: onOpen, child: Text(l10n.t('open'))),
                OutlinedButton(onPressed: onEdit, child: Text(l10n.t('edit'))),
                OutlinedButton(
                  onPressed: onDuplicate,
                  child: Text(l10n.t('duplicate')),
                ),
                OutlinedButton(
                  onPressed: onDelete,
                  child: Text(l10n.t('delete')),
                ),
              ],
            ),
            if (runtime.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                runtime.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2430),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2B3644)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
