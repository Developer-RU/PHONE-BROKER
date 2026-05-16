import 'dart:convert';
import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/broker_models.dart';

/// Handles local SQLite persistence for brokers and app settings.
class StorageManager {
  Database? _database;

  /// Opens the app database and recreates it if the file is corrupted.
  Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    final databasePath = p.join(directory.path, 'mqtt_hub.sqlite');

    try {
      _database = await _openDatabase(databasePath).timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {
      // Recover from a potentially corrupted DB file after abrupt app termination.
      await deleteDatabase(databasePath);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _database = await _openDatabase(databasePath).timeout(
        const Duration(seconds: 8),
      );
    }
  }

  Future<Database> _openDatabase(String databasePath) {
    return openDatabase(
      databasePath,
      singleInstance: false,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE brokers (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Database get _db {
    final database = _database;
    if (database == null) {
      throw StateError('StorageManager is not initialized');
    }
    return database;
  }

  /// Loads broker configurations ordered by most recently updated first.
  ///
  /// Invalid serialized rows are discarded from storage to keep the database
  /// clean and prevent repeated decode failures.
  Future<List<BrokerConfig>> loadBrokerConfigs() async {
    final rows = await _db.query('brokers', orderBy: 'updated_at DESC');
    final configs = <BrokerConfig>[];
    final invalidIds = <String>[];

    for (final row in rows) {
      try {
        configs.add(
          BrokerConfig.fromJson(
            jsonDecode(row['payload']! as String) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        final id = row['id'];
        if (id is String && id.isNotEmpty) {
          invalidIds.add(id);
        }
      }
    }

    if (invalidIds.isNotEmpty) {
      await _db.delete(
        'brokers',
        where: 'id IN (${List.filled(invalidIds.length, '?').join(',')})',
        whereArgs: invalidIds,
      );
    }

    return configs;
  }

  /// Persists or replaces a broker configuration.
  Future<void> saveBrokerConfig(BrokerConfig config) async {
    await _db.insert('brokers', {
      'id': config.id,
      'payload': jsonEncode(config.toJson()),
      'updated_at': config.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Removes a broker configuration by identifier.
  Future<void> deleteBrokerConfig(String id) async {
    await _db.delete('brokers', where: 'id = ?', whereArgs: [id]);
  }

  /// Saves a string setting value by key.
  Future<void> saveStringSetting(String key, String value) async {
    await _db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Loads a string setting value by key.
  Future<String?> loadStringSetting(String key) async {
    final rows = await _db.query(
      'app_settings',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  /// Saves an integer setting value by key.
  Future<void> saveIntSetting(String key, int value) async {
    await saveStringSetting(key, '$value');
  }

  /// Loads an integer setting value by key.
  Future<int?> loadIntSetting(String key) async {
    final value = await loadStringSetting(key);
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }
}
