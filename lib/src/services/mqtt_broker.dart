import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/broker_models.dart';
import 'log_manager.dart';

class EmbeddedMqttBroker {
  EmbeddedMqttBroker({
    required this.config,
    required this.logManager,
    required this.onStateChanged,
  });

  final BrokerConfig config;
  final LogManager logManager;
  final ValueChanged<BrokerRuntimeState> onStateChanged;

  final Map<Socket, _ClientConnection> _connections = {};
  final Map<String, List<_Subscription>> _subscriptions = {};
  final Map<String, _RetainedMessage> _retainedMessages = {};

  ServerSocket? _server;
  Timer? _autoStopTimer;
  BrokerRuntimeState _state = const BrokerRuntimeState.stopped();
  int _packetSeed = 1;

  bool get isRunning => _server != null;

  Map<String, dynamic> get diagnostics => {
    'port': config.network.port,
    'isRunning': isRunning,
    'subscriptions': _subscriptions.length,
    'retainedMessages': _retainedMessages.length,
    'clients': _state.clients
        .map(
          (client) => {
            'clientId': client.clientId,
            'ipAddress': client.ipAddress,
            'connectedAt': client.connectedAt.toIso8601String(),
            'lastPacketAt': client.lastPacketAt.toIso8601String(),
            'packetCount': client.packetCount,
            'subscriptionsCount': client.subscriptionsCount,
          },
        )
        .toList(),
  };

