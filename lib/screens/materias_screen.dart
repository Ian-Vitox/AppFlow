import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_page_header.dart';
import 'dashboard_screen.dart';
import 'pomodoro_screen.dart';
import 'perfil_screen.dart';
import 'sessoes_screen.dart';

const _blue = Color(0xFF2563EB);
const _ink = Color(0xFF171627);
const _muted = Color(0xFF707184);

class MateriasScreen extends StatefulWidget {
  const MateriasScreen({super.key});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  late Future<List<SubjectRecord>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = DatabaseService.instance.fetchSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: AppPageHeader(
        title: 'Minhas matérias',
        compact: compact,
        actionLabel: 'Nova matéria',
        onAction: () => _openEditor(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() => _load());
                await _future;
              },
              child: FutureBuilder<List<SubjectRecord>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ScrollableMessage(
                      icon: Icons.cloud_off_outlined,
                      text: 'Não foi possível carregar as matérias.',
                      action: TextButton(
                        onPressed: () => setState(() => _load()),
                        child: const Text('Tentar novamente'),
                      ),
                    );
                  }
                  final subjects = snapshot.data ?? [];
                  final totalSeconds = subjects.fold<int>(
                    0,
                    (total, item) => total + item.studiedSeconds,
                  );
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      _Overview(
                        subjectCount: subjects.length,
                        totalSeconds: totalSeconds,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _openArchivedSubjects,
                          icon: const Icon(Icons.archive_outlined),
                          label: const Text('Matérias arquivadas'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (subjects.isEmpty)
                        const _EmptySubjects()
                      else
                        ...subjects.map(
                          (subject) => _SubjectCard(
                            subject: subject,
                            onEdit: () => _openEditor(subject),
                            onArchive: () => _archive(subject),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 3,
        onDestinationSelected: _navigate,
      ),
    );
  }

  void _navigate(int index) {
    if (index == 3) return;
    final Widget? page = switch (index) {
      0 => const DashboardScreen(),
      1 => const PomodoroScreen(),
      2 => const SessoesScreen(),
      4 => const PerfilScreen(),
      _ => null,
    };
    if (page != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  Future<void> _openEditor([SubjectRecord? subject]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SubjectEditor(subject: subject),
    );
    if (saved == true && mounted) setState(() => _load());
  }

  Future<void> _archive(SubjectRecord subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar matéria?'),
        content: Text('${subject.name} deixará de aparecer na lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseService.instance.archiveSubject(subject.id);
    if (mounted) setState(() => _load());
  }

  Future<void> _openArchivedSubjects() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ArchivedSubjectsSheet(),
    );
    if (changed == true && mounted) setState(() => _load());
  }
}

class _ArchivedSubjectsSheet extends StatefulWidget {
  const _ArchivedSubjectsSheet();

  @override
  State<_ArchivedSubjectsSheet> createState() => _ArchivedSubjectsSheetState();
}

