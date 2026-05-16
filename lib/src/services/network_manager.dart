import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

import '../models/broker_models.dart';

/// Probes local/public network state and publishes snapshots to the UI.
class NetworkManager extends ChangeNotifier {
  final NetworkInfo _networkInfo = NetworkInfo();

  Timer? _refreshTimer;
  NetworkSnapshot _snapshot = const NetworkSnapshot.initial();

  /// Latest computed network snapshot.
  NetworkSnapshot get snapshot => _snapshot;

  /// Starts periodic and event-driven network probing.
  Future<void> initialize() async {
    // Do not block app startup on network probing/public IP lookup.
    _safeRefresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _safeRefresh(),
    );
  }

  /// Runs [refresh] in a guarded async zone to avoid bubbling probe errors.
  void _safeRefresh() {
    unawaited(() async {
      try {
        await refresh();
      } catch (_) {
        // Network probing is best-effort and should never crash app startup.
      }
    }());
  }

  /// Recomputes connectivity mode, local addresses, SSID and public IP.
  Future<void> refresh() async {
    final localAddresses = await _loadLocalAddresses();
    final wifiName = await _safeWifiName();
    final publicAddress = await _loadPublicAddress();

    _snapshot = NetworkSnapshot(
      mode: _detectMode(localAddresses, wifiName),
      localAddresses: localAddresses,
      publicAddress: publicAddress,
      wifiName: wifiName,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<List<String>> _loadLocalAddresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    final addresses =
        interfaces
            .expand((item) => item.addresses)
            .map((address) => address.address)
            .where((address) => !address.startsWith('127.'))
            .toSet()
            .toList()
          ..sort();

    return addresses;
  }

  Future<String?> _safeWifiName() async {
    try {
      return await _networkInfo.getWifiName();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _loadPublicAddress() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['ip'] as String?;
    } catch (_) {
      return null;
    }
  }

  NetworkMode _detectMode(
    List<String> localAddresses,
    String? wifiName,
  ) {
    final primary = localAddresses.isEmpty ? '' : localAddresses.first;
    final isHotspotAddress = primary.startsWith('172.20.10.');

    // If iOS reports SSID, treat connection as Wi-Fi (or hotspot by address).
    if (wifiName != null && wifiName.isNotEmpty) {
      return isHotspotAddress ? NetworkMode.hotspot : NetworkMode.wifi;
    }

    // Without connectivity_plus, classify by available interfaces.
    if (localAddresses.isNotEmpty) {
      return isHotspotAddress ? NetworkMode.hotspot : NetworkMode.unknown;
    }

    return NetworkMode.offline;
  }

  @override
  /// Cancels timers and releases resources.
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
