import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/broker_models.dart';
import '../services/settings_manager.dart';

Future<BrokerConfig?> showBrokerEditorSheet(
  BuildContext context, {
  required BrokerConfig initialConfig,
}) {
  return showModalBottomSheet<BrokerConfig>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BrokerEditorSheet(initialConfig: initialConfig),
  );
}

class BrokerEditorSheet extends StatefulWidget {
  const BrokerEditorSheet({super.key, required this.initialConfig});

  final BrokerConfig initialConfig;

  @override
  State<BrokerEditorSheet> createState() => _BrokerEditorSheetState();
}

class _BrokerEditorSheetState extends State<BrokerEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _allowedController;
  late final TextEditingController _deniedController;
  late final TextEditingController _autoStopController;
  late final TextEditingController _scheduledStartController;
  late final TextEditingController _scheduledStopController;
  late final TextEditingController _maxEntriesController;

  late bool _webSocketEnabled;
  late bool _externalAccessEnabled;
  late bool _localOnly;
  late bool _hotspotSupport;
  late bool _anonymousMode;
  late bool _autoStart;
  late bool _autoRestart;
  late bool _loggingEnabled;
  late bool _savePayloads;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    _nameController = TextEditingController(text: config.name);
    _descriptionController = TextEditingController(text: config.description);
    _portController = TextEditingController(text: '${config.network.port}');
    _usernameController = TextEditingController(text: config.security.username);
    _passwordController = TextEditingController(text: config.security.password);
    _allowedController = TextEditingController(
      text: config.security.allowedClients.join(', '),
    );
    _deniedController = TextEditingController(
      text: config.security.deniedClients.join(', '),
    );
    _autoStopController = TextEditingController(
      text: '${config.automation.autoStopMinutes}',
    );
    _scheduledStartController = TextEditingController(
      text: config.automation.scheduledStart,
    );
    _scheduledStopController = TextEditingController(
      text: config.automation.scheduledStop,
    );
    _maxEntriesController = TextEditingController(
      text: '${config.logging.maxEntries}',
    );

    _webSocketEnabled = config.network.webSocketEnabled;
    _externalAccessEnabled = config.network.externalAccessEnabled;
    _localOnly = config.network.localNetworkOnly;
    _hotspotSupport = config.network.hotspotModeSupport;
    _anonymousMode = config.security.anonymousMode;
    _autoStart = config.automation.autoStart;
    _autoRestart = config.automation.autoRestartOnCrash;
    _loggingEnabled = config.logging.enabled;
    _savePayloads = config.logging.savePayloads;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _allowedController.dispose();
    _deniedController.dispose();
    _autoStopController.dispose();
    _scheduledStartController.dispose();
    _scheduledStopController.dispose();
    _maxEntriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF10161D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            32,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.t('brokerSettings'), style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.t('brokerName')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.t('description')),
              ),
              const SizedBox(height: 20),
              _SectionLabel(title: l10n.t('network')),
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.t('port')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('websocketPlaceholder')),
                subtitle: Text(l10n.t('configPersistedLater')),
                value: _webSocketEnabled,
                onChanged: (value) => setState(() => _webSocketEnabled = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('allowExternalAccess')),
                value: _externalAccessEnabled,
                onChanged: (value) =>
                    setState(() => _externalAccessEnabled = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('localNetworkOnly')),
                value: _localOnly,
                onChanged: (value) => setState(() => _localOnly = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('hotspotSupport')),
                value: _hotspotSupport,
                onChanged: (value) => setState(() => _hotspotSupport = value),
              ),
              const SizedBox(height: 20),
              _SectionLabel(title: l10n.t('security')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('anonymousMode')),
                value: _anonymousMode,
                onChanged: (value) => setState(() => _anonymousMode = value),
              ),
              TextField(
                controller: _usernameController,
                enabled: !_anonymousMode,
                decoration: InputDecoration(labelText: l10n.t('username')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                enabled: !_anonymousMode,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.t('password')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _allowedController,
                decoration: InputDecoration(
                  labelText: l10n.t('allowClientList'),
                  hintText: 'clientA, clientB',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deniedController,
                decoration: InputDecoration(
                  labelText: l10n.t('denyClientList'),
                  hintText: 'clientX, clientY',
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(title: l10n.t('automationLogging')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('autoStartOnLaunch')),
                value: _autoStart,
                onChanged: (value) => setState(() => _autoStart = value),
              ),
              TextField(
                controller: _autoStopController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.t('autoStopMinutesLabel'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _scheduledStartController,
                decoration: InputDecoration(
                  labelText: l10n.t('scheduledStartOptional'),
                  hintText: '08:00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _scheduledStopController,
                decoration: InputDecoration(
                  labelText: l10n.t('scheduledStopOptional'),
                  hintText: '23:00',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('autoRestartOnCrash')),
                value: _autoRestart,
                onChanged: (value) => setState(() => _autoRestart = value),
              ),
              const SizedBox(height: 20),
              _SectionLabel(title: l10n.t('logging')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('enableLogs')),
                value: _loggingEnabled,
                onChanged: (value) => setState(() => _loggingEnabled = value),
              ),
              TextField(
                controller: _maxEntriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.t('maxLogEntries')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.t('savePayloads')),
                value: _savePayloads,
                onChanged: (value) => setState(() => _savePayloads = value),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(l10n.t('save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final maxAllowedLogs = context.read<SettingsManager>().maxLogEntries;
    final port = int.tryParse(_portController.text.trim()) ?? 1883;
    final autoStop = int.tryParse(_autoStopController.text.trim()) ?? 0;
    final maxEntries =
        (int.tryParse(_maxEntriesController.text.trim()) ?? 1000).clamp(
          1,
          maxAllowedLogs,
        );

    final updated = widget.initialConfig.copyWith(
      name: _nameController.text.trim().isEmpty
          ? widget.initialConfig.name
          : _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      network: widget.initialConfig.network.copyWith(
        port: port,
        webSocketEnabled: _webSocketEnabled,
        externalAccessEnabled: _externalAccessEnabled,
        localNetworkOnly: _localOnly,
        hotspotModeSupport: _hotspotSupport,
      ),
      security: widget.initialConfig.security.copyWith(
        anonymousMode: _anonymousMode,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        allowedClients: _splitList(_allowedController.text),
        deniedClients: _splitList(_deniedController.text),
      ),
      automation: widget.initialConfig.automation.copyWith(
        autoStart: _autoStart,
        autoStopMinutes: autoStop,
        scheduledStart: _scheduledStartController.text.trim(),
        scheduledStop: _scheduledStopController.text.trim(),
        autoRestartOnCrash: _autoRestart,
      ),
      logging: widget.initialConfig.logging.copyWith(
        enabled: _loggingEnabled,
        maxEntries: maxEntries,
        savePayloads: _savePayloads,
      ),
    );

    Navigator.of(context).pop(updated);
  }

  List<String> _splitList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}