class _ArchivedSubjectsSheetState extends State<_ArchivedSubjectsSheet> {
  late Future<List<SubjectRecord>> _future;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = DatabaseService.instance.fetchArchivedSubjects();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) Navigator.pop(context, _changed);
    },
    child: FractionallySizedBox(
      heightFactor: .88,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6D7DE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Matérias arquivadas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.pop(context, _changed),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                  'Restaure uma matéria para voltar a usá-la. A exclusão só é permitida quando não existem sessões vinculadas.',
                  style: TextStyle(color: _muted),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<SubjectRecord>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Não foi possível carregar as matérias arquivadas.',
                          ),
                        );
                      }
                      final subjects = snapshot.data ?? const [];
                      if (subjects.isEmpty) {
                        return const Center(
                          child: Text('Nenhuma matéria arquivada.'),
                        );
                      }
                      return ListView.separated(
                        itemCount: subjects.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          final color = _parseColor(subject.colorHex);
                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: .12),
                                child: Icon(
                                  Icons.menu_book_outlined,
                                  color: color,
                                ),
                              ),
                              title: Text(
                                subject.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                subject.hasSessions
                                    ? '${subject.sessionCount} sessões vinculadas'
                                    : 'Sem sessões vinculadas',
                              ),
                              trailing: Wrap(
                                spacing: 2,
                                children: [
                                  IconButton(
                                    tooltip: 'Restaurar matéria',
                                    onPressed: () => _restore(subject),
                                    icon: const Icon(Icons.unarchive_outlined),
                                    color: _blue,
                                  ),
                                  IconButton(
                                    tooltip: subject.hasSessions
                                        ? 'Não é possível excluir uma matéria com sessões'
                                        : 'Excluir matéria',
                                    onPressed: subject.hasSessions
                                        ? null
                                        : () => _delete(subject),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _restore(SubjectRecord subject) async {
    try {
      await DatabaseService.instance.restoreSubject(subject.id);
      _changed = true;
      if (mounted) setState(_reload);
    } catch (_) {
      _showMessage(
        'Não foi possível restaurar a matéria. Verifique se já existe outra matéria ativa com o mesmo nome.',
      );
    }
  }

  Future<void> _delete(SubjectRecord subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir matéria definitivamente?'),
        content: Text('A matéria “${subject.name}” não poderá ser recuperada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DatabaseService.instance.deleteSubject(subject.id);
      _changed = true;
      if (mounted) setState(_reload);
    } on SubjectHasSessionsException {
      _showMessage(
        'Esta matéria possui sessões de Pomodoro ou manuais e não pode ser excluída.',
      );
    } catch (_) {
      _showMessage('Não foi possível excluir a matéria.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.subjectCount, required this.totalSeconds});
  final int subjectCount;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 24,
          runSpacing: 18,
          children: [
            _OverviewItem(
              width: constraints.maxWidth < 500
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 24) / 2,
              icon: Icons.menu_book_outlined,
              label: 'Total de matérias',
              value: '$subjectCount',
            ),
            _OverviewItem(
              width: constraints.maxWidth < 500
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 24) / 2,
              icon: Icons.schedule,
              label: 'Horas acumuladas',
              value: _formatDuration(totalSeconds),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
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
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFEAF2FF),
          child: Icon(icon, color: _blue),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: _muted)),
            Text(
              value,
              style: const TextStyle(
                color: _ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onArchive,
  });
  final SubjectRecord subject;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(subject.colorHex);
    final targetSeconds = (subject.targetMinutes ?? 0) * 60;
    final progress = targetSeconds == 0
        ? 0.0
        : (subject.studiedSeconds / targetSeconds).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(Icons.menu_book_outlined, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subject.name,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) =>
                            value == 'edit' ? onEdit() : onArchive(),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'archive',
                            child: Text('Arquivar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${subject.sessionCount} sessões  •  ${_formatDuration(subject.studiedSeconds)} estudadas',
                    style: const TextStyle(color: _muted),
                  ),
                  if (subject.targetMinutes != null) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      color: color,
                      backgroundColor: const Color(0xFFE6E8EF),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${(progress * 100).round()}% da meta',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (subject.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      subject.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectEditor extends StatefulWidget {
  const _SubjectEditor({this.subject});
  final SubjectRecord? subject;
  @override
  State<_SubjectEditor> createState() => _SubjectEditorState();
}

class _SubjectEditorState extends State<_SubjectEditor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _target;
  String _color = '#2563EB';
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();
  static const colors = ['#2563EB', '#10B981', '#0EA5E9', '#F97316', '#F43F5E'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.subject?.name);
    _description = TextEditingController(text: widget.subject?.description);
    _target = TextEditingController(
      text: widget.subject?.targetMinutes?.toString(),
    );
    _color = widget.subject?.colorHex ?? colors.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.subject == null ? 'Nova matéria' : 'Editar matéria',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nome da matéria',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o nome.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            TextFormField(
              controller: _target,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Meta em minutos (opcional)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final number = int.tryParse(value);
                return number == null || number < 1
                    ? 'Digite um número maior que zero.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Cor'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                for (final color in colors)
                  InkWell(
                    onTap: () => setState(() => _color = color),
                    borderRadius: BorderRadius.circular(24),
                    child: CircleAvatar(
                      backgroundColor: _parseColor(color),
                      child: _color == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Salvando...' : 'Salvar matéria'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final target = _target.text.trim().isEmpty
          ? null
          : int.parse(_target.text);
      if (widget.subject == null) {
        await DatabaseService.instance.createSubject(
          name: _name.text,
          description: _description.text,
          targetMinutes: target,
          colorHex: _color,
        );
      } else {
        await DatabaseService.instance.updateSubject(
          id: widget.subject!.id,
          name: _name.text,
          description: _description.text,
          targetMinutes: target,
          colorHex: _color,
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a matéria.')),
        );
        setState(() => _saving = false);
      }
    }
  }
}

class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 56),
    child: Column(
      children: [
        Icon(Icons.menu_book_outlined, size: 56, color: _muted),
        SizedBox(height: 12),
        Text('Nenhuma matéria cadastrada.'),
        Text(
          'Use “Nova matéria” para começar.',
          style: TextStyle(color: _muted),
        ),
      ],
    ),
  );
}

class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({
    required this.icon,
    required this.text,
    this.action,
  });
  final IconData icon;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 120),
      Icon(icon, size: 56, color: _muted),
      const SizedBox(height: 12),
      Text(text, textAlign: TextAlign.center),
      if (action != null) Center(child: action!),
    ],
  );
}

Color _parseColor(String value) {
  final hex = value.replaceFirst('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}

String _formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return hours > 0
      ? '${hours}h ${minutes.toString().padLeft(2, '0')}m'
      : '${minutes}min';
}
