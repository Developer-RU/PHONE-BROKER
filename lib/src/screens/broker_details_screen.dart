import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/broker_models.dart';
import '../services/broker_manager.dart';
import '../services/import_export_service.dart';
import '../services/log_manager.dart';
import '../widgets/broker_editor_sheet.dart';

class BrokerDetailsScreen extends StatelessWidget {
  const BrokerDetailsScreen({super.key, required this.brokerId});

  final String brokerId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final manager = context.watch<BrokerManager>();
    final broker = manager.brokerById(brokerId);
    if (broker == null) {
      return Scaffold(body: Center(child: Text(l10n.t('brokerNotFound'))));
    }

    final runtime = manager.runtimeFor(brokerId);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(broker.name),
          actions: [
            IconButton(
              tooltip: l10n.t('exportBrokerConfig'),
              onPressed: () => context
                  .read<ImportExportService>()
                  .exportBrokerConfig(broker),
              icon: const Icon(Icons.ios_share_rounded),
            ),
            IconButton(
              tooltip: l10n.t('editBroker'),
              onPressed: () => _editBroker(context, broker),
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.t('overview')),
              Tab(text: l10n.t('logs')),
              Tab(text: l10n.t('settings')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(broker: broker, runtime: runtime),
            _LogsTab(broker: broker),
            _SettingsTab(broker: broker),
          ],
        ),
      ),
    );
  }

  Future<void> _editBroker(BuildContext context, BrokerConfig broker) async {
    final manager = context.read<BrokerManager>();
    final updated = await showBrokerEditorSheet(context, initialConfig: broker);
    if (!context.mounted || updated == null) {
      return;
    }
    if (updated.network.port != broker.network.port &&
        manager.portInUse(updated.network.port)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('portInUse'))),
      );
      return;
    }
    await manager.updateBroker(updated);
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.broker, required this.runtime});

  final BrokerConfig broker;
  final BrokerRuntimeState runtime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snapshot = context.watch<BrokerManager>().networkSnapshot;
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final uptime = runtime.uptime;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('general'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _Line(label: l10n.t('brokerName'), value: broker.name),
                _Line(label: l10n.t('description'), value: broker.description),
                _Line(label: l10n.t('port'), value: '${broker.network.port}'),
                _Line(label: l10n.t('localIp'), value: snapshot.primaryLocalAddress),
                _Line(
                  label: l10n.t('publicIp'),
                  value: snapshot.publicAddress ?? l10n.t('unavailable'),
                ),
                _Line(
                  label: l10n.t('currentUptime'),
                  value: l10n.uptime(uptime),
                ),
                _Line(
                  label: l10n.t('currentStatus'),
                  value: l10n.statusLabel(runtime.status),
                ),
                _Line(
                  label: l10n.t('lastActivity'),
                  value: runtime.lastActivityAt == null
                      ? l10n.t('noActivity')
                      : formatter.format(runtime.lastActivityAt!),
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
                Text(l10n.t('clients'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (runtime.clients.isEmpty)
                  Text(l10n.t('none'))
                else
                  for (final client in runtime.clients) ...[
                    _Line(label: 'Client ID', value: client.clientId),
                    _Line(label: 'IP address', value: client.ipAddress),
                    _Line(
                      label: 'Connection duration',
                      value:
                          '${DateTime.now().difference(client.connectedAt).inMinutes} min',
                    ),
                    _Line(
                      label: 'Last packet',
                      value: formatter.format(client.lastPacketAt),
                    ),
                    _Line(
                      label: 'Subscriptions',
                      value: '${client.subscriptionsCount}',
                    ),
                    const Divider(height: 24),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LogsTab extends StatefulWidget {
  const _LogsTab({required this.broker});

  final BrokerConfig broker;

  @override
  State<_LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<_LogsTab> {
  bool _paused = false;
  BrokerLogDirection? _filter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<LogManager>().logsFor(widget.broker.id);
    final visibleLogs = _paused
        ? const <BrokerLogEntry>[]
        : logs.where((entry) {
            final matchesFilter = _filter == null || entry.direction == _filter;
            final search = _searchController.text.trim().toLowerCase();
            final haystack = [
              entry.topic,
              entry.payload,
              entry.clientId,
              entry.message,
            ].join(' ').toLowerCase();
            final matchesSearch = search.isEmpty || haystack.contains(search);
            return matchesFilter && matchesSearch;
          }).toList();
    final formatter = DateFormat('HH:mm:ss');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: context.l10n.t('searchLogs'),
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: _paused ? context.l10n.t('resumeLogs') : context.l10n.t('pauseLogs'),
                onPressed: () => setState(() => _paused = !_paused),
                icon: Icon(
                  _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
              ),
              IconButton(
                tooltip: context.l10n.t('clearLogs'),
                onPressed: () =>
                    context.read<LogManager>().clear(widget.broker.id),
                icon: const Icon(Icons.delete_sweep_rounded),
              ),
              IconButton(
                tooltip: context.l10n.t('exportLogs'),
                onPressed: () {
                  final logManager = context.read<LogManager>();
                  final payload = logManager.exportPayload(widget.broker, logs);
                  context.read<ImportExportService>().exportBrokerLogs(
                    config: widget.broker,
                    payload: payload,
                  );
                },
                icon: const Icon(Icons.file_upload_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(context.l10n.t('all')),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final direction in BrokerLogDirection.values)
                ChoiceChip(
                  label: Text(_directionLabel(context, direction)),
                  selected: _filter == direction,
                  onSelected: (_) => setState(() => _filter = direction),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.broker.logging.enabled
                      ? context.l10n.t('loggingEnabled')
                      : context.l10n.t('loggingDisabledSystem'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: visibleLogs.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final entry = visibleLogs[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(formatter.format(entry.timestamp)),
                          const SizedBox(width: 8),
                          Chip(label: Text(_directionLabel(context, entry.direction))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.topic.isEmpty ? entry.message : entry.topic,
                            ),
                          ),
                        ],
                      ),
                      if (entry.clientId.isNotEmpty)
                        Text('${context.l10n.t('client')}: ${entry.clientId}'),
                      if (entry.payload.isNotEmpty)
                        Text(
                          entry.payload,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _directionLabel(BuildContext context, BrokerLogDirection direction) {
    return switch (direction) {
      BrokerLogDirection.inbound => 'IN',
      BrokerLogDirection.outbound => 'OUT',
      BrokerLogDirection.system => 'SYSTEM',
    };
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.broker});

  final BrokerConfig broker;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('network'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _Line(label: l10n.t('port'), value: '${broker.network.port}'),
                _Line(
                  label: 'WebSocket',
                  value: broker.network.webSocketEnabled
                      ? l10n.t('enabled')
                      : l10n.t('disabled'),
                ),
                _Line(
                  label: 'External access',
                  value: broker.network.externalAccessEnabled
                      ? l10n.t('enabled')
                      : l10n.t('disabled'),
                ),
                _Line(
                  label: 'Local only',
                  value: broker.network.localNetworkOnly
                      ? l10n.t('enabled')
                      : l10n.t('disabled'),
                ),
                _Line(
                  label: 'Hotspot support',
                  value: broker.network.hotspotModeSupport
                      ? l10n.t('enabled')
                      : l10n.t('disabled'),
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
                Text(l10n.t('security'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _Line(
                  label: l10n.t('anonymousMode'),
                  value: broker.security.anonymousMode ? l10n.t('enabled') : l10n.t('disabled'),
                ),
                _Line(
                  label: l10n.t('username'),
                  value: broker.security.username.isEmpty
                      ? l10n.t('notSet')
                      : broker.security.username,
                ),
                _Line(
                  label: l10n.t('allowedClients'),
                  value: broker.security.allowedClients.isEmpty
                      ? l10n.t('anyClient')
                      : broker.security.allowedClients.join(', '),
                ),
                _Line(
                  label: l10n.t('deniedClients'),
                  value: broker.security.deniedClients.isEmpty
                      ? l10n.t('none')
                      : broker.security.deniedClients.join(', '),
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
                  l10n.t('automationLogging'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _Line(
                  label: l10n.t('autoStart'),
                  value: broker.automation.autoStart ? l10n.t('enabled') : l10n.t('disabled'),
                ),
                _Line(
                  label: l10n.t('autoStopTimer'),
                  value: broker.automation.autoStopMinutes == 0
                      ? l10n.t('disabled')
                      : l10n.minutes(broker.automation.autoStopMinutes),
                ),
                _Line(
                  label: l10n.t('autoRestartCrash'),
                  value: broker.automation.autoRestartOnCrash
                      ? l10n.t('enabled')
                      : l10n.t('disabled'),
                ),
                _Line(
                  label: l10n.t('scheduledStart'),
                  value: broker.automation.scheduledStart.isEmpty
                      ? l10n.t('notSet')
                      : broker.automation.scheduledStart,
                ),
                _Line(
                  label: l10n.t('scheduledStop'),
                  value: broker.automation.scheduledStop.isEmpty
                      ? l10n.t('notSet')
                      : broker.automation.scheduledStop,
                ),
                _Line(
                  label: l10n.t('logging'),
                  value: broker.logging.enabled ? l10n.t('enabled') : l10n.t('disabled'),
                ),
                _Line(
                  label: l10n.t('logSizeLimit'),
                  value: '${broker.logging.maxEntries}',
                ),
                _Line(
                  label: l10n.t('savePayloads'),
                  value: broker.logging.savePayloads ? l10n.t('enabled') : l10n.t('disabled'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
