import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_page_header.dart';
import 'dashboard_screen.dart';
import 'materias_screen.dart';
import 'nova_sessao_screen.dart';
import 'perfil_screen.dart';
import 'pomodoro_screen.dart';

const _blue = Color(0xFF2563EB);
const _ink = Color(0xFF171627);
const _muted = Color(0xFF707184);

class SessoesScreen extends StatefulWidget {
  const SessoesScreen({super.key});
  @override
  State<SessoesScreen> createState() => _SessoesScreenState();
}

class _SessoesScreenState extends State<SessoesScreen> {
  String _query = '';
  List<String> _subjectSuggestions = [];
  String _type = 'todos';
  late Future<List<StudySessionRecord>> _future;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSuggestions();
  }

  void _load() {
    _future = DatabaseService.instance.fetchSessions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final subjects = await DatabaseService.instance.fetchSubjects();
      if (mounted) {
        setState(() {
          _subjectSuggestions = subjects.map((item) => item.name).toList();
        });
      }
    } catch (_) {
      // A busca continua funcionando mesmo se as sugestões não carregarem.
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: AppPageHeader(
        title: 'Histórico de sessões',
        compact: compact,
        actionLabel: 'Nova sessão',
        onAction: () => _newSessionMessage(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() => _load());
                await Future.wait([_future, _loadSuggestions()]);
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Acompanhe todas as suas sessões de estudo.',
                    style: TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 18),
                  Autocomplete<String>(
                    optionsBuilder: (value) {
                      final typed = value.text.trim().toLowerCase();
                      if (typed.isEmpty) return const Iterable<String>.empty();
                      return _subjectSuggestions
                          .where((name) => name.toLowerCase().contains(typed))
                          .take(6);
                    },
                    displayStringForOption: (option) => option,
                    onSelected: (option) => setState(() => _query = option),
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) =>
                            TextField(
                              controller: controller,
                              focusNode: focusNode,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              onSubmitted: (_) => onFieldSubmitted(),
                              decoration: const InputDecoration(
                                hintText: 'Buscar matéria...',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final type in ['todos', 'pomodoro', 'manual'])
                        ChoiceChip(
                          label: Text(
                            type == 'todos'
                                ? 'Todos'
                                : type == 'pomodoro'
                                ? 'Pomodoro'
                                : 'Manual',
                          ),
                          selected: _type == type,
                          selectedColor: const Color(0xFFE5EFFF),
                          checkmarkColor: _blue,
                          side: BorderSide(
                            color: _type == type
                                ? _blue
                                : const Color(0xFFE3E1E8),
                          ),
                          labelStyle: TextStyle(
                            color: _type == type ? _blue : _muted,
                            fontWeight: _type == type
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          onSelected: (_) => setState(() => _type = type),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<StudySessionRecord>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return _Message(
                          icon: Icons.cloud_off_outlined,
                          text: 'Não foi possível carregar as sessões.',
                          action: TextButton(
                            onPressed: () => setState(() => _load()),
                            child: const Text('Tentar novamente'),
                          ),
                        );
                      }
                      final query = _query.trim().toLowerCase();
                      final allSessions = snapshot.data ?? [];
                      final sessions = allSessions.where((item) {
                        return (_type == 'todos' || item.source == _type) &&
                            (query.isEmpty ||
                                item.subject.toLowerCase().contains(query));
                      }).toList();
                      return Column(
                        children: [
                          _SessionStats(sessions: allSessions),
                          const SizedBox(height: 16),
                          if (sessions.isEmpty)
                            const _Message(
                              icon: Icons.event_note_outlined,
                              text: 'Nenhuma sessão encontrada.',
                            )
                          else
                            ...sessions.map(
                              (item) => _SessionCard(
                                session: item,
                                onEditSummary: () => _editSummary(item),
                                onDelete: () => _delete(item),
                              ),
                            ),
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
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 2) return;
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (_) => false,
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PomodoroScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MateriasScreen()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PerfilScreen()),
            );
          }
        },
      ),
    );
  }

  Future<void> _newSessionMessage(BuildContext context) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NovaSessaoScreen()),
    );
    if (saved == true && mounted) {
      setState(() => _load());
    }
  }

  Future<void> _delete(StudySessionRecord item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir sessão?'),
        content: Text('A sessão de ${item.subject} será removida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseService.instance.deleteSession(item.id);
      if (mounted) setState(() => _load());
    }
  }

  Future<void> _editSummary(StudySessionRecord item) async {
    final summary = await showDialog<String>(
      context: context,
      builder: (_) => _SummaryEditorDialog(initialValue: item.summary ?? ''),
    );
    if (summary == null) return;
    try {
      await DatabaseService.instance.updateSessionSummary(item.id, summary);
      if (mounted) setState(() => _load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a anotação.')),
        );
      }
    }
  }
}

