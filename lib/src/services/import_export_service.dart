import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/broker_models.dart';

class ImportExportService {
  Future<void> exportBrokerConfig(BrokerConfig config) async {
    final file = await _writeJsonFile(
      fileName: 'mqtt-hub-${config.name}-${config.network.port}.json',
      payload: {
        'exportedAt': DateTime.now().toIso8601String(),
        'brokers': [config.toJson()],
      },
    );
    await SharePlus.instance.share(
      ShareParams(title: 'Export ${config.name}', files: [XFile(file.path)]),
    );
  }

  Future<void> exportAllBrokers(List<BrokerConfig> configs) async {
    final file = await _writeJsonFile(
      fileName: 'mqtt-hub-all-brokers.json',
      payload: {
        'exportedAt': DateTime.now().toIso8601String(),
        'brokers': configs.map((config) => config.toJson()).toList(),
      },
    );
    await SharePlus.instance.share(
      ShareParams(title: 'Export all brokers', files: [XFile(file.path)]),
    );
  }

  Future<void> exportBrokerLogs({
    required BrokerConfig config,
    required Map<String, dynamic> payload,
  }) async {
    final file = await _writeJsonFile(
      fileName: 'mqtt-hub-${config.name}-logs.json',
      payload: payload,
    );
    await SharePlus.instance.share(
      ShareParams(title: 'Export broker logs', files: [XFile(file.path)]),
    );
  }

  Future<List<BrokerConfig>> importBrokerConfigs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return const [];
    }

    final file = result.files.first;
    final content = file.bytes != null
        ? utf8.decode(file.bytes!)
        : await File(file.path!).readAsString();
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    final brokers = (decoded['brokers'] as List<dynamic>? ?? const [])
        .map((item) => BrokerConfig.fromJson(item as Map<String, dynamic>))
        .toList();

    return brokers;
  }

  Future<File> _writeJsonFile({
    required String fileName,
    required Map<String, dynamic> payload,
  }) async {
    final directory = await getTemporaryDirectory();
    final sanitized = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    final file = File(p.join(directory.path, sanitized));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file;
  }
}
