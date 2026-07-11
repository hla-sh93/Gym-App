import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules a weekly repeating local notification for each training day.
///
/// Everything is wrapped defensively: on platforms without the plugin (unit
/// tests, desktop) or when the OS denies permission, calls become no-ops so
/// the app never crashes.
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _available = true;

  Future<void> _ensureInitialized() async {
    if (_initialized || !_available) {
      return;
    }
    try {
      tz.initializeTimeZones();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const init = InitializationSettings(android: androidInit);
      await _plugin.initialize(init);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (error) {
      _available = false;
      debugPrint('ReminderService unavailable: $error');
    }
  }

  /// Cancels all reminders and, when [enabled], schedules one weekly
  /// notification per training day at [hour]:00.
  Future<void> sync({
    required bool enabled,
    required int hour,
    required List<ReminderDay> days,
  }) async {
    await _ensureInitialized();
    if (!_available) {
      return;
    }
    try {
      await _plugin.cancelAll();
      if (!enabled) {
        return;
      }
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_reminders',
          'Workout reminders',
          channelDescription: 'Daily reminder on your training days',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      for (final day in days) {
        await _plugin.zonedSchedule(
          day.weekDay, // stable id 0..6
          day.title,
          day.body,
          _nextInstanceOf(day.weekDay, hour),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (error) {
      debugPrint('ReminderService sync failed: $error');
    }
  }

  /// Next occurrence of app weekday (0=Sun..6=Sat) at [hour]:00 local time.
  tz.TZDateTime _nextInstanceOf(int appWeekDay, int hour) {
    final now = tz.TZDateTime.now(tz.local);
    // DateTime.weekday: Mon=1..Sun=7. App: Sun=0..Sat=6.
    final targetWeekday = appWeekDay == 0 ? DateTime.sunday : appWeekDay;
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );
    while (scheduled.weekday != targetWeekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

class ReminderDay {
  const ReminderDay({
    required this.weekDay,
    required this.title,
    required this.body,
  });

  final int weekDay;
  final String title;
  final String body;
}
