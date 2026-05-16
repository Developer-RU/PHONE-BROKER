import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/broker_models.dart';

class LogManager extends ChangeNotifier {
  final Map<String, List<BrokerLogEntry>> _logsByBroker = {};

  UnmodifiableListView<BrokerLogEntry> logsFor(String brokerId) {
    return UnmodifiableListView(_logsByBroker[brokerId] ?? const []);
  }

  void append(
    BrokerConfig config, {
    required BrokerLogDirection direction,
    String topic = '',
    String payload = '',
    String clientId = '',
    String message = '',
  }) {
    if (!config.logging.enabled && direction != BrokerLogDirection.system) {
      return;
    }

    final entry = BrokerLogEntry(
      id: '${config.id}-${DateTime.now().microsecondsSinceEpoch}',
      brokerId: config.id,
      timestamp: DateTime.now(),
      direction: direction,
      topic: topic,
      payload: config.logging.savePayloads ? payload : '[payload omitted]',
      clientId: clientId,
      message: message,
    );

    final list = _logsByBroker.putIfAbsent(config.id, () => <BrokerLogEntry>[]);
    list.insert(0, entry);
    if (list.length > config.logging.maxEntries) {
      list.removeRange(config.logging.maxEntries, list.length);
    }
    notifyListeners();
  }

  void clear(String brokerId) {
    _logsByBroker[brokerId]?.clear();
    notifyListeners();
  }

  Map<String, dynamic> exportPayload(
    BrokerConfig config,
    List<BrokerLogEntry> logs,
  ) {
    return {
      'broker': config.toJson(),
      'logs': logs.map((entry) => entry.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}
