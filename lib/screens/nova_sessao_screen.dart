import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../widgets/app_logo.dart';

const _blue = Color(0xFF2563EB);
const _ink = Color(0xFF171627);
const _muted = Color(0xFF777588);

class NovaSessaoScreen extends StatefulWidget {
  const NovaSessaoScreen({super.key});

  @override
  State<NovaSessaoScreen> createState() => _NovaSessaoScreenState();
}

class _NovaSessaoScreenState extends State<NovaSessaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _summary = TextEditingController();
  late Future<List<SubjectRecord>> _subjectsFuture;
  String? _subjectId;
  DateTime _date = DateTime.now();
  late TimeOfDay _time;
  late TimeOfDay _endTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    _time = TimeOfDay(hour: oneHourAgo.hour, minute: oneHourAgo.minute);
    _endTime = TimeOfDay(hour: now.hour, minute: now.minute);
    _subjectsFuture = DatabaseService.instance.fetchSubjects();
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Nova sessão'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 66)),
                    const SizedBox(height: 10),
                    const Text(
                      'Registre sua sessão para acompanhar seu progresso e manter a consistência.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 15),
                    ),
                    const SizedBox(height: 22),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Matéria', style: _labelStyle),
                            const SizedBox(height: 8),
                            _SubjectField(
                              future: _subjectsFuture,
                              value: _subjectId,
                              onChanged: (value) =>
                                  setState(() => _subjectId = value),
                              onRetry: () => setState(() {
                                _subjectsFuture = DatabaseService.instance
                                    .fetchSubjects();
                              }),
                            ),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 620;
                                final fields = [
                                  _PickerField(
                                    label: 'Data',
                                    icon: Icons.calendar_today_outlined,
                                    value: _formatDate(_date),
                                    onTap: _pickDate,
                                  ),
                                  _PickerField(
                                    label: 'Hora de início',
                                    icon: Icons.schedule_rounded,
                                    value: _formatTime(_time),
                                    onTap: _pickTime,
                                  ),
                                  _PickerField(
                                    label: 'Hora de término',
                                    icon: Icons.timer_outlined,
                                    value: _formatTime(_endTime),
                                    onTap: _pickEndTime,
                                  ),
                                ];
                                if (narrow) {
                                  return Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < fields.length;
                                        i++
                                      ) ...[
                                        fields[i],
                                        if (i < fields.length - 1)
                                          const SizedBox(height: 14),
                                      ],
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < fields.length; i++) ...[
                                      Expanded(child: fields[i]),
                                      if (i < fields.length - 1)
                                        const SizedBox(width: 14),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F7FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.timelapse_rounded,
                                    color: _blue,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Tempo calculado',
                                      style: TextStyle(
                                        color: _ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _calculatedDuration,
                                    style: TextStyle(
                                      color: _calculatedMinutes > 0
                                          ? _blue
                                          : Colors.red,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Resumo da sessão (opcional)',
                              style: _labelStyle,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _summary,
                              maxLength: 1000,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                hintText:
                                    'Descreva o que você estudou, principais tópicos, dúvidas ou aprendizados...',
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const _TipsCard(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 480;
                        final cancel = OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        );
                        final save = FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'Salvando...' : 'Salvar sessão',
                          ),
                        );
                        if (narrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              save,
                              const SizedBox(height: 10),
                              cancel,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: cancel),
                            const SizedBox(width: 14),
                            Expanded(child: save),
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
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await _show24HourPicker(_time);
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _pickEndTime() async {
    final selected = await _show24HourPicker(_endTime);
    if (selected != null) setState(() => _endTime = selected);
  }

  Future<TimeOfDay?> _show24HourPicker(TimeOfDay initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  int get _calculatedMinutes {
    final start = _time.hour * 60 + _time.minute;
    final end = _endTime.hour * 60 + _endTime.minute;
    return end - start;
  }

  String get _calculatedDuration => _calculatedMinutes > 0
      ? _formatDuration(_calculatedMinutes)
      : 'Período inválido';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _subjectId == null) return;
    setState(() => _saving = true);
    try {
      final startedAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );
      final endedAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _endTime.hour,
        _endTime.minute,
      );
      final durationMinutes = endedAt.difference(startedAt).inMinutes;
      if (durationMinutes < 1) {
        _showError('A hora de término deve ser posterior à hora de início.');
        return;
      }
      await DatabaseService.instance.createManualSession(
        subjectId: _subjectId!,
        startedAt: startedAt,
        durationMinutes: durationMinutes,
        summary: _summary.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão salva com sucesso!')),
      );
      Navigator.pop(context, true);
    } on FutureSessionException {
      _showError(
        'A hora de início precisa ser igual ou anterior ao horário atual.',
      );
    } on UnfinishedSessionException {
      _showError(
        'A hora de término precisa ser igual ou anterior ao horário atual.',
      );
    } on SessionConflictException {
      _showError(
        'Já existe uma sessão cadastrada nesse período. Escolha um horário sem sobreposição.',
      );
    } catch (_) {
      _showError('Não foi possível salvar a sessão.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _saving = false);
    }
  }
}

class _SubjectField extends StatelessWidget {
  const _SubjectField({
    required this.future,
    required this.value,
    required this.onChanged,
    required this.onRetry,
  });
  final Future<List<SubjectRecord>> future;
  final String? value;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<SubjectRecord>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const LinearProgressIndicator();
      }
      if (snapshot.hasError) {
        return OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar carregar matérias novamente'),
        );
      }
      final subjects = snapshot.data ?? [];
      if (subjects.isEmpty) {
        return const InputDecorator(
          decoration: InputDecoration(
            errorText: 'Cadastre uma matéria antes de registrar uma sessão.',
          ),
          child: Text(
            'Nenhuma matéria disponível',
            style: TextStyle(color: _muted),
          ),
        );
      }
      return DropdownButtonFormField<String>(
        // Compatibilidade com o Flutter 3.32 usado pelo FlutLab.
        // ignore: deprecated_member_use
        value: value,
        isExpanded: true,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.menu_book_outlined),
          hintText: 'Selecione a matéria',
        ),
        items: subjects
            .map(
              (item) => DropdownMenuItem(
                value: item.id,
                child: Text(item.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: (selected) =>
            selected == null ? 'Selecione uma matéria.' : null,
      );
    },
  );
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: _labelStyle),
      const SizedBox(height: 8),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(prefixIcon: Icon(icon)),
          child: Text(value),
        ),
      ),
    ],
  );
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: _blue),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dicas para um bom resumo',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _Tip('Resuma os principais tópicos estudados'),
        _Tip('Liste dúvidas para revisar depois'),
        _Tip('Anote exemplos, fórmulas ou definições'),
      ],
    ),
  );
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      children: [
        const Icon(Icons.check_rounded, size: 18, color: _blue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: _muted)),
        ),
      ],
    ),
  );
}

const _labelStyle = TextStyle(color: _ink, fontWeight: FontWeight.w700);

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatTime(TimeOfDay value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '${minutes}min';
  return '${hours}h ${rest.toString().padLeft(2, '0')}min';
}
