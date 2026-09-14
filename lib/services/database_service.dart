import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  DatabaseService._();
  static final instance = DatabaseService._();

  Future<List<StudySessionRecord>> fetchSessions() async {
    final data = await Supabase.instance.client
        .from('study_sessions')
        .select(
          'id, source, started_at, duration_seconds, summary, subjects(name, color_hex)',
        )
        .eq('completed', true)
        .order('started_at', ascending: false);
    final records = (data as List)
        .map((row) => StudySessionRecord.fromMap(row as Map<String, dynamic>))
        .toList();
    final seen = <String>{};
    return records.where((item) {
      final key =
          '${item.subject}|${item.source}|${item.startedAt.toUtc().toIso8601String()}|${item.seconds}';
      return seen.add(key);
    }).toList();
  }

  Future<void> deleteSession(String id) =>
      Supabase.instance.client.from('study_sessions').delete().eq('id', id);

  Future<void> updateSessionSummary(String id, String summary) => Supabase
      .instance
      .client
      .from('study_sessions')
      .update({'summary': summary.trim().isEmpty ? null : summary.trim()})
      .eq('id', id);

  Future<void> createManualSession({
    required String subjectId,
    required DateTime startedAt,
    required int durationMinutes,
    String? summary,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    final endedAt = startedAt.add(Duration(minutes: durationMinutes));
    final now = DateTime.now();
    if (startedAt.isAfter(now)) throw const FutureSessionException();
    if (endedAt.isAfter(now)) throw const UnfinishedSessionException();
    final conflicts = await Supabase.instance.client
        .from('study_sessions')
        .select('id')
        .eq('completed', true)
        .lt('started_at', endedAt.toUtc().toIso8601String())
        .gt('ended_at', startedAt.toUtc().toIso8601String())
        .limit(1);
    if ((conflicts as List).isNotEmpty) throw const SessionConflictException();
    await Supabase.instance.client.from('study_sessions').insert({
      'user_id': user.id,
      'subject_id': subjectId,
      'source': 'manual',
      'started_at': startedAt.toUtc().toIso8601String(),
      'ended_at': endedAt.toUtc().toIso8601String(),
      'duration_seconds': durationMinutes * 60,
      'summary': summary?.trim().isEmpty == true ? null : summary?.trim(),
      'completed': true,
    });
  }

  Future<void> createPomodoroSession({
    required String subjectId,
    required DateTime finishedAt,
    required int durationMinutes,
    String? summary,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    final startedAt = finishedAt.subtract(Duration(minutes: durationMinutes));
    final compactSubjectId = subjectId.replaceAll('-', '');
    final timestamp = finishedAt.microsecondsSinceEpoch
        .toRadixString(16)
        .padLeft(12, '0');
    final rawId =
        '${compactSubjectId.substring(0, 20)}${timestamp.substring(timestamp.length - 12)}';
    final sessionId =
        '${rawId.substring(0, 8)}-${rawId.substring(8, 12)}-'
        '${rawId.substring(12, 16)}-${rawId.substring(16, 20)}-${rawId.substring(20)}';
    final conflicts = await Supabase.instance.client
        .from('study_sessions')
        .select('id')
        .eq('completed', true)
        .neq('id', sessionId)
        .lt('started_at', finishedAt.toUtc().toIso8601String())
        .gt('ended_at', startedAt.toUtc().toIso8601String())
        .limit(1);
    if ((conflicts as List).isNotEmpty) throw const SessionConflictException();
    await Supabase.instance.client
        .from('study_sessions')
        .upsert(
          {
            'id': sessionId,
            'user_id': user.id,
            'subject_id': subjectId,
            'source': 'pomodoro',
            'started_at': startedAt.toUtc().toIso8601String(),
            'ended_at': finishedAt.toUtc().toIso8601String(),
            'duration_seconds': durationMinutes * 60,
            'summary': summary?.trim().isEmpty == true ? null : summary?.trim(),
            'completed': true,
          },
          onConflict: 'id',
          ignoreDuplicates: true,
        );
  }

  Future<List<SubjectRecord>> fetchSubjects() async {
    final data = await Supabase.instance.client
        .from('subjects')
        .select(
          'id, name, description, color_hex, icon_key, target_minutes, status, '
          'study_sessions(duration_seconds, completed)',
        )
        .neq('status', 'archived')
        .order('created_at');
    return (data as List)
        .map((row) => SubjectRecord.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<SubjectRecord>> fetchArchivedSubjects() async {
    final data = await Supabase.instance.client
        .from('subjects')
        .select(
          'id, name, description, color_hex, icon_key, target_minutes, status, '
          'study_sessions(duration_seconds, completed)',
        )
        .eq('status', 'archived')
        .order('updated_at', ascending: false);
    return (data as List)
        .map((row) => SubjectRecord.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createSubject({
    required String name,
    String? description,
    int? targetMinutes,
    String colorHex = '#2563EB',
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    await Supabase.instance.client.from('subjects').insert({
      'user_id': user.id,
      'name': name.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'target_minutes': targetMinutes,
      'color_hex': colorHex,
    });
  }

  Future<void> updateSubject({
    required String id,
    required String name,
    String? description,
    int? targetMinutes,
    required String colorHex,
  }) => Supabase.instance.client
      .from('subjects')
      .update({
        'name': name.trim(),
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        'target_minutes': targetMinutes,
        'color_hex': colorHex,
      })
      .eq('id', id);

  Future<void> archiveSubject(String id) => Supabase.instance.client
      .from('subjects')
      .update({'status': 'archived'})
      .eq('id', id);

  Future<void> restoreSubject(String id) => Supabase.instance.client
      .from('subjects')
      .update({'status': 'active'})
      .eq('id', id);

  Future<void> deleteSubject(String id) async {
    final sessions = await Supabase.instance.client
        .from('study_sessions')
        .select('id')
        .eq('subject_id', id)
        .limit(1);
    if ((sessions as List).isNotEmpty) {
      throw const SubjectHasSessionsException();
    }
    await Supabase.instance.client.from('subjects').delete().eq('id', id);
  }

  Future<ProfileRecord> fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    final data = await Supabase.instance.client
        .from('profiles')
        .select('full_name, avatar_url, timezone, created_at')
        .eq('id', user.id)
        .single();
    return ProfileRecord.fromMap(data, email: user.email ?? '');
  }

  Future<void> updateProfileName(String fullName) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    final name = fullName.trim();
    await client.from('profiles').update({'full_name': name}).eq('id', user.id);
    await client.auth.updateUser(UserAttributes(data: {'full_name': name}));
  }

  Future<int?> fetchCurrentWeeklyGoal() async {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final date =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    final data = await Supabase.instance.client
        .from('weekly_goals')
        .select('target_minutes')
        .eq('week_start', date)
        .maybeSingle();
    return data?['target_minutes'] as int?;
  }

  Future<void> saveCurrentWeeklyGoal(int targetMinutes) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final date =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    if (targetMinutes < 1) throw ArgumentError.value(targetMinutes);
    await Supabase.instance.client.from('weekly_goals').upsert({
      'user_id': user.id,
      'week_start': date,
      'target_minutes': targetMinutes,
    }, onConflict: 'user_id,week_start');
  }

  Future<void> removeCurrentWeeklyGoal() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Usuário não autenticado.');
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final date =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    await Supabase.instance.client
        .from('weekly_goals')
        .delete()
        .eq('user_id', user.id)
        .eq('week_start', date);
  }

  Future<DashboardRecord> fetchDashboard() async {
    final values = await Future.wait([
      fetchSessions(),
      fetchCurrentWeeklyGoal(),
    ]);
    return DashboardRecord(
      sessions: values[0] as List<StudySessionRecord>,
      weeklyGoalMinutes: values[1] as int?,
    );
  }
}

class DashboardRecord {
  const DashboardRecord({required this.sessions, this.weeklyGoalMinutes});
  final List<StudySessionRecord> sessions;
  final int? weeklyGoalMinutes;
}

class FutureSessionException implements Exception {
  const FutureSessionException();
}

class UnfinishedSessionException implements Exception {
  const UnfinishedSessionException();
}

class SessionConflictException implements Exception {
  const SessionConflictException();
}

class SubjectHasSessionsException implements Exception {
  const SubjectHasSessionsException();
}

class ProfileRecord {
  const ProfileRecord({
    required this.fullName,
    required this.email,
    required this.timezone,
    required this.createdAt,
    this.avatarUrl,
  });

  factory ProfileRecord.fromMap(
    Map<String, dynamic> map, {
    required String email,
  }) => ProfileRecord(
    fullName: map['full_name'] as String? ?? 'Estudante',
    email: email,
    timezone: map['timezone'] as String? ?? 'America/Sao_Paulo',
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    avatarUrl: map['avatar_url'] as String?,
  );

  final String fullName;
  final String email;
  final String timezone;
  final DateTime createdAt;
  final String? avatarUrl;
}

class SubjectRecord {
  const SubjectRecord({
    required this.id,
    required this.name,
    required this.description,
    required this.colorHex,
    required this.targetMinutes,
    required this.status,
    required this.sessionCount,
    required this.studiedSeconds,
    required this.hasSessions,
  });

  factory SubjectRecord.fromMap(Map<String, dynamic> map) {
    final allSessions = (map['study_sessions'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final sessions = allSessions.where((item) => item['completed'] == true);
    return SubjectRecord(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      colorHex: map['color_hex'] as String? ?? '#2563EB',
      targetMinutes: map['target_minutes'] as int?,
      status: map['status'] as String? ?? 'active',
      sessionCount: sessions.length,
      studiedSeconds: sessions.fold<int>(
        0,
        (total, item) => total + (item['duration_seconds'] as int? ?? 0),
      ),
      hasSessions: allSessions.isNotEmpty,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String colorHex;
  final int? targetMinutes;
  final String status;
  final int sessionCount;
  final int studiedSeconds;
  final bool hasSessions;
}

class StudySessionRecord {
  const StudySessionRecord({
    required this.id,
    required this.subject,
    required this.source,
    required this.startedAt,
    required this.seconds,
    required this.summary,
    required this.color,
  });

  factory StudySessionRecord.fromMap(Map<String, dynamic> map) {
    final subject = map['subjects'] as Map<String, dynamic>? ?? const {};
    return StudySessionRecord(
      id: map['id'] as String,
      subject: subject['name'] as String? ?? 'Matéria',
      source: map['source'] as String? ?? 'manual',
      startedAt: DateTime.parse(map['started_at'] as String).toLocal(),
      seconds: map['duration_seconds'] as int,
      summary: map['summary'] as String?,
      color: subject['color_hex'] as String? ?? '#2563EB',
    );
  }

  final String id;
  final String subject;
  final String source;
  final DateTime startedAt;
  final int seconds;
  final String? summary;
  final String color;
}
