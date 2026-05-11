import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../model/sensor_data.dart';

class MqttService extends ChangeNotifier {
  // — Altere para o IP do seu broker MQTT (ex: Mosquitto rodando no PC) —
  static const _broker   = 'test.mosquitto.org';
  static const _port     = 1883;
  static const _clientId = 'app-djmr-${Random().nextInt(10000)}';

  // Tópicos MQTT
  static const _topicSubscribe = 'horta/irrigation_djmr/#'; 
  // Tópico para o app enviar comandos PARA a ESP32
  static const _topicComando   = 'horta/irrigation_djmr/comando';

  late final MqttServerClient _client;
  bool isConnected = false;

  String umidadeSolo = "0";
  String temperaturaAr = "0.0";
  String statusBomba = "DESLIGADA";

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

  // Roteamento de Mensagens
  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      final topic = msg.topic;
      final payload = msg.payload as MqttPublishMessage;
      final textoRecebido = MqttPublishPayload.bytesToStringAsString(
        payload.payload.message,
      );

      // Verifica de qual sub-tópico a mensagem veio e atualiza a variável certa
      if (topic == 'horta/irrigation_djmr/solo') {
        umidadeSolo = textoRecebido;
      } 
      else if (topic == 'horta/irrigation_djmr/temperatura') {
        temperaturaAr = textoRecebido;
      } 
      else if (topic == 'horta/irrigation_djmr/bomba/status') {
        statusBomba = textoRecebido;
      }

      // Notifica as telas do Flutter para se redesenharem com os novos valores
      notifyListeners(); 
    }
  }

  void publishIrrigate(bool irrigate) {
    if (!isConnected) {
      debugPrint('[MQTT] Não conectado — comando ignorado.');
      return;
    }

    final comandoTexto = ligarBomba ? "LIGAR" : "DESLIGAR";
    final builder = MqttClientPayloadBuilder()..addString(comandoTexto);
    
    _client.publishMessage(
      _topicComando,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    debugPrint('[MQTT] Comando enviado: $comandoTexto');
  }

  @override
  void dispose() {
    _client.disconnect();
    super.dispose();
  }
}
