import 'package:flutter/foundation.dart';
import '../model/schedule.dart';

class AgendaViewModel extends ChangeNotifier {
  final List<Schedule> _schedules = [
    const Schedule(
      id: '1',
      hour: 6,
      minute: 0,
      days: [true, true, true, true, true, false, false],
      durationMinutes: 20,
    ),
    const Schedule(
      id: '2',
      hour: 18,
      minute: 30,
      days: [false, false, false, false, false, true, true],
      durationMinutes: 15,
    ),
  ];

  List<Schedule> get schedules => List.unmodifiable(_schedules);

  int get activeCount => _schedules.length;

  void addSchedule(Schedule schedule) {
    _schedules.add(schedule);
    // ordenar por horário
    _schedules.sort((a, b) {
      final aMinutes = a.hour * 60 + a.minute;
      final bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });
    notifyListeners();
  }

  void removeSchedule(String id) {
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
