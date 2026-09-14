import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_page_header.dart';
import 'dashboard_screen.dart';
import 'materias_screen.dart';
import 'pomodoro_screen.dart';
import 'sessoes_screen.dart';

const _blue = Color(0xFF2563EB);
const _ink = Color(0xFF171627);
const _muted = Color(0xFF777588);

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Future<_ProfileViewData> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _fetchData();
  }

  Future<_ProfileViewData> _fetchData() async {
    final results = await Future.wait([
      DatabaseService.instance.fetchProfile(),
      DatabaseService.instance.fetchSessions(),
      DatabaseService.instance.fetchSubjects(),
    ]);
    return _ProfileViewData(
      profile: results[0] as ProfileRecord,
      sessions: results[1] as List<StudySessionRecord>,
      subjects: results[2] as List<SubjectRecord>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return Scaffold(
      appBar: AppPageHeader(title: 'Meu perfil', compact: compact),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _load());
            await _future;
          },
          child: FutureBuilder<_ProfileViewData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  children: [
                    const SizedBox(height: 120),
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 56,
                      color: _muted,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Não foi possível carregar seu perfil.',
                      textAlign: TextAlign.center,
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _load()),
                        child: const Text('Tentar novamente'),
                      ),
                    ),
                  ],
                );
              }
              final data = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _IdentityCard(
                            profile: data.profile,
                            onEdit: () => _editName(data.profile),
                          ),
                          const SizedBox(height: 16),
                          _StatsCard(data: data),
                          const SizedBox(height: 16),
                          _AccountCard(profile: data.profile),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _changePassword,
                            icon: const Icon(Icons.lock_reset_rounded),
                            label: const Text('Alterar senha'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _signOut,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sair da conta'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 4,
        onDestinationSelected: _navigate,
      ),
    );
  }

  void _navigate(int index) {
    if (index == 4) return;
    final page = switch (index) {
      0 => const DashboardScreen(),
      1 => const PomodoroScreen(),
      2 => const SessoesScreen(),
      3 => const MateriasScreen(),
      _ => null,
    };
    if (page != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  Future<void> _editName(ProfileRecord profile) async {
    final controller = TextEditingController(text: profile.fullName);
    final key = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nome'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome completo'),
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Informe pelo menos 2 caracteres.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    try {
      await DatabaseService.instance.updateProfileName(name);
      if (mounted) setState(() => _load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível atualizar o nome.')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha alterada com sucesso.')),
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente para acessar seus dados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthService.instance.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirmation = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Alterar senha'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _passwordField(
                controller: _currentPassword,
                label: 'Senha atual',
                hidden: _hideCurrent,
                onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
                validator: (value) => value == null || value.isEmpty
                    ? 'Digite sua senha atual.'
                    : null,
              ),
              const SizedBox(height: 14),
              _passwordField(
                controller: _newPassword,
                label: 'Nova senha',
                hidden: _hideNew,
                onToggle: () => setState(() => _hideNew = !_hideNew),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite a nova senha.';
                  }
                  if (value.length < 8) {
                    return 'Use pelo menos 8 caracteres.';
                  }
                  if (value == _currentPassword.text) {
                    return 'A nova senha deve ser diferente da atual.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _passwordField(
                controller: _confirmation,
                label: 'Confirmar nova senha',
                hidden: _hideConfirmation,
                onToggle: () =>
                    setState(() => _hideConfirmation = !_hideConfirmation),
                validator: (value) => value != _newPassword.text
                    ? 'As senhas não coincidem.'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Alterar senha'),
      ),
    ],
  );

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) => TextFormField(
    controller: controller,
    obscureText: hidden,
    autocorrect: false,
    enableSuggestions: false,
    textInputAction: label == 'Confirmar nova senha'
        ? TextInputAction.done
        : TextInputAction.next,
    onFieldSubmitted: label == 'Confirmar nova senha' && !_saving
        ? (_) => _save()
        : null,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        tooltip: hidden ? 'Mostrar senha' : 'Ocultar senha',
        onPressed: onToggle,
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: validator,
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthService.instance.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on CurrentPasswordInvalidException {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'A senha atual está incorreta.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não foi possível alterar a senha. Tente novamente.';
        });
      }
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile, required this.onEdit});
  final ProfileRecord profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = profile.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFFE5EFFF),
              child: Text(
                initials.isEmpty ? 'E+' : initials,
                style: const TextStyle(
                  color: _blue,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onEdit,
              tooltip: 'Editar nome',
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.data});
  final _ProfileViewData data;

  @override
  Widget build(BuildContext context) {
    final seconds = data.sessions.fold<int>(
      0,
      (total, item) => total + item.seconds,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meu progresso',
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth < 560
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 24) / 3;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Stat(
                      width: itemWidth,
                      icon: Icons.schedule_rounded,
                      label: 'Tempo estudado',
                      value: _duration(seconds),
                    ),
                    _Stat(
                      width: itemWidth,
                      icon: Icons.calendar_month_outlined,
                      label: 'Sessões concluídas',
                      value: '${data.sessions.length}',
                    ),
                    _Stat(
                      width: itemWidth,
                      icon: Icons.menu_book_outlined,
                      label: 'Matérias',
                      value: '${data.subjects.length}',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
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
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: _blue),
          const SizedBox(width: 10),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile});
  final ProfileRecord profile;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações da conta',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'E-mail',
            value: profile.email,
          ),
          const Divider(height: 24),
          _InfoRow(
            icon: Icons.event_outlined,
            label: 'Membro desde',
            value: _date(profile.createdAt),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _blue),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
            Text(
              value,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ProfileViewData {
  const _ProfileViewData({
    required this.profile,
    required this.sessions,
    required this.subjects,
  });
  final ProfileRecord profile;
  final List<StudySessionRecord> sessions;
  final List<SubjectRecord> subjects;
}

String _duration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}

String _date(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