  Future<void> start() async {
    if (_server != null) {
      return;
    }

    _setState(
      _state.copyWith(
        status: BrokerStatus.starting,
        lastActivityAt: DateTime.now(),
        clearError: true,
      ),
    );

    try {
      final server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        config.network.port,
        shared: false,
      );
      _server = server;
      _scheduleAutoStop();
      server.listen(
        _handleIncomingSocket,
        onError: (Object error, StackTrace stackTrace) {
          _fail('Broker socket error: $error');
        },
      );

      logManager.append(
        config,
        direction: BrokerLogDirection.system,
        message:
            'Broker ${config.name} started on port ${config.network.port}.',
      );
      _setState(
        _state.copyWith(
          status: BrokerStatus.running,
          startedAt: DateTime.now(),
          lastActivityAt: DateTime.now(),
          clearError: true,
        ),
      );
    } catch (error) {
      _fail('Failed to start broker on port ${config.network.port}: $error');
    }
  }

  Future<void> stop({String reason = 'Stopped by user'}) async {
    _autoStopTimer?.cancel();
    final clients = _connections.values.toList();
    for (final client in clients) {
      await _disconnect(client, reason, closeSocket: true);
    }
    await _server?.close();
    _server = null;
    _subscriptions.clear();

    logManager.append(
      config,
      direction: BrokerLogDirection.system,
      message: reason,
    );
    _setState(
      const BrokerRuntimeState.stopped().copyWith(
        lastActivityAt: DateTime.now(),
      ),
    );
  }

  Future<void> dispose() async {
    _autoStopTimer?.cancel();
    await _server?.close();
    _server = null;
  }

  void _scheduleAutoStop() {
    _autoStopTimer?.cancel();
    if (config.automation.autoStopMinutes <= 0) {
      return;
    }
    _autoStopTimer = Timer(
      Duration(minutes: config.automation.autoStopMinutes),
      () => stop(reason: 'Auto-stop timer reached.'),
    );
  }

  void _handleIncomingSocket(Socket socket) {
    socket.setOption(SocketOption.tcpNoDelay, true);
    final connection = _ClientConnection(
      socket: socket,
      ipAddress: socket.remoteAddress.address,
      connectedAt: DateTime.now(),
    );
    _connections[socket] = connection;
    _emitState();

    logManager.append(
      config,
      direction: BrokerLogDirection.system,
      message: 'TCP client connected from ${connection.ipAddress}.',
    );

    socket.listen(
      (data) => _handleData(connection, data),
      onError: (Object error, StackTrace _) {
        _disconnect(connection, 'Socket error: $error');
      },
      onDone: () {
        _disconnect(connection, 'Client disconnected.');
      },
      cancelOnError: true,
    );
  }

  void _handleData(_ClientConnection connection, Uint8List data) {
    connection.buffer.addAll(data);
    connection.lastPacketAt = DateTime.now();
    connection.packetCount += 1;
    _touch();
    _logRaw(connection, data, incoming: true);

    while (true) {
      final packet = _tryDecodePacket(connection.buffer);
      if (packet == null) {
        break;
      }
      _processPacket(connection, packet);
    }
  }

  _MqttPacket? _tryDecodePacket(List<int> source) {
    if (source.length < 2) {
      return null;
    }

    var multiplier = 1;
    var value = 0;
    var index = 1;
    var encodedByte = 0;

    do {
      if (index >= source.length) {
        return null;
      }
      encodedByte = source[index++];
      value += (encodedByte & 0x7F) * multiplier;
      multiplier *= 128;
      if (multiplier > 128 * 128 * 128 * 128) {
        throw const FormatException('Malformed MQTT remaining length.');
      }
    } while ((encodedByte & 0x80) != 0);

    if (source.length < index + value) {
      return null;
    }

    final packetBytes = Uint8List.fromList(source.sublist(0, index + value));
    source.removeRange(0, index + value);
    return _MqttPacket(
      header: packetBytes[0],
      body: packetBytes.sublist(index),
    );
  }

  void _processPacket(_ClientConnection connection, _MqttPacket packet) {
    final packetType = packet.header >> 4;
    switch (packetType) {
      case 1:
        _handleConnect(connection, packet.body);
      case 3:
        _handlePublish(connection, packet);
      case 4:
        _handlePubAck(connection, packet.body);
      case 8:
        _handleSubscribe(connection, packet.body);
      case 10:
        _handleUnsubscribe(connection, packet.body);
      case 12:
        _sendPacket(
          connection,
          const [0xD0, 0x00],
          direction: BrokerLogDirection.outbound,
          message: 'PINGRESP',
        );
      case 14:
        _disconnect(connection, 'Client sent DISCONNECT.');
      default:
        logManager.append(
          config,
          direction: BrokerLogDirection.system,
          clientId: connection.clientId ?? '',
          message: 'Unsupported packet type $packetType ignored.',
        );
    }
  }

  void _handleConnect(_ClientConnection connection, Uint8List body) {
    try {
      var index = 0;
      final protocolName = _readString(body, index);
      index = protocolName.nextIndex;
      final protocolLevel = body[index++];
      final connectFlags = body[index++];
      final keepAliveSeconds = (body[index] << 8) | body[index + 1];
      index += 2;

      final clientId = _readString(body, index);
      index = clientId.nextIndex;

      final willFlag = (connectFlags & 0x04) != 0;
      final usernameFlag = (connectFlags & 0x80) != 0;
      final passwordFlag = (connectFlags & 0x40) != 0;
      final cleanSession = (connectFlags & 0x02) != 0;

      if (willFlag) {
        index = _readString(body, index).nextIndex;
        index = _readBytes(body, index).nextIndex;
      }

      String username = '';
      String password = '';
      if (usernameFlag) {
        final value = _readString(body, index);
        username = value.value;
        index = value.nextIndex;
      }
      if (passwordFlag) {
        final value = _readString(body, index);
        password = value.value;
        index = value.nextIndex;
      }
      if (index > body.length) {
        throw const FormatException('CONNECT payload exceeded packet length.');
      }

      if (clientId.value.isEmpty) {
        _sendConnAck(connection, 0x02);
        return;
      }
      if (protocolName.value != 'MQTT' ||
          (protocolLevel != 4 && protocolLevel != 3)) {
        _sendConnAck(connection, 0x01);
        return;
      }
      if (!_authorizeClient(clientId.value, username, password)) {
        _sendConnAck(connection, 0x05);
        return;
      }

      for (final other in _connections.values.where(
        (item) => item != connection && item.clientId == clientId.value,
      )) {
        _disconnect(other, 'Duplicate client ID: ${clientId.value}.');
      }

      connection.clientId = clientId.value;
      connection.cleanSession = cleanSession;
      connection.keepAliveSeconds = keepAliveSeconds;
      connection.lastPacketAt = DateTime.now();
      _startKeepAliveMonitor(connection);

      _sendConnAck(connection, 0x00);
      logManager.append(
        config,
        direction: BrokerLogDirection.system,
        clientId: clientId.value,
        message: 'Client connected from ${connection.ipAddress}.',
      );
      _emitState();
    } catch (error) {
      _sendConnAck(connection, 0x02);
      _disconnect(connection, 'CONNECT parse error: $error');
    }
  }

  bool _authorizeClient(String clientId, String username, String password) {
    final security = config.security;
    final allowed =
        security.allowedClients.isEmpty ||
        security.allowedClients.contains(clientId);
    final denied = security.deniedClients.contains(clientId);
    final credentialsOkay =
        security.anonymousMode ||
        (security.username == username && security.password == password);
    return allowed && !denied && credentialsOkay;
  }

  void _handleSubscribe(_ClientConnection connection, Uint8List body) {
    if (connection.clientId == null) {
      return;
    }
    try {
      var index = 0;
      final packetId = (body[index] << 8) | body[index + 1];
      index += 2;
      final grantedQos = <int>[];

      while (index < body.length) {
        final topic = _readString(body, index);
        index = topic.nextIndex;
        final requestedQos = (body[index++]).clamp(0, 1);
        _addSubscription(connection, topic.value, requestedQos);
        grantedQos.add(requestedQos);

        for (final retained in _retainedMessages.values) {
          if (_topicMatches(topic.value, retained.topic)) {
            _publishToConnection(
              connection,
              topic: retained.topic,
              payload: retained.payload,
              qos: min(retained.qos, requestedQos),
              retained: true,
            );
          }
        }
      }

      final payload = <int>[packetId >> 8, packetId & 0xFF, ...grantedQos];
      _sendPacket(
        connection,
        [0x90, ..._encodeRemainingLength(payload.length), ...payload],
        direction: BrokerLogDirection.outbound,
        clientId: connection.clientId ?? '',
        message: 'SUBACK',
      );
      _emitState();
    } catch (error) {
      logManager.append(
        config,
        direction: BrokerLogDirection.system,
        clientId: connection.clientId ?? '',
        message: 'SUBSCRIBE parse error: $error',
      );
    }
  }

  void _handleUnsubscribe(_ClientConnection connection, Uint8List body) {
    if (connection.clientId == null) {
      return;
    }
    try {
      var index = 0;
      final packetId = (body[index] << 8) | body[index + 1];
      index += 2;
      while (index < body.length) {
        final topic = _readString(body, index);
        index = topic.nextIndex;
        _removeSubscription(connection, topic.value);
      }
      final payload = <int>[packetId >> 8, packetId & 0xFF];
      _sendPacket(
        connection,
        [0xB0, ..._encodeRemainingLength(payload.length), ...payload],
        direction: BrokerLogDirection.outbound,
        clientId: connection.clientId ?? '',
        message: 'UNSUBACK',
      );
      _emitState();
    } catch (error) {
      logManager.append(
        config,
        direction: BrokerLogDirection.system,
        clientId: connection.clientId ?? '',
        message: 'UNSUBSCRIBE parse error: $error',
      );
    }
  }

  void _handlePublish(_ClientConnection connection, _MqttPacket packet) {
    if (connection.clientId == null) {
      return;
    }
    try {
      var index = 0;
      final flags = packet.header & 0x0F;
      final retain = (flags & 0x01) != 0;
      final qos = (flags >> 1) & 0x03;
      final topic = _readString(packet.body, index);
      index = topic.nextIndex;

      var packetId = 0;
      if (qos > 0) {
        packetId = (packet.body[index] << 8) | packet.body[index + 1];
        index += 2;
      }

      final payloadBytes = Uint8List.fromList(packet.body.sublist(index));
      final payloadText = utf8.decode(payloadBytes, allowMalformed: true);

      if (retain) {
        if (payloadBytes.isEmpty) {
          _retainedMessages.remove(topic.value);
        } else {
          _retainedMessages[topic.value] = _RetainedMessage(
            topic: topic.value,
            payload: payloadBytes,
            qos: qos,
          );
        }
      }

      logManager.append(
        config,
        direction: BrokerLogDirection.inbound,
        topic: topic.value,
        payload: payloadText,
        clientId: connection.clientId ?? '',
        message: 'PUBLISH QoS$qos',
      );

      _fanOutPublish(
        topic: topic.value,
        payload: payloadBytes,
        qos: qos,
        retained: retain,
      );

      if (qos == 1) {
        final pubAck = [0x40, 0x02, packetId >> 8, packetId & 0xFF];
        _sendPacket(
          connection,
          pubAck,
          direction: BrokerLogDirection.outbound,
          topic: topic.value,
          clientId: connection.clientId ?? '',
          message: 'PUBACK',
        );
      }

      _emitState();
    } catch (error) {
      logManager.append(
        config,
        direction: BrokerLogDirection.system,
        clientId: connection.clientId ?? '',
        message: 'PUBLISH parse error: $error',
      );
    }
  }

  void _handlePubAck(_ClientConnection connection, Uint8List body) {
    if (body.length < 2) {
      return;
    }
    final packetId = (body[0] << 8) | body[1];
    logManager.append(
      config,
      direction: BrokerLogDirection.system,
      clientId: connection.clientId ?? '',
      message: 'PUBACK received for packet $packetId.',
    );
  }

  void _fanOutPublish({
    required String topic,
    required Uint8List payload,
    required int qos,
    required bool retained,
  }) {
    final targets = <_ClientConnection, int>{};

    for (final entry in _subscriptions.entries) {
      if (!_topicMatches(entry.key, topic)) {
        continue;
      }
      for (final subscription in entry.value) {
        final currentQos = targets[subscription.connection] ?? 0;
        targets[subscription.connection] = max(currentQos, subscription.qos);
      }
    }

    for (final entry in targets.entries) {
      _publishToConnection(
        entry.key,
        topic: topic,
        payload: payload,
        qos: min(entry.value, qos),
        retained: retained,
      );
    }
  }

  void _publishToConnection(
    _ClientConnection connection, {
    required String topic,
    required Uint8List payload,
    required int qos,
    required bool retained,
  }) {
    final topicBytes = utf8.encode(topic);
    final variableHeader = <int>[
      topicBytes.length >> 8,
      topicBytes.length & 0xFF,
      ...topicBytes,
    ];
    if (qos > 0) {
      final packetId = _nextPacketId();
      variableHeader
        ..add(packetId >> 8)
        ..add(packetId & 0xFF);
    }

    final body = <int>[...variableHeader, ...payload];
    final header = 0x30 | (qos << 1) | (retained ? 0x01 : 0x00);
    _sendPacket(
      connection,
      [header, ..._encodeRemainingLength(body.length), ...body],
      direction: BrokerLogDirection.outbound,
      topic: topic,
      payload: utf8.decode(payload, allowMalformed: true),
      clientId: connection.clientId ?? '',
      message: 'PUBLISH QoS$qos',
    );
  }

  void _addSubscription(_ClientConnection connection, String topic, int qos) {
    _removeSubscription(connection, topic);
    _subscriptions
        .putIfAbsent(topic, () => <_Subscription>[])
        .add(_Subscription(connection: connection, topic: topic, qos: qos));
    connection.subscriptions.add(topic);
    logManager.append(
      config,
      direction: BrokerLogDirection.system,
      clientId: connection.clientId ?? '',
      topic: topic,
      message: 'Subscribed with QoS$qos.',
    );
  }

  void _removeSubscription(_ClientConnection connection, String topic) {
    final list = _subscriptions[topic];
    if (list == null) {
      return;
    }
    list.removeWhere((item) => item.connection == connection);
    if (list.isEmpty) {
      _subscriptions.remove(topic);
    }
    connection.subscriptions.remove(topic);
  }

  Future<void> _disconnect(
    _ClientConnection connection,
    String reason, {
    bool closeSocket = false,
  }) async {
    final existing = _connections.remove(connection.socket);
    if (existing == null) {
      return;
    }
    connection.keepAliveTimer?.cancel();
    for (final topic in connection.subscriptions.toList()) {
      _removeSubscription(connection, topic);
    }
    if (closeSocket) {
      await connection.socket.close();
    } else {
      connection.socket.destroy();
    }

    logManager.append(
      config,
      direction: BrokerLogDirection.system,
      clientId: connection.clientId ?? '',
      message: reason,
    );
    _emitState();
  }

  void _startKeepAliveMonitor(_ClientConnection connection) {
    connection.keepAliveTimer?.cancel();
    if (connection.keepAliveSeconds <= 0) {
      return;
    }
    final period = max(2, connection.keepAliveSeconds);
    connection.keepAliveTimer = Timer.periodic(Duration(seconds: period), (
      timer,
    ) {
      final diff = DateTime.now().difference(connection.lastPacketAt).inSeconds;
      if (diff > (connection.keepAliveSeconds * 1.5).round()) {
        _disconnect(connection, 'KeepAlive timeout.');
      }
    });
  }

  void _sendConnAck(_ClientConnection connection, int returnCode) {
    _sendPacket(
      connection,
      [0x20, 0x02, 0x00, returnCode],
      direction: BrokerLogDirection.outbound,
      clientId: connection.clientId ?? '',
      message: 'CONNACK $returnCode',
    );
  }

  void _sendPacket(
    _ClientConnection connection,
    List<int> bytes, {
    required BrokerLogDirection direction,
    String topic = '',
    String payload = '',
    String clientId = '',
    String message = '',
  }) {
    connection.socket.add(bytes);
    _logRaw(connection, Uint8List.fromList(bytes), incoming: false);
    logManager.append(
      config,
      direction: direction,
      topic: topic,
      payload: payload,
      clientId: clientId,
      message: message,
    );
  }

  void _logRaw(
    _ClientConnection connection,
    Uint8List data, {
    required bool incoming,
  }) {
    logManager.append(
      config,
      direction: BrokerLogDirection.system,
      clientId: connection.clientId ?? '',
      topic: '__raw__',
      payload: _toHex(data),
      message: incoming ? 'RAW IN' : 'RAW OUT',
    );
  }

  List<int> _encodeRemainingLength(int length) {
    final encoded = <int>[];
    var value = length;
    do {
      var digit = value % 128;
      value ~/= 128;
      if (value > 0) {
        digit |= 0x80;
      }
      encoded.add(digit);
    } while (value > 0);
    return encoded;
  }

  _ReadStringResult _readString(Uint8List bytes, int index) {
    final result = _readBytes(bytes, index);
    return _ReadStringResult(
      value: utf8.decode(result.value, allowMalformed: true),
      nextIndex: result.nextIndex,
    );
  }

  _ReadBytesResult _readBytes(Uint8List bytes, int index) {
    if (index + 2 > bytes.length) {
      throw const FormatException('Unexpected packet end.');
    }
    final length = (bytes[index] << 8) | bytes[index + 1];
    final start = index + 2;
    final end = start + length;
    if (end > bytes.length) {
      throw const FormatException('MQTT string length exceeds packet.');
    }
    return _ReadBytesResult(
      value: Uint8List.fromList(bytes.sublist(start, end)),
      nextIndex: end,
    );
  }

  bool _topicMatches(String filter, String topic) {
    final filterLevels = filter.split('/');
    final topicLevels = topic.split('/');

    for (var index = 0; index < filterLevels.length; index += 1) {
      final filterLevel = filterLevels[index];
      if (filterLevel == '#') {
        return true;
      }
      if (index >= topicLevels.length) {
        return false;
      }
      if (filterLevel != '+' && filterLevel != topicLevels[index]) {
        return false;
      }
    }

    return filterLevels.length == topicLevels.length;
  }

  int _nextPacketId() {
    _packetSeed += 1;
    if (_packetSeed > 65535) {
      _packetSeed = 1;
    }
    return _packetSeed;
  }

  String _toHex(Uint8List bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }

  void _touch() {
    _setState(_state.copyWith(lastActivityAt: DateTime.now()));
  }

  void _emitState() {
    final clients =
        _connections.values
            .where((connection) => connection.clientId != null)
            .map(
              (connection) => BrokerClientSnapshot(
                clientId: connection.clientId!,
                ipAddress: connection.ipAddress,
                connectedAt: connection.connectedAt,
                lastPacketAt: connection.lastPacketAt,
                subscriptionsCount: connection.subscriptions.length,
                packetCount: connection.packetCount,
              ),
            )
            .toList()
          ..sort((a, b) => a.clientId.compareTo(b.clientId));

    _setState(
      _state.copyWith(
        connectedClients: clients.length,
        clients: clients,
        lastActivityAt: DateTime.now(),
      ),
    );
  }

  void _setState(BrokerRuntimeState state) {
    _state = state;
    onStateChanged(_state);
  }

  void _fail(String message) {
    logManager.append(
      config,
      direction: BrokerLogDirection.system,
      message: message,
    );
    _setState(
      _state.copyWith(
        status: BrokerStatus.error,
        errorMessage: message,
        lastActivityAt: DateTime.now(),
      ),
    );
  }
}

