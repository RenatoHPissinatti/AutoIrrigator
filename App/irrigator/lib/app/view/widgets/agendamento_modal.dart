import 'package:flutter/material.dart';
import '../../model/schedule.dart';

class AgendamentoModal extends StatefulWidget {
  const AgendamentoModal({super.key});

  @override
  State<AgendamentoModal> createState() => _AgendamentoModalState();
}

class _AgendamentoModalState extends State<AgendamentoModal> {
  static const _darkGreen = Color(0xFF1B3826);
  static const _accentGreen = Color(0xFF52B788);

  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;

  int _hour = 7;
  int _minute = 30;
  int _durationIndex = 1;
  final List<bool> _days = [true, true, true, true, true, false, false];

  final List<String> _dayLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
  final List<String> _durations = ['5 min', '15 min', '30 min', '1 h'];
  final List<int> _durationValues = [5, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final schedule = Schedule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      hour: _hour,
      minute: _minute,
      days: List.unmodifiable(_days),
      durationMinutes: _durationValues[_durationIndex],
    );
    Navigator.of(context).pop(schedule);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Novo agendamento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // — Horário —
            Text('Horário',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWheel(
                  controller: _hourCtrl,
                  itemCount: 24,
                  label: (i) => i.toString().padLeft(2, '0'),
                  onChanged: (i) => setState(() => _hour = i),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':',
                      style: TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                _buildWheel(
                  controller: _minuteCtrl,
                  itemCount: 60,
                  label: (i) => i.toString().padLeft(2, '0'),
                  onChanged: (i) => setState(() => _minute = i),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // — Dias da semana —
            Text('Dias da semana',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final active = _days[i];
                return GestureDetector(
                  onTap: () => setState(() => _days[i] = !_days[i]),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: active ? _darkGreen : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _dayLabels[i],
                        style: TextStyle(
                          color: active ? Colors.white : Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // — Duração da irrigação —
            Text('Duração da irrigação',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_durations.length, (i) {
                final selected = _durationIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _durationIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _accentGreen : Colors.grey[300]!,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        _durations[i],
                        style: TextStyle(
                          color: selected ? _accentGreen : Colors.black54,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // — Botão salvar —
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Salvar agendamento'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 72,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black87, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 48,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.002,
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, i) => Center(
                child: Text(
                  label(i),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
