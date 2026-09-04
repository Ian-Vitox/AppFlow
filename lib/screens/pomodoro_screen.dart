import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/pomodoro_controller.dart';

const _blue = Color(0xFF2563EB);
const _ink = Color(0xFF171627);
const _muted = Color(0xFF777588);
const _background = Color(0xFFF8F8FC);

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final _controller = PomodoroController.instance;
  bool _adjustingDuration = false;
  bool _draggingKnob = false;

  static const _subjects = [
    'Desenvolvimento Web',
    'Banco de Dados',
    'Redes de Computadores',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _setAdjustingDuration(bool value) {
    if (_adjustingDuration == value || !mounted) return;
    setState(() => _adjustingDuration = value);
  }

  Offset _knobPosition(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final progress = _controller.remainingSeconds / (60 * 60);
    final angle = math.pi * .16 + math.pi * 1.68 * progress;
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
  }

  void _durationPointerDown(Offset position) {
    if (_controller.durationLocked) {
      _draggingKnob = false;
      _setAdjustingDuration(false);
      _showDurationLockedMessage();
      return;
    }
    if (_controller.mode != 'Pausa personalizada') {
      _showFixedDurationMessage();
      return;
    }
    const size = Size.square(280);
    _draggingKnob = (position - _knobPosition(size)).distance <= 30;
    if (_draggingKnob) _setAdjustingDuration(true);
    _changeDuration(position, size);
  }

  void _durationPointerMove(Offset position) {
    if (_draggingKnob) _changeDuration(position, const Size.square(280));
  }

  void _selectMode(String mode, int minutes) {
    if (_controller.durationLocked) {
      _showDurationLockedMessage();
      return;
    }
    _controller.selectMode(mode, minutes);
  }

  void _showDurationLockedMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Reinicie o cronômetro antes de alterar o tempo da sessão.',
          ),
        ),
      );
  }

  void _showFixedDurationMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione Pausa personalizada para escolher outro tempo.',
          ),
        ),
      );
  }

  void _durationPointerEnd() {
    _draggingKnob = false;
    _setAdjustingDuration(false);
  }

  void _changeDuration(Offset position, Size size) {
    if (_controller.running) return;
    final center = Offset(size.width / 2, size.height / 2);
    var angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    const startAngle = math.pi * .16;
    const sweepAngle = math.pi * 1.68;
    if (angle < startAngle) angle += math.pi * 2;
    final ratio = ((angle - startAngle) / sweepAngle).clamp(0.0, 1.0);
    final minutes = 1 + (ratio * 59).round();
    _controller.changeDuration(minutes);
  }

  String get _clock {
    final minutes = (_controller.remainingSeconds ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final seconds = (_controller.remainingSeconds % 60).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _controller.remainingSeconds / (60 * 60);
    return Scaffold(
      backgroundColor: _background,
      bottomNavigationBar: const _PomodoroNavigation(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: _adjustingDuration
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  const _PageHeader(),
                  const SizedBox(height: 20),
                  _TimerPanel(
                    subject: _controller.subject,
                    subjects: _subjects,
                    onSubjectChanged: (value) {
                      if (value != null) _controller.changeSubject(value);
                    },
                    clock: _clock,
                    mode: _controller.mode,
                    progress: progress,
                    running: _controller.running,
                    onStart: _controller.start,
                    onPause: _controller.pause,
                    onReset: _controller.reset,
                    onModeSelected: _selectMode,
                    onPointerDown: _durationPointerDown,
                    onPointerMove: _durationPointerMove,
                    onPointerEnd: _durationPointerEnd,
                  ),
                  const SizedBox(height: 18),
                  const _TodaySessions(),
                  const SizedBox(height: 18),
                  const _ProductivitySummary(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _StudyLogo(),
        Expanded(
          child: Text(
            'Pomodoro',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          width: 42,
          child: Icon(Icons.more_horiz_rounded, color: _ink, size: 27),
        ),
      ],
    );
  }
}

class _StudyLogo extends StatelessWidget {
  const _StudyLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.menu_book_rounded, color: _blue, size: 27),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
    required this.subject,
    required this.subjects,
    required this.onSubjectChanged,
    required this.clock,
    required this.mode,
    required this.progress,
    required this.running,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onModeSelected,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerEnd,
  });

  final String subject;
  final List<String> subjects;
  final ValueChanged<String?> onSubjectChanged;
  final String clock;
  final String mode;
  final double progress;
  final bool running;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final void Function(String, int) onModeSelected;
  final ValueChanged<Offset> onPointerDown;
  final ValueChanged<Offset> onPointerMove;
  final VoidCallback onPointerEnd;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: subject,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F9F0),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.code_rounded, color: Color(0xFF18A36B)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE7E5EB)),
              ),
            ),
            items: subjects
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onSubjectChanged,
          ),
          const SizedBox(height: 16),
          Center(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => onPointerDown(event.localPosition),
              onPointerMove: (event) => onPointerMove(event.localPosition),
              onPointerUp: (_) => onPointerEnd(),
              onPointerCancel: (_) => onPointerEnd(),
              child: SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: _TimerRingPainter(progress),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          child: Text(
                            clock,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 61,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            mode,
                            style: const TextStyle(
                              color: _blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          running ? 'Mantenha o foco!' : 'Foque até o fim!',
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Toque ou arraste o ponto azul para alterar o tempo',
              style: TextStyle(color: _muted, fontSize: 10),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (_, constraints) {
              final narrow = constraints.maxWidth < 360;
              final buttons = [
                _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Iniciar',
                  primary: true,
                  onPressed: onStart,
                ),
                _ActionButton(
                  icon: Icons.pause_rounded,
                  label: 'Pausar',
                  onPressed: onPause,
                ),
                _ActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Reiniciar',
                  onPressed: onReset,
                ),
              ];
              if (narrow) {
                return Column(
                  children: buttons
                      .map(
                        (button) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: button,
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < buttons.length; index++) ...[
                    Expanded(child: buttons[index]),
                    if (index < buttons.length - 1) const SizedBox(width: 9),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'Escolha o tipo de sessão',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (_, constraints) {
              final modes = [
                _ModeButton(
                  title: 'Pomodoro',
                  minutes: 25,
                  icon: Icons.schedule_rounded,
                  color: _blue,
                  selected: mode == 'Pomodoro',
                  onTap: () => onModeSelected('Pomodoro', 25),
                ),
                _ModeButton(
                  title: 'Pausa curta',
                  minutes: 5,
                  icon: Icons.coffee_outlined,
                  color: const Color(0xFF20AD65),
                  selected: mode == 'Pausa curta',
                  onTap: () => onModeSelected('Pausa curta', 5),
                ),
                _ModeButton(
                  title: 'Pausa longa',
                  minutes: 15,
                  icon: Icons.coffee_outlined,
                  color: const Color(0xFF3398E6),
                  selected: mode == 'Pausa longa',
                  onTap: () => onModeSelected('Pausa longa', 15),
                ),
                _ModeButton(
                  title: 'Pausa personalizada',
                  minutes: mode == 'Pausa personalizada'
                      ? int.parse(clock.split(':').first)
                      : 10,
                  icon: Icons.tune_rounded,
                  color: const Color(0xFF2563EB),
                  selected: mode == 'Pausa personalizada',
                  onTap: () => onModeSelected('Pausa personalizada', 10),
                ),
              ];
              if (constraints.maxWidth < 330) {
                return Column(
                  children: modes
                      .map(
                        (button) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: button,
                          ),
                        ),
                      )
                      .toList(),
                );
              }
              final itemWidth = (constraints.maxWidth - 9) / 2;
              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: modes
                    .map((button) => SizedBox(width: itemWidth, child: button))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label, maxLines: 1),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: primary ? _blue : Colors.white,
          foregroundColor: primary ? Colors.white : _ink,
          side: BorderSide(color: primary ? _blue : const Color(0xFFE3E1E8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.title,
    required this.minutes,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final int minutes;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? _blue : const Color(0xFFE3E1E8),
            width: selected ? 1.6 : 1,
          ),
          color: selected ? const Color(0xFFFBFAFF) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(width: 9),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? _blue : _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$minutes min',
                    style: const TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySessions extends StatelessWidget {
  const _TodaySessions();
  static const sessions = [
    ('Desenvolvimento Web', '09:15'),
    ('Banco de Dados', '11:05'),
    ('Redes de Computadores', '13:20'),
    ('Desenvolvimento Web', '15:30'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sessões de hoje',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('Ver todas')),
            ],
          ),
          ...sessions.map(
            (session) => Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEDECF1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAFBF1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF20AF67),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Pomodoro',
                          style: TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.schedule_rounded, color: _muted, size: 17),
                  const SizedBox(width: 5),
                  Text(
                    session.$2,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.timelapse_rounded, color: _blue, size: 21),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Total de foco',
                    style: TextStyle(color: _ink, fontSize: 12),
                  ),
                ),
                Text(
                  '4h 25min',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductivitySummary extends StatelessWidget {
  const _ProductivitySummary();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.schedule_rounded, 'Foco total', '4h 25min', '+1h 10m vs ontem'),
      (Icons.track_changes_rounded, 'Pomodoros', '6', '+2 vs ontem'),
      (Icons.trending_up_rounded, 'Taxa de foco', '92%', '+8% vs ontem'),
    ];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo de produtividade',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (_, constraints) {
              final narrow = constraints.maxWidth < 430;
              final cards = items
                  .map(
                    (item) => _ProductivityCard(
                      icon: item.$1,
                      label: item.$2,
                      value: item.$3,
                      comparison: item.$4,
                    ),
                  )
                  .toList();
              if (narrow) {
                return Column(
                  children: cards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: SizedBox(width: double.infinity, child: card),
                        ),
                      )
                      .toList(),
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    Expanded(child: cards[index]),
                    if (index < cards.length - 1) const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: _blue, size: 20),
                SizedBox(width: 9),
                Flexible(
                  child: Text(
                    'Excelente trabalho! Continue assim.',
                    style: TextStyle(
                      color: _blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductivityCard extends StatelessWidget {
  const _ProductivityCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.comparison,
  });
  final IconData icon;
  final String label;
  final String value;
  final String comparison;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDECF1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _blue, size: 25),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  comparison,
                  style: const TextStyle(color: _blue, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PomodoroNavigation extends StatelessWidget {
  const _PomodoroNavigation();

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE5EFFF),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? _blue : _muted,
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0 && Navigator.canPop(context)) Navigator.pop(context);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_rounded),
            selectedIcon: Icon(Icons.schedule_rounded),
            label: 'Pomodoro',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Sessões',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Matérias',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Relatórios',
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEBF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A181226),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      math.pi * .16,
      math.pi * 1.68,
      false,
      Paint()
        ..color = const Color(0xFFDCE8FF)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5,
    );
    canvas.drawArc(
      rect,
      math.pi * .16,
      math.pi * 1.68 * progress,
      false,
      Paint()
        ..color = _blue
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5,
    );
    final angle = math.pi * .16 + math.pi * 1.68 * progress;
    final dot = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(dot, 15, Paint()..color = const Color(0x332563EB));
    canvas.drawCircle(dot, 9, Paint()..color = _blue);
    canvas.drawCircle(dot, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
