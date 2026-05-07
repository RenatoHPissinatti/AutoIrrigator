import 'dart:async';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  bool sistemaLigado = true;
  int selectedTimeIndex = 1;
  bool isIrrigating = false;
  int elapsedSeconds = 0;
  int totalSeconds = 0;
  DateTime? startTime;

  Timer? _timer;

  final List<String> tempos = ['5 min', '15 min', '30 min', '1 h'];
  final List<int> temposEmSegundos = [300, 900, 1800, 3600];

  double get progress =>
      totalSeconds > 0 ? elapsedSeconds / totalSeconds : 0;

  int get remainingSeconds => totalSeconds - elapsedSeconds;

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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
