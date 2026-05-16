import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../services/broker_manager.dart';
import '../services/network_manager.dart';
import '../services/settings_manager.dart';
import '../widgets/broker_editor_sheet.dart';
import 'about_debug_screen.dart';
import 'broker_details_screen.dart';
import 'broker_list_screen.dart';
import 'import_export_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final networkManager = context.watch<NetworkManager>();
    final titles = [l10n.t('brokers'), l10n.t('importExport'), l10n.t('debug')];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.t('settings'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            );
          },
          icon: const Icon(Icons.settings_rounded),
        ),
        title: Text(titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: l10n.t('refreshNetwork'),
            onPressed: () => networkManager.refresh(),
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          BrokerListScreen(
            onOpenBroker: _openBroker,
            onEditBroker: _editBroker,
          ),
          const ImportExportScreen(),
          const AboutDebugScreen(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _createBroker,
              icon: const Icon(Icons.add),
              label: Text(l10n.t('createBroker')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.hub_outlined),
            label: l10n.t('brokers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.import_export_rounded),
            label: l10n.t('importExport'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.developer_mode_rounded),
            label: l10n.t('debug'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBroker() async {
    final manager = context.read<BrokerManager>();
    final settings = context.read<SettingsManager>();
    if (manager.brokers.length >= settings.maxBrokers) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.t('maxBrokers')}: ${settings.maxBrokers}',
          ),
        ),
      );
      return;
    }
    final config = await showBrokerEditorSheet(
      context,
      initialConfig: manager.newDraftBroker(
        defaultMaxLogEntries: settings.maxLogEntries,
      ),
    );
    if (!mounted || config == null) {
      return;
    }
    await manager.createBroker(config);
  }

  Future<void> _editBroker(String brokerId) async {
    final manager = context.read<BrokerManager>();
    final broker = manager.brokerById(brokerId);
    if (broker == null) {
      return;
    }
    final updated = await showBrokerEditorSheet(context, initialConfig: broker);
    if (!mounted || updated == null) {
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

  void _openBroker(String brokerId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BrokerDetailsScreen(brokerId: brokerId),
      ),
    );
  }
}
