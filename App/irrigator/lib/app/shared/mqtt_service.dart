import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService extends ChangeNotifier {
  // HiveMQ Cloud — preencha com o Cluster URL do console.hivemq.cloud
  static const _broker   = '237d802ef6b84b83847c6f83e6cf17c4.s1.eu.hivemq.cloud';
  static const _port     = 8883;
  static const _user     = 'brainstorm_humano';
  static const _pass     = 'Brainstorm123@';
  final String _clientId = 'app-djmr-${Random().nextInt(10000)}';

  // Tópicos MQTT
  static const _topicSubscribe = 'horta/irrigation_djmr/#'; 
  // Tópico para o app enviar comandos PARA a ESP32
  static const _topicComando   = 'horta/irrigation_djmr/comando';

  late final MqttServerClient _client;
  bool isConnected = false;
  Timer? _reconnectTimer;

  String umidadeSolo = "0";
  String temperaturaAr = "0.0";
  String statusBomba = "DESLIGADA";

  MqttService() {
    _client = MqttServerClient.withPort(_broker, _clientId, _port);
    _client.logging(on: true);
    _client.keepAlivePeriod = 20;
    _client.secure = true; // TLS obrigatório no HiveMQ Cloud (porta 8883)
    _client.onConnected    = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .authenticateAs(_user, _pass)
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
      _client.subscribe(_topicSubscribe, MqttQos.atLeastOnce);
      _client.updates?.listen(_onMessage);
    }
  }

  void _onConnected() {
    isConnected = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    notifyListeners();
    debugPrint('[MQTT] Conectado ao broker!');
  }

  void _onDisconnected() {
    isConnected = false;
    notifyListeners();
    debugPrint('[MQTT] Desconectado do broker.');
    _reconnectTimer ??= Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!isConnected) await connect();
    });
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

    final comandoTexto = irrigate ? "LIGAR" : "DESLIGAR";
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
    _reconnectTimer?.cancel();
    _client.disconnect();
    super.dispose();
  }
}
