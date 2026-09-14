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
  String? completedMessage;
  final List<CompletedStudySession> completedSessions = [];

  int get focusMinutesToday =>
      completedSessions.fold(0, (total, session) => total + session.minutes);

  int get pomodorosToday => completedSessions.length;

  bool get subjectLocked => durationLocked && remainingSeconds > 0;

  void start() {
    if (running || remainingSeconds == 0) return;
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

  void changeSubject(String value) {
    if (subjectLocked) return;
    subject = value;
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
        completedSessions.insert(
          0,
          CompletedStudySession(
            subject: subject,
            minutes: sessionMinutes,
            finishedAt: DateTime.now(),
          ),
        );
      }
    }
  }
}

class CompletedStudySession {
  const CompletedStudySession({
    required this.subject,
    required this.minutes,
    required this.finishedAt,
  });

  final String subject;
  final int minutes;
  final DateTime finishedAt;
}
