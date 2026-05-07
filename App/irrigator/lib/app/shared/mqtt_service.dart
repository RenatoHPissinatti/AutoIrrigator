import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../model/sensor_data.dart';

class MqttService extends ChangeNotifier {
  // — Altere para o IP do seu broker MQTT (ex: Mosquitto rodando no PC) —
  static const _broker   = '192.168.1.100';
  static const _port     = 1883;
  static const _clientId = 'autoirrigator-app';

  static const _topicSensores = 'autoirrigator/sensores';
  static const _topicIrrigar  = 'autoirrigator/irrigar';

  late final MqttServerClient _client;

  bool isConnected = false;
  SensorData sensorData = SensorData.empty();

  MqttService() {
    _client = MqttServerClient.withPort(_broker, _clientId, _port);
    _client.logging(on: false);
    _client.keepAlivePeriod = 20;
    _client.onConnected    = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
  }

  Future<void> connect() async {
    try {
      await _client.connect();
    } catch (e) {
      debugPrint('[MQTT] Erro ao conectar: $e');
      _client.disconnect();
      return;
    }

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _client.subscribe(_topicSensores, MqttQos.atLeastOnce);
      _client.updates?.listen(_onMessage);
    }
  }

  void _onConnected() {
    isConnected = true;
    notifyListeners();
    debugPrint('[MQTT] Conectado ao broker!');
  }

  void _onDisconnected() {
    isConnected = false;
    notifyListeners();
    debugPrint('[MQTT] Desconectado do broker.');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      if (msg.topic != _topicSensores) continue;

      final payload = msg.payload as MqttPublishMessage;
      final raw = MqttPublishPayload.bytesToStringAsString(
        payload.payload.message,
      );

      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        sensorData = SensorData.fromJson(json);
        notifyListeners();
      } catch (e) {
        debugPrint('[MQTT] Erro ao parsear sensores: $e');
      }
    }
  }

  void publishIrrigate(bool irrigate) {
    if (!isConnected) {
      debugPrint('[MQTT] Não conectado — comando ignorado.');
      return;
    }
    final builder = MqttClientPayloadBuilder()
      ..addString(irrigate ? '1' : '0');
    _client.publishMessage(
      _topicIrrigar,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    debugPrint('[MQTT] Publicado irrigar: ${irrigate ? "1" : "0"}');
  }

  @override
  void dispose() {
    _client.disconnect();
    super.dispose();
  }
}
