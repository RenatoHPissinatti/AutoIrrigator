import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _darkGreen = Color(0xFF1B3826);
  static const _cardGreen = Color(0xFF2D5040);
  static const _brightGreen = Color(0xFF52D98D);
  static const _accentGreen = Color(0xFF52B788);
  static const _bgColor = Color(0xFFF2EDE4);

  bool _sistemaLigado = true;
  int _selectedTimeIndex = 1;
  bool _isIrrigating = false;
  int _elapsedSeconds = 0;
  int _totalSeconds = 0;
  DateTime? _startTime;
  Timer? _timer;

  final List<String> _tempos = ['5 min', '15 min', '30 min', '1 h'];
  final List<int> _temposEmSegundos = [300, 900, 1800, 3600];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startIrrigation() {
    setState(() {
      _isIrrigating = true;
      _elapsedSeconds = 0;
      _totalSeconds = _temposEmSegundos[_selectedTimeIndex];
      _startTime = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_elapsedSeconds >= _totalSeconds) {
        _stopIrrigation();
      } else {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _stopIrrigation() {
    _timer?.cancel();
    setState(() {
      _isIrrigating = false;
      _elapsedSeconds = 0;
      _totalSeconds = 0;
      _startTime = null;
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatStartTime() {
    if (_startTime == null) return '';
    final h = _startTime!.hour.toString().padLeft(2, '0');
    final m = _startTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  _buildControle(),
                  const SizedBox(height: 20),
                  _buildProgramacao(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.pushReplacementNamed(context, '/agenda');
            case 2:
              Navigator.pushReplacementNamed(context, '/historico');
            case 3:
              Navigator.pushReplacementNamed(context, '/config');
          }
        },
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
                'AutoIrrigator',
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
          const Text(
            'Jardim',
            style: TextStyle(color: _accentGreen, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSensorCard('68%', 'Umidade do\nsolo'),
              const SizedBox(width: 10),
              _buildSensorCard('27°C', 'Temperatura'),
              const SizedBox(width: 10),
              _buildSensorCard('52%', 'Umidade do\nar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: _cardGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: _brightGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Controle',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // — cabeçalho do card (sempre visível) —
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8F3DC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Color(0xFF2D6A4F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sistema ligado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _isIrrigating
                              ? 'Manual • iniciado às ${_formatStartTime()}'
                              : 'Em espera - próximo às 06:00',
                          style: TextStyle(
                            color: _isIrrigating
                                ? _accentGreen
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _sistemaLigado,
                    onChanged: (v) => setState(() => _sistemaLigado = v),
                    activeThumbColor: _darkGreen,
                    activeTrackColor: _accentGreen,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // — estado: irrigando —
              if (_isIrrigating) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tempo restante',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    Text(
                      _formatTime(_totalSeconds - _elapsedSeconds),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _totalSeconds > 0
                        ? _elapsedSeconds / _totalSeconds
                        : 0,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_accentGreen),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatTime(_elapsedSeconds)} decorridos',
                      style: const TextStyle(
                        color: _accentGreen,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${_tempos[_selectedTimeIndex]} no total',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _stopIrrigation,
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('Parar irrigação'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              // — estado: em espera —
              if (!_isIrrigating) ...[
                Text(
                  'Irrigar agora por quanto tempo ?',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(_tempos.length, (i) {
                    final selected = _selectedTimeIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTimeIndex = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? _accentGreen
                                  : Colors.grey[300]!,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            _tempos[i],
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sistemaLigado ? _startIrrigation : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        Text('Irrigar agora • ${_tempos[_selectedTimeIndex]}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgramacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isIrrigating ? 'Hoje' : 'Programação de hoje',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              _buildScheduleItem('06:00', 'Manhã', '20 min • Seg - Sex'),
              Divider(height: 1, color: Colors.grey[200]),
              _buildScheduleItem('18:30', 'Tarde', '15 min • Sáb - Dom'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(String hora, String periodo, String detalhe) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            hora,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                periodo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                detalhe,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
