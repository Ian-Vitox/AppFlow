import 'dart:async';

import 'package:flutter/foundation.dart';

import 'notification_service.dart';

class PomodoroController extends ChangeNotifier {
  PomodoroController._();

  static final instance = PomodoroController._();

  Timer? _ticker;
  DateTime? _endAt;
  int sessionMinutes = 25;
  int remainingSeconds = 25 * 60;
  bool running = false;
  bool durationLocked = false;
  String mode = 'Pomodoro';
  String subject = '';
  String? subjectId;
  String? completedMessage;
  CompletedStudySession? pendingCompletion;
  String pendingSummaryDraft = '';
  bool pendingNotesRequested = false;

  bool get subjectLocked => durationLocked && remainingSeconds > 0;

  void start() {
    if (running ||
        remainingSeconds == 0 ||
        pendingCompletion != null ||
        subjectId == null) {
      return;
    }
    running = true;
    completedMessage = null;
    durationLocked = true;
    _endAt = DateTime.now().add(Duration(seconds: remainingSeconds));
    NotificationService.instance.scheduleTimerEnd(_endAt!, mode);
    _startTicker();
    notifyListeners();
  }

  void pause() {
    _syncWithClock();
    _ticker?.cancel();
    _endAt = null;
    running = false;
    NotificationService.instance.cancelTimerEnd();
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _endAt = null;
    running = false;
    durationLocked = false;
    completedMessage = null;
    remainingSeconds = sessionMinutes * 60;
    NotificationService.instance.cancelTimerEnd();
    notifyListeners();
  }

  void selectMode(String value, int minutes) {
    if (durationLocked) return;
    _ticker?.cancel();
    _endAt = null;
    mode = value;
    sessionMinutes = minutes;
    remainingSeconds = minutes * 60;
    running = false;
    NotificationService.instance.cancelTimerEnd();
    notifyListeners();
  }

  void changeDuration(int minutes) {
    if (durationLocked ||
        mode == 'Pausa curta' ||
        mode == 'Pausa longa' ||
        minutes == sessionMinutes) {
      return;
    }
    sessionMinutes = minutes;
    remainingSeconds = minutes * 60;
    notifyListeners();
  }

  void changeSubject(String value, {String? id}) {
    if (subjectLocked) return;
    subject = value;
    subjectId = id;
    notifyListeners();
  }

  void updatePendingSummaryDraft(String value) {
    if (pendingCompletion == null) return;
    pendingSummaryDraft = value;
  }

  void requestPendingNotes() {
    if (pendingCompletion == null) return;
    pendingNotesRequested = true;
  }

  void resolvePendingCompletion() {
    pendingCompletion = null;
    pendingSummaryDraft = '';
    pendingNotesRequested = false;
    notifyListeners();
  }

  Future<void> clearForLogout() async {
    _ticker?.cancel();
    _endAt = null;
    running = false;
    durationLocked = false;
    sessionMinutes = 25;
    remainingSeconds = 25 * 60;
    mode = 'Pomodoro';
    subject = '';
    subjectId = null;
    completedMessage = null;
    pendingCompletion = null;
    pendingSummaryDraft = '';
    pendingNotesRequested = false;
    await NotificationService.instance.cancelTimerEnd();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncWithClock();
      notifyListeners();
    });
  }

  void _syncWithClock() {
    if (_endAt == null) return;
    final difference = _endAt!.difference(DateTime.now()).inSeconds;
    remainingSeconds = difference.clamp(0, sessionMinutes * 60);
    if (remainingSeconds == 0) {
      _ticker?.cancel();
      _endAt = null;
      running = false;
      durationLocked = false;
      completedMessage = mode == 'Pomodoro'
          ? 'Ciclo de Pomodoro concluído!'
          : '$mode concluída!';
      if (mode == 'Pomodoro') {
        pendingCompletion = CompletedStudySession(
          subjectId: subjectId!,
          subject: subject,
          minutes: sessionMinutes,
          finishedAt: DateTime.now(),
        );
        pendingSummaryDraft = '';
        pendingNotesRequested = false;
      }
    }
  }
}

class CompletedStudySession {
  const CompletedStudySession({
    required this.subjectId,
    required this.subject,
    required this.minutes,
    required this.finishedAt,
  });

  final String subjectId;
  final String subject;
  final int minutes;
  final DateTime finishedAt;
}
