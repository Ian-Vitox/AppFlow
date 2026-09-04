import 'dart:math' as math;

import 'package:flutter/material.dart';

const primary = Color(0xFF6547ED);
const ink = Color(0xFF171627);
const muted = Color(0xFF777588);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      bottomNavigationBar: const _BottomNav(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    onNewSession: () => ScaffoldMessenger.of(context)
                        .showSnackBar(
                          const SnackBar(
                            content: Text('Nova sessão será conectada depois.'),
                          ),
                        ),
                  ),
                  const SizedBox(height: 28),
                  const Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 9,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Boa noite, Juan',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      Icon(Icons.nightlight_round, color: primary, size: 27),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Continue firme! Cada sessão te aproxima dos seus objetivos.',
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                  const SizedBox(height: 22),
                  const _SummaryGrid(),
                  const SizedBox(height: 18),
                  const _WeeklyChart(),
                  const SizedBox(height: 18),
                  const _GoalCard(),
                  const SizedBox(height: 18),
                  const _RecentSessions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNewSession});
  final VoidCallback onNewSession;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final compact = constraints.maxWidth < 340;
        final logo = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0ECFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: primary,
                size: 27,
              ),
            ),
            const SizedBox(width: 10),
            const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    text: 'Study',
                    style: TextStyle(color: ink),
                  ),
                  TextSpan(
                    text: 'Flow',
                    style: TextStyle(color: primary),
                  ),
                ],
              ),
            ),
          ],
        );
        final button = FilledButton.icon(
          onPressed: onNewSession,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova sessão'),
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [logo, const SizedBox(height: 12), button],
          );
        }
        return Row(children: [logo, const Spacer(), button]);
      },
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final singleColumn = constraints.maxWidth < 390;
        final width = singleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: const _Metric(
                icon: Icons.schedule_rounded,
                label: 'Horas totais',
                value: '12h 30m',
                change: '+2h 15m',
              ),
            ),
            SizedBox(
              width: width,
              child: const _Metric(
                icon: Icons.calendar_month_outlined,
                label: 'Sessões',
                value: '18',
                change: '+4',
              ),
            ),
            SizedBox(
              width: width,
              child: const _Metric(
                icon: Icons.trending_up_rounded,
                label: 'Esta semana',
                value: '4h 20m',
                change: '+1h 10m',
              ),
            ),
            SizedBox(width: width, child: const _GoalMetric()),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
  });
  final IconData icon;
  final String label;
  final String value;
  final String change;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      height: 136,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIcon(icon),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 10),
              children: [
                TextSpan(
                  text: change,
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: ' em relação à semana passada',
                  style: TextStyle(color: muted),
                ),
              ],
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _GoalMetric extends StatelessWidget {
  const _GoalMetric();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      height: 136,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _CircleIcon(Icons.track_changes_rounded),
              SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meta', style: TextStyle(color: muted, fontSize: 12)),
                  Text(
                    '75%',
                    style: TextStyle(
                      color: ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: .75,
              minHeight: 6,
              backgroundColor: Color(0xFFEDECF2),
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
          const SizedBox(height: 7),
          const Text.rich(
            TextSpan(
              style: TextStyle(color: muted, fontSize: 10),
              children: [
                TextSpan(text: 'Meta semanal: '),
                TextSpan(
                  text: '5h 30m',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart();
  static const days = [
    ('Seg', 70),
    ('Ter', 120),
    ('Qua', 50),
    ('Qui', 90),
    ('Sex', 180),
    ('Sáb', 260),
    ('Dom', 30),
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tempo de estudo na semana',
                  style: TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE3E1E8)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Esta semana',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: muted,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                const SizedBox(
                  width: 27,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('5h', style: TextStyle(color: muted, fontSize: 9)),
                      Text('4h', style: TextStyle(color: muted, fontSize: 9)),
                      Text('3h', style: TextStyle(color: muted, fontSize: 9)),
                      Text('2h', style: TextStyle(color: muted, fontSize: 9)),
                      Text('1h', style: TextStyle(color: muted, fontSize: 9)),
                      Text('0', style: TextStyle(color: muted, fontSize: 9)),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (_) => Container(
                            height: 1,
                            color: const Color(0xFFEDECF2),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: days.map((day) {
                          final height = 165 * day.$2 / 300;
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _time(day.$2),
                                  style: const TextStyle(
                                    color: ink,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 29,
                                  height: height,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF765CF2),
                                        Color(0xFF4F2BE1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  day.$1,
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _time(int minutes) =>
      '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
}

class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Progresso da meta semanal',
                  style: TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (_, constraints) {
              final content = [
                const _ProgressRing(),
                const SizedBox(width: 28, height: 20),
                const Expanded(child: _GoalDetails()),
              ];
              if (constraints.maxWidth < 400) {
                return const Column(
                  children: [
                    _ProgressRing(),
                    SizedBox(height: 20),
                    _GoalDetails(),
                  ],
                );
              }
              return Row(children: content);
            },
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 126,
      height: 126,
      child: CustomPaint(
        painter: _RingPainter(.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '75%',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              Text('concluído', style: TextStyle(color: muted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalDetails extends StatelessWidget {
  const _GoalDetails();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Detail(Icons.track_changes_rounded, 'Meta semanal', '5h 30m'),
        SizedBox(height: 15),
        _Detail(
          Icons.schedule_rounded,
          'Tempo estudado',
          '4h 20m',
          active: true,
        ),
        SizedBox(height: 15),
        _Detail(Icons.hourglass_bottom_rounded, 'Faltam', '1h 10m'),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail(this.icon, this.label, this.value, {this.active = false});
  final IconData icon;
  final String label;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: muted),
        const SizedBox(width: 11),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: ink)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: active ? primary : ink,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RecentSessions extends StatelessWidget {
  const _RecentSessions();
  static const sessions = [
    (
      'Redes de Computadores',
      'Redes',
      '1h 20m',
      Icons.hub_outlined,
      Color(0xFF6847E8),
      Color(0xFFF0EBFF),
    ),
    (
      'Banco de Dados',
      'Banco de Dados',
      '1h 00m',
      Icons.storage_outlined,
      Color(0xFF18799E),
      Color(0xFFE8F6FC),
    ),
    (
      'Desenvolvimento Web',
      'Desenvolvimento',
      '1h 30m',
      Icons.code_rounded,
      Color(0xFF159765),
      Color(0xFFE9FAF1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    return _Panel(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sessões recentes',
                  style: TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('Ver todas')),
            ],
          ),
          ...List.generate(sessions.length, (index) {
            final item = sessions[index];
            return Column(
              children: [
                if (index > 0)
                  const Divider(height: 1, color: Color(0xFFEEEDEF)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: item.$6,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.$4, color: item.$5, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              compact
                                  ? '${item.$2}  •  26/05/2025  •  ${item.$3}'
                                  : item.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!compact) ...[
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: muted,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '26/05/2025',
                          style: TextStyle(color: muted, fontSize: 9),
                        ),
                        const SizedBox(width: 9),
                        const Icon(
                          Icons.schedule_rounded,
                          color: muted,
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.$3,
                          style: const TextStyle(color: muted, fontSize: 9),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        height: 70,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEDE8FF),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10,
            color: states.contains(WidgetState.selected) ? primary : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_rounded),
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
            icon: Icon(Icons.person_outline_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: const BoxDecoration(
        color: Color(0xFFF1EDFF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: primary, size: 25),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.height});
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFEDEDF2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 13,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
