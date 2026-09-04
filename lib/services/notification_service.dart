import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  static const timerNotificationId = 1001;
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    if (!kIsWeb) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleTimerEnd(DateTime endAt, String mode) async {
    await cancelTimerEnd();
    await _plugin.zonedSchedule(
      id: timerNotificationId,
      title: '$mode concluído!',
      body: _messageFor(mode),
      scheduledDate: tz.TZDateTime.from(endAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'study_flow_timer',
          'Cronômetro Estuda+',
          channelDescription: 'Avisos de conclusão das sessões de estudo',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'pomodoro_finished',
    );
  }

  Future<void> cancelTimerEnd() => _plugin.cancel(id: timerNotificationId);

  String _messageFor(String mode) {
    switch (mode) {
      case 'Pausa curta':
        return 'Sua pausa curta acabou. Vamos voltar aos estudos?';
      case 'Pausa longa':
        return 'Sua pausa longa acabou. Hora de retomar o foco!';
      default:
        return 'Seu tempo de foco acabou. Excelente trabalho!';
    }
  }
}
