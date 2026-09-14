import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_logo.dart';
import 'pomodoro_screen.dart';
import 'sessoes_screen.dart';
import 'materias_screen.dart';
import 'nova_sessao_screen.dart';
import 'perfil_screen.dart';

const primary = Color(0xFF2563EB);
const ink = Color(0xFF171627);
const muted = Color(0xFF777588);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardRecord> _future;
  RealtimeChannel? _channel;
  String _chartPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _load();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _channel = Supabase.instance.client
          .channel('dashboard-${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'study_sessions',
            callback: (_) => _reload(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'weekly_goals',
            callback: (_) => _reload(),
          )
          .subscribe();
    }
  }

  void _load() {
    _future = DatabaseService.instance.fetchDashboard();
  }

  void _reload() {
    if (mounted) setState(() => _load());
  }

  Future<void> _editGoal(int? currentMinutes) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _GoalEditorDialog(currentMinutes: currentMinutes),
    );
    if (result == null) return;
    try {
      if (result == -1) {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remover meta semanal?'),
            content: const Text(
              'A meta desta semana será removida. Suas sessões e horas estudadas serão mantidas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remover'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await DatabaseService.instance.removeCurrentWeeklyGoal();
      } else {
        await DatabaseService.instance.saveCurrentWeeklyGoal(result);
      }
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar a meta semanal.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_channel != null) Supabase.instance.client.removeChannel(_channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    final fullName = metadata?['full_name']?.toString().trim();
    final firstName = fullName == null || fullName.isEmpty
        ? 'Estudante'
        : fullName.split(' ').first;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      bottomNavigationBar: _BottomNav(onReturn: _reload),
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
                    onNewSession: () async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NovaSessaoScreen(),
                        ),
                      );
                      if (saved == true) _reload();
                    },
                  ),
                  const SizedBox(height: 28),
                  _Greeting(firstName: firstName),
                  const SizedBox(height: 5),
                  const Text(
                    'Continue firme! Cada sessão te aproxima dos seus objetivos.',
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                  const SizedBox(height: 22),
                  FutureBuilder<DashboardRecord>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: TextButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text(
                              'Tentar carregar os dados novamente',
                            ),
                          ),
                        );
                      }
                      final data = _DashboardView.fromRecord(snapshot.data!);
                      return Column(
                        children: [
                          _SummaryGrid(
                            data: data,
                            onEditGoal: () => _editGoal(data.goalMinutes),
                          ),
                          const SizedBox(height: 18),
                          _WeeklyChart(
                            sessions: data.allSessions,
                            period: _chartPeriod,
                            onPeriodChanged: (value) =>
                                setState(() => _chartPeriod = value),
                          ),
                          const SizedBox(height: 18),
                          _GoalCard(
                            data: data,
                            onEditGoal: () => _editGoal(data.goalMinutes),
                          ),
                          const SizedBox(height: 18),
                          _RecentSessions(sessions: data.recentSessions),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalEditorDialog extends StatefulWidget {
  const _GoalEditorDialog({required this.currentMinutes});
  final int? currentMinutes;

  @override
  State<_GoalEditorDialog> createState() => _GoalEditorDialogState();
}

class _GoalEditorDialogState extends State<_GoalEditorDialog> {
  late final TextEditingController _hours;
  late final TextEditingController _minutes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _hours = TextEditingController(
      text: widget.currentMinutes == null
          ? ''
          : '${widget.currentMinutes! ~/ 60}',
    );
    _minutes = TextEditingController(
      text: widget.currentMinutes == null
          ? ''
          : '${widget.currentMinutes! % 60}',
    );
  }

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.currentMinutes == null
          ? 'Definir meta semanal'
          : 'Alterar meta semanal',
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _hours,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Horas'),
                onChanged: (_) => _clearError(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _minutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minutos'),
                onChanged: (_) => _clearError(),
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
    actions: [
      if (widget.currentMinutes != null)
        TextButton.icon(
          onPressed: () => Navigator.pop(context, -1),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remover meta'),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Salvar meta')),
    ],
  );

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  void _submit() {
    final hoursText = _hours.text.trim();
    final minutesText = _minutes.text.trim();
    final hours = hoursText.isEmpty ? 0 : int.tryParse(hoursText);
    final minutes = minutesText.isEmpty ? 0 : int.tryParse(minutesText);
    if (hours == null || minutes == null || hours < 0 || minutes < 0) {
      setState(
        () => _errorMessage =
            'Informe horas e minutos usando apenas números positivos.',
      );
      return;
    }
    if (minutes > 59) {
      setState(
        () => _errorMessage = 'O campo de minutos deve estar entre 0 e 59.',
      );
      return;
    }
    final total = hours * 60 + minutes;
    if (total == 0) {
      setState(
        () => _errorMessage = widget.currentMinutes == null
            ? 'A meta deve ser maior que zero.'
            : 'Para zerar, use o botão “Remover meta”.',
      );
      return;
    }
    if (total > 10080) {
      setState(
        () => _errorMessage = 'A meta semanal não pode ultrapassar 168 horas.',
      );
      return;
    }
    Navigator.pop(context, total);
  }
}

