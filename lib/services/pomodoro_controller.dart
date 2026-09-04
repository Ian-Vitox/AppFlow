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
  String subject = 'Desenvolvimento Web';

  void start() {
    if (running || remainingSeconds == 0) return;
    running = true;
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
    if (durationLocked || minutes == sessionMinutes) return;
    mode = 'Pomodoro';
    sessionMinutes = minutes;
    remainingSeconds = minutes * 60;
    notifyListeners();
  }

  void changeSubject(String value) {
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
    }
  }
}
