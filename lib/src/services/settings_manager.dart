import 'package:flutter/widgets.dart';

import 'storage_manager.dart';

/// Stores and exposes global app-level settings.
///
/// Values are persisted through [StorageManager] and mirrored in-memory for
/// reactive UI updates via [ChangeNotifier].
class SettingsManager extends ChangeNotifier {
  /// Creates a settings manager bound to persistent storage.
  SettingsManager({required StorageManager storageManager})
    : _storageManager = storageManager;

  final StorageManager _storageManager;

  String _languageCode = 'system';
  int _maxBrokers = 8;
  int _messageRetentionHours = 24;
  int _maxLogEntries = 1000;

  /// Currently selected language code (`system`, `en`, `ru`, etc.).
  String get languageCode => _languageCode;

  /// Maximum number of broker configs the UI should allow creating.
  int get maxBrokers => _maxBrokers;

  /// Message retention period in hours for newly created brokers.
  int get messageRetentionHours => _messageRetentionHours;

  /// Default upper bound for per-broker log entries.
  int get maxLogEntries => _maxLogEntries;

  /// Loads persisted settings and notifies listeners once values are ready.
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

  /// Updates UI language and persists it.
  Future<void> updateLanguageCode(String value) async {
    _languageCode = value;
    await _storageManager.saveStringSetting('language_code', value);
    notifyListeners();
  }

  /// Updates and clamps the global broker limit to a safe range.
  Future<void> updateMaxBrokers(int value) async {
    _maxBrokers = value.clamp(1, 100);
    await _storageManager.saveIntSetting('max_brokers', _maxBrokers);
    notifyListeners();
  }

  /// Updates retention period and clamps it to `1..8760` hours.
  Future<void> updateMessageRetentionHours(int value) async {
    _messageRetentionHours = value.clamp(1, 24 * 365);
    await _storageManager.saveIntSetting(
      'message_retention_hours',
      _messageRetentionHours,
    );
    notifyListeners();
  }

  /// Updates default log capacity and clamps it to `50..100000` entries.
  Future<void> updateMaxLogEntries(int value) async {
    _maxLogEntries = value.clamp(50, 100000);
    await _storageManager.saveIntSetting('max_log_entries', _maxLogEntries);
    notifyListeners();
  }
}
