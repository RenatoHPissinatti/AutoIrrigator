import 'package:flutter/foundation.dart';

@immutable
class Schedule {
  final String id;
  final int hour;
  final int minute;
  final List<bool> days; // [Seg, Ter, Qua, Qui, Sex, Sáb, Dom]
  final int durationMinutes;

  const Schedule({
    required this.id,
    required this.hour,
    required this.minute,
    required this.days,
    required this.durationMinutes,
  });

  String get label {
    if (hour >= 5 && hour < 12) return 'Manhã';
    if (hour >= 12 && hour < 18) return 'Tarde';
    return 'Noite';
  }

  String get timeFormatted =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get durationLabel =>
      durationMinutes >= 60 ? '${durationMinutes ~/ 60} h' : '$durationMinutes min';
}