class _Greeting extends StatefulWidget {
  const _Greeting({required this.firstName});

  final String firstName;

  @override
  State<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends State<_Greeting> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (message, icon) = switch (_now.hour) {
      >= 5 && < 12 => ('Bom dia', Icons.wb_sunny_outlined),
      >= 12 && < 18 => ('Boa tarde', Icons.wb_sunny_rounded),
      _ => ('Boa noite', Icons.nightlight_round),
    };
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 9,
      runSpacing: 4,
      children: [
        Text(
          '$message, ${widget.firstName}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        Icon(icon, color: primary, size: 27),
      ],
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
            const AppLogo(size: 46),
            const SizedBox(width: 10),
            const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    text: 'Estuda',
                    style: TextStyle(color: ink),
                  ),
                  TextSpan(
                    text: '+',
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

class _DashboardView {
  const _DashboardView({
    required this.totalSeconds,
    required this.weekSeconds,
    required this.previousWeekSeconds,
    required this.sessionCount,
    required this.days,
    required this.recentSessions,
    required this.allSessions,
    this.goalMinutes,
  });

  factory _DashboardView.fromRecord(DashboardRecord record) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final previousStart = weekStart.subtract(const Duration(days: 7));
    final dayMinutes = List<int>.filled(7, 0);
    var total = 0;
    var week = 0;
    var previous = 0;
    for (final session in record.sessions) {
      total += session.seconds;
      if (!session.startedAt.isBefore(weekStart)) {
        week += session.seconds;
        final index = session.startedAt.weekday - 1;
        if (index >= 0 && index < 7) dayMinutes[index] += session.seconds ~/ 60;
      } else if (!session.startedAt.isBefore(previousStart)) {
        previous += session.seconds;
      }
    }
    return _DashboardView(
      totalSeconds: total,
      weekSeconds: week,
      previousWeekSeconds: previous,
      sessionCount: record.sessions.length,
      days: dayMinutes,
      recentSessions: record.sessions.take(3).toList(),
      allSessions: record.sessions,
      goalMinutes: record.weeklyGoalMinutes,
    );
  }

  final int totalSeconds;
  final int weekSeconds;
  final int previousWeekSeconds;
  final int sessionCount;
  final List<int> days;
  final List<StudySessionRecord> recentSessions;
  final List<StudySessionRecord> allSessions;
  final int? goalMinutes;
  double get goalProgress => goalMinutes == null
      ? 0
      : (weekSeconds / 60 / goalMinutes!).clamp(0.0, 1.0);
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data, required this.onEditGoal});
  final _DashboardView data;
  final VoidCallback onEditGoal;

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
              child: _Metric(
                icon: Icons.schedule_rounded,
                label: 'Horas totais',
                value: _duration(data.totalSeconds),
                change: data.sessionCount == 0
                    ? 'Sem dados'
                    : 'Tempo total estudado',
              ),
            ),
            SizedBox(
              width: width,
              child: _Metric(
                icon: Icons.calendar_month_outlined,
                label: 'Sessões',
                value: '${data.sessionCount}',
                change: data.sessionCount == 1
                    ? 'Sessão concluída'
                    : 'Sessões concluídas',
              ),
            ),
            SizedBox(
              width: width,
              child: _Metric(
                icon: Icons.trending_up_rounded,
                label: 'Esta semana',
                value: _duration(data.weekSeconds),
                change: _weekComparison(
                  data.weekSeconds,
                  data.previousWeekSeconds,
                ),
              ),
            ),
            SizedBox(
              width: width,
              child: _GoalMetric(data: data, onEdit: onEditGoal),
            ),
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
          Text(
            change,
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalMetric extends StatelessWidget {
  const _GoalMetric({required this.data, required this.onEdit});
  final _DashboardView data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      height: 136,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIcon(Icons.track_changes_rounded),
              SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meta', style: TextStyle(color: muted, fontSize: 12)),
                  Text(
                    '${(data.goalProgress * 100).round()}%',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Definir meta semanal',
                icon: const Icon(Icons.edit_outlined, color: primary, size: 19),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: data.goalProgress,
              minHeight: 6,
              backgroundColor: Color(0xFFEDECF2),
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
          const SizedBox(height: 7),
          Text.rich(
            TextSpan(
              style: TextStyle(color: muted, fontSize: 10),
              children: [
                TextSpan(text: 'Meta semanal: '),
                TextSpan(
                  text: data.goalMinutes == null
                      ? 'Não definida'
                      : _minutes(data.goalMinutes!),
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
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

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({
    required this.sessions,
    required this.period,
    required this.onPeriodChanged,
  });
  final List<StudySessionRecord> sessions;
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final chart = _chartData(sessions, period);
    final days = chart.$2;
    final labels = chart.$1;
    final largest = days.fold<int>(0, math.max);
    final scale = math.max(60, ((largest + 59) ~/ 60) * 60);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tempo de estudo ${period == 'week'
                      ? 'na semana'
                      : period == 'month'
                      ? 'no mês'
                      : 'no ano'}',
                  style: TextStyle(
                    color: ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DropdownButton<String>(
                value: period,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'week', child: Text('Semanal')),
                  DropdownMenuItem(value: 'month', child: Text('Mensal')),
                  DropdownMenuItem(value: 'year', child: Text('Anual')),
                ],
                onChanged: (value) {
                  if (value != null) onPeriodChanged(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                SizedBox(
                  width: 27,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      final minutes = (scale * (5 - index) / 5).round();
                      return Text(
                        index == 5
                            ? '0'
                            : '${(minutes / 60).toStringAsFixed(minutes % 60 == 0 ? 0 : 1)}h',
                        style: const TextStyle(color: muted, fontSize: 9),
                      );
                    }),
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
                        children: List.generate(days.length, (index) {
                          final minutes = days[index];
                          final height = 165 * minutes / scale;
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _time(minutes),
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
                                        Color(0xFF3B82F6),
                                        Color(0xFF1D4ED8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  labels[index],
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

  static (List<String>, List<int>) _chartData(
    List<StudySessionRecord> sessions,
    String period,
  ) {
    final now = DateTime.now();
    if (period == 'year') {
      final values = List<int>.filled(12, 0);
      for (final item in sessions) {
        if (item.startedAt.year == now.year) {
          values[item.startedAt.month - 1] += item.seconds ~/ 60;
        }
      }
      return (
        const [
          'Jan',
          'Fev',
          'Mar',
          'Abr',
          'Mai',
          'Jun',
          'Jul',
          'Ago',
          'Set',
          'Out',
          'Nov',
          'Dez',
        ],
        values,
      );
    }
    if (period == 'month') {
      final values = List<int>.filled(5, 0);
      for (final item in sessions) {
        if (item.startedAt.year == now.year &&
            item.startedAt.month == now.month) {
          values[((item.startedAt.day - 1) ~/ 7).clamp(0, 4)] +=
              item.seconds ~/ 60;
        }
      }
      return (const ['1–7', '8–14', '15–21', '22–28', '29+'], values);
    }
    final values = List<int>.filled(7, 0);
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    for (final item in sessions) {
      if (!item.startedAt.isBefore(start)) {
        values[item.startedAt.weekday - 1] += item.seconds ~/ 60;
      }
    }
    return (const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'], values);
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.data, required this.onEditGoal});
  final _DashboardView data;
  final VoidCallback onEditGoal;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              IconButton(
                onPressed: onEditGoal,
                tooltip: 'Alterar meta semanal',
                icon: const Icon(Icons.edit_outlined, color: primary),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (_, constraints) {
              final content = [
                _ProgressRing(progress: data.goalProgress),
                const SizedBox(width: 28, height: 20),
                Expanded(child: _GoalDetails(data: data)),
              ];
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    _ProgressRing(progress: data.goalProgress),
                    const SizedBox(height: 20),
                    _GoalDetails(data: data),
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
  const _ProgressRing({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 126,
      child: CustomPaint(
        painter: _RingPainter(progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
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
  const _GoalDetails({required this.data});
  final _DashboardView data;

  @override
  Widget build(BuildContext context) {
    final goalSeconds = (data.goalMinutes ?? 0) * 60;
    final remaining = math.max(0, goalSeconds - data.weekSeconds);
    return Column(
      children: [
        _Detail(
          Icons.track_changes_rounded,
          'Meta semanal',
          data.goalMinutes == null
              ? 'Não definida'
              : _minutes(data.goalMinutes!),
        ),
        const SizedBox(height: 15),
        _Detail(
          Icons.schedule_rounded,
          'Tempo estudado',
          _duration(data.weekSeconds),
          active: true,
        ),
        const SizedBox(height: 15),
        _Detail(
          Icons.hourglass_bottom_rounded,
          'Faltam',
          data.goalMinutes == null ? '—' : _duration(remaining),
        ),
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
  const _RecentSessions({required this.sessions});
  final List<StudySessionRecord> sessions;

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
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SessoesScreen()),
                ),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'Nenhuma sessão registrada.',
                style: TextStyle(color: muted),
              ),
            ),
          ...List.generate(sessions.length, (index) {
            final item = sessions[index];
            final color = _color(item.color);
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
                          color: color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.menu_book_outlined,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.subject,
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
                                  ? '${_shortDate(item.startedAt)}  •  ${_duration(item.seconds)}'
                                  : (item.source == 'pomodoro'
                                        ? 'Pomodoro'
                                        : 'Sessão manual'),
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
                        Text(
                          _shortDate(item.startedAt),
                          style: const TextStyle(color: muted, fontSize: 9),
                        ),
                        const SizedBox(width: 9),
                        const Icon(
                          Icons.schedule_rounded,
                          color: muted,
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _duration(item.seconds),
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
  const _BottomNav({required this.onReturn});
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return AppBottomNavigation(
      selectedIndex: 0,
      onDestinationSelected: (index) async {
        if (index == 1) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PomodoroScreen()),
          );
        } else if (index == 2) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SessoesScreen()),
          );
        } else if (index == 3) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MateriasScreen()),
          );
        } else if (index == 4) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PerfilScreen()),
          );
        }
        onReturn();
      },
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
        color: Color(0xFFEAF2FF),
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

String _duration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

String _minutes(int minutes) => _duration(minutes * 60);

String _weekComparison(int current, int previous) {
  final difference = current - previous;
  if (difference == 0) return 'Igual à semana passada';
  return '${difference > 0 ? '+' : '-'}${_duration(difference.abs())} vs semana passada';
}

String _shortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

Color _color(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  } catch (_) {
    return primary;
  }
}