class _ClientConnection {
  _ClientConnection({
    required this.socket,
    required this.ipAddress,
    required this.connectedAt,
  }) : lastPacketAt = connectedAt;

  final Socket socket;
  final String ipAddress;
  final DateTime connectedAt;
  final List<int> buffer = <int>[];
  final Set<String> subscriptions = <String>{};

  String? clientId;
  bool cleanSession = true;
  int keepAliveSeconds = 0;
  int packetCount = 0;
  DateTime lastPacketAt;
  Timer? keepAliveTimer;
}

class _Subscription {
  const _Subscription({
    required this.connection,
    required this.topic,
    required this.qos,
  });

  final _ClientConnection connection;
  final String topic;
  final int qos;
}

class _RetainedMessage {
  const _RetainedMessage({
    required this.topic,
    required this.payload,
    required this.qos,
  });

  final String topic;
  final Uint8List payload;
  final int qos;
}

class _MqttPacket {
  const _MqttPacket({required this.header, required this.body});

  final int header;
  final Uint8List body;
}

class _ReadStringResult {
  const _ReadStringResult({required this.value, required this.nextIndex});

  final String value;
  final int nextIndex;
}

class _ReadBytesResult {
  const _ReadBytesResult({required this.value, required this.nextIndex});

  final Uint8List value;
  final int nextIndex;
}
