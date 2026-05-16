import 'package:flutter/widgets.dart';

import 'storage_manager.dart';

class SettingsManager extends ChangeNotifier {
  SettingsManager({required StorageManager storageManager})
    : _storageManager = storageManager;

  final StorageManager _storageManager;

  String _languageCode = 'system';
  int _maxBrokers = 8;
  int _messageRetentionHours = 24;
  int _maxLogEntries = 1000;

  String get languageCode => _languageCode;
  int get maxBrokers => _maxBrokers;
  int get messageRetentionHours => _messageRetentionHours;
  int get maxLogEntries => _maxLogEntries;

  Future<void> initialize() async {
    _languageCode =
        await _storageManager.loadStringSetting('language_code') ?? 'system';
    _maxBrokers =
        await _storageManager.loadIntSetting('max_brokers') ?? _maxBrokers;
    _messageRetentionHours =
        await _storageManager.loadIntSetting('message_retention_hours') ??
        _messageRetentionHours;
    _maxLogEntries =
        await _storageManager.loadIntSetting('max_log_entries') ??
        _maxLogEntries;
    notifyListeners();
  }

  Future<void> updateLanguageCode(String value) async {
    _languageCode = value;
    await _storageManager.saveStringSetting('language_code', value);
    notifyListeners();
  }

  Future<void> updateMaxBrokers(int value) async {
    _maxBrokers = value.clamp(1, 100);
    await _storageManager.saveIntSetting('max_brokers', _maxBrokers);
    notifyListeners();
  }

  Future<void> updateMessageRetentionHours(int value) async {
    _messageRetentionHours = value.clamp(1, 24 * 365);
    await _storageManager.saveIntSetting(
      'message_retention_hours',
      _messageRetentionHours,
    );
    notifyListeners();
  }

  Future<void> updateMaxLogEntries(int value) async {
    _maxLogEntries = value.clamp(50, 100000);
    await _storageManager.saveIntSetting('max_log_entries', _maxLogEntries);
    notifyListeners();
  }
}
