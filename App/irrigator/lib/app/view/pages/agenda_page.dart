import 'package:flutter/material.dart';
import '../../model/schedule.dart';
import '../../view_model/agenda_view_model.dart';
import '../widgets/agendamento_modal.dart';
import '../widgets/bottom_nav_bar.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  static const _darkGreen = Color(0xFF1B3826);
  static const _accentGreen = Color(0xFF52B788);
  static const _bgColor = Color(0xFFF2EDE4);

  static const _dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  late final AgendaViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AgendaViewModel();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _openModal() async {
    final result = await showDialog<Schedule>(
      context: context,
      builder: (_) => const AgendamentoModal(),
    );
    if (result != null) _vm.addSchedule(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScheduleList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/home');
              case 2:
                Navigator.pushReplacementNamed(context, '/historico');
              case 3:
                Navigator.pushReplacementNamed(context, '/config');
            }
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _darkGreen,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Agendamentos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Online',
                    style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_vm.activeCount} ativos • Jardim',
            style: const TextStyle(color: _accentGreen, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Programados',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              ...List.generate(_vm.schedules.length, (i) {
                final isLast = i == _vm.schedules.length - 1;
                return Column(
                  children: [
                    _buildScheduleItem(_vm.schedules[i]),
                    if (!isLast) Divider(height: 1, color: Colors.grey[200]),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildScheduleItem(Schedule schedule) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            schedule.timeFormatted,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Duração: ${schedule.durationLabel}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 6),
                _buildDaysRow(schedule.days),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysRow(List<bool> days) {
    return Row(
      children: List.generate(7, (i) {
        final active = days[i];
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            _dayNames[i],
            style: TextStyle(
              color: active ? _accentGreen : Colors.grey[400],
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _openModal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _accentGreen,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Text(
            '+ Novo agendamento',
            style: TextStyle(
              color: _accentGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
