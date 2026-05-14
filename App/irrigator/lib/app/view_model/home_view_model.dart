import 'dart:async';
import 'package:flutter/foundation.dart';
import '../shared/mqtt_service.dart';

class HomeViewModel extends ChangeNotifier {
  late final MqttService _mqttService;

  bool sistemaLigado = true;
  int selectedTimeIndex = 1;
  bool isIrrigating = false;
  int elapsedSeconds = 0;
  int totalSeconds = 0;
  DateTime? startTime;
  Timer? _timer;

  final List<String> tempos = ['5 min', '15 min', '30 min', '1 h'];
  final List<int> temposEmSegundos = [300, 900, 1800, 3600];

  // --- GETTERS ATUALIZADOS PARA A NOVA ARQUITETURA MQTT ---
  bool get isConnected => _mqttService.isConnected;
  
  // Em vez de retornar um objeto SensorData, retornamos as strings individuais
  String get umidade => _mqttService.umidadeSolo;
  String get temperatura => _mqttService.temperaturaAr;
  String get statusBomba => _mqttService.statusBomba;

  double get progress =>
      totalSeconds > 0 ? elapsedSeconds / totalSeconds : 0;

  int get remainingSeconds => totalSeconds - elapsedSeconds;

  HomeViewModel() {
    _mqttService = MqttService();
    // O addListener garante que quando o MQTT receber dados novos, 
    // o ViewModel avisará a tela para se redesenhar.
    _mqttService.addListener(notifyListeners);
    _mqttService.connect();
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String formatStartTime() {
    if (startTime == null) return '';
    final h = startTime!.hour.toString().padLeft(2, '0');
    final m = startTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void toggleSistema(bool value) {
    sistemaLigado = value;
    notifyListeners();
  }

  void selectTime(int index) {
    selectedTimeIndex = index;
    notifyListeners();
  }

  void startIrrigation() {
    isIrrigating = true;
    elapsedSeconds = 0;
    totalSeconds = temposEmSegundos[selectedTimeIndex];
    startTime = DateTime.now();
    notifyListeners();

    // Envia o comando "LIGAR" para a ESP32
    _mqttService.publishIrrigate(true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (elapsedSeconds >= totalSeconds) {
        stopIrrigation();
      } else {
        elapsedSeconds++;
        notifyListeners();
      }
    });
  }

  void stopIrrigation() {
    _timer?.cancel();
    isIrrigating = false;
    elapsedSeconds = 0;
    totalSeconds = 0;
    startTime = null;
    notifyListeners();

    // Envia o comando "DESLIGAR" para a ESP32
    _mqttService.publishIrrigate(false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mqttService.removeListener(notifyListeners);
    _mqttService.dispose();
    super.dispose();
  }
}