class _SummaryEditorDialog extends StatefulWidget {
  const _SummaryEditorDialog({required this.initialValue});
  final String initialValue;

  @override
  State<_SummaryEditorDialog> createState() => _SummaryEditorDialogState();
}

class _SummaryEditorDialogState extends State<_SummaryEditorDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initialValue.isEmpty ? 'Adicionar anotação' : 'Editar anotação',
    ),
    content: SizedBox(
      width: 460,
      child: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 1000,
        maxLines: 7,
        decoration: const InputDecoration(
          hintText: 'Escreva um resumo, tópicos estudados ou dúvidas...',
          alignLabelWithHint: true,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: () => Navigator.pop(context, _controller.text),
        icon: const Icon(Icons.save_outlined),
        label: const Text('Salvar'),
      ),
    ],
  );
}

class _SessionStats extends StatelessWidget {
  const _SessionStats({required this.sessions});

  final List<StudySessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = sessions.fold<int>(
      0,
      (total, item) => total + item.seconds,
    );
    final streak = _currentStreak(sessions);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 620
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              width: width,
              icon: Icons.schedule,
              label: 'Total de horas',
              value: _SessionCard.duration(totalSeconds),
            ),
            _StatCard(
              width: width,
              icon: Icons.calendar_month_outlined,
              label: 'Total de sessões',
              value: '${sessions.length}',
            ),
            _StatCard(
              width: width,
              icon: Icons.track_changes,
              label: 'Dias consecutivos',
              value: '$streak ${streak == 1 ? 'dia' : 'dias'}',
            ),
          ],
        );
      },
    );
  }

  int _currentStreak(List<StudySessionRecord> records) {
    final days = records
        .map(
          (item) => DateTime(
            item.startedAt.year,
            item.startedAt.month,
            item.startedAt.day,
          ),
        )
        .toSet();
    if (days.isEmpty) return 0;
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEAF2FF),
              child: Icon(icon, color: _blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onEditSummary,
    required this.onDelete,
  });
  final StudySessionRecord session;
  final VoidCallback onEditSummary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(Icons.menu_book_outlined, color: _blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.subject,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        session.source == 'pomodoro'
                            ? 'Pomodoro'
                            : 'Sessão manual',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(duration(session.seconds)),
                IconButton(
                  tooltip: session.summary?.trim().isNotEmpty == true
                      ? 'Editar anotação'
                      : 'Adicionar anotação',
                  onPressed: onEditSummary,
                  icon: Icon(
                    session.summary?.trim().isNotEmpty == true
                        ? Icons.edit_note_rounded
                        : Icons.note_add_outlined,
                    color: _blue,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _date(session.startedAt),
              style: const TextStyle(color: _muted),
            ),
            if (session.summary?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                session.summary!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return hours > 0
        ? '${hours}h ${minutes.toString().padLeft(2, '0')}m'
        : '${minutes}min';
  }

  static String _date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(icon, size: 52, color: _muted),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        ?action,
      ],
    ),
  );
}
