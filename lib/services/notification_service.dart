import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/bell_schedule.dart';
import '../models/lesson.dart';
import '../models/schedule_snapshot.dart';
import 'notification_content.dart';
import 'schedule_controller.dart';
import 'storage_service.dart';

// Пока процесс приложения жив, минутный таймер обновляет шторку не реже
// раза в минуту; zonedSchedule (inexact, без SCHEDULE_EXACT_ALARM) страхует
// границы звонков в doze. Foreground service не используем: тяжело и не
// требуется, уведомление должно жить только при живом приложении.
class NotificationService {
  final ScheduleController controller;
  final StorageService storage;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Timer? _timer;
  bool _ready = false;
  bool _wasEnabled = false;
  String _scheduledDay = '';

  NotificationService({required this.controller, required this.storage});

  static const _ongoingId = 1;

  Future<void> init() async {
    if (kIsWeb) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    tzdata.initializeTimeZones();
    _ready = true;
    _wasEnabled = controller.notificationSettings.enabled;
    controller.addListener(_onChange);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_scheduledDay != controller.selectedDate) _scheduleBoundaries();
      sync();
    });
    _scheduleBoundaries();
    sync();
  }

  void dispose() {
    _timer?.cancel();
    controller.removeListener(_onChange);
  }

  void _onChange() {
    final nowEnabled = controller.notificationSettings.enabled;
    if (nowEnabled && !_wasEnabled) {
      _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    _wasEnabled = nowEnabled;
    _scheduleBoundaries();
    sync();
  }

  bool get _shouldShow =>
      controller.enabled &&
      controller.notificationSettings.enabled &&
      controller.isDayAvailable(controller.selectedDate);

  void sync() {
    if (!_ready) return;
    if (!_shouldShow) {
      _plugin.cancelAll();
      return;
    }
    final now = DateTime.now();
    final day = DateTime.parse(controller.selectedDate);
    final bells = controller.bellsFor(day);
    final snapshot = snapshotAt(controller.lessons, bells, now);

    Lesson? tomorrowFirst;
    DateTime? tomorrowStart;
    if (snapshot.phase == DayPhase.afterEnd) {
      final nextDays = controller.days
          .where((d) =>
              d.compareTo(controller.selectedDate) > 0 &&
              controller.isDayAvailable(d))
          .toList()
        ..sort();
      if (nextDays.isNotEmpty) {
        final cache = storage.loadDay(nextDays.first);
        final lessons = cache?.groups[controller.selectedGroup];
        if (lessons != null && lessons.isNotEmpty) {
          final period = controller
              .bellsFor(DateTime.parse(nextDays.first))
              .periodFor(lessons.first.number);
          if (period != null) {
            tomorrowFirst = lessons.first;
            tomorrowStart = DateTime.parse(nextDays.first)
                .add(Duration(minutes: period.startMinutes));
          }
        }
      }
    }

    final content = buildNotificationContent(
      snapshot,
      now,
      showNext: controller.notificationSettings.showNext,
      tomorrowFirst: tomorrowFirst,
      tomorrowStart: tomorrowStart,
    );
    if (content == null) {
      _plugin.cancel(_ongoingId);
      return;
    }
    _show(_ongoingId, content, ongoing: true);
  }

  void _scheduleBoundaries() {
    if (!_ready) return;
    _scheduledDay = controller.selectedDate;
    _plugin.cancelAll();
    if (!_shouldShow) return;
    final now = DateTime.now();
    final day = DateTime.parse(controller.selectedDate);
    final bells = controller.bellsFor(day);
    final remind = controller.notificationSettings.remindMinutes;

    for (var i = 0; i < bells.periods.length; i++) {
      final period = bells.periods[i];
      final start = day.add(Duration(minutes: period.startMinutes));
      final end = day.add(Duration(minutes: period.endMinutes));
      for (final instant in [start, end]) {
        if (!instant.isAfter(now)) continue;
        final at = instant.add(const Duration(seconds: 1));
        final content = buildNotificationContent(
          snapshotAt(controller.lessons, bells, at),
          at,
          showNext: controller.notificationSettings.showNext,
        );
        if (content == null) continue;
        _schedule(1000 + i * 2 + (instant == end ? 1 : 0), content, instant);
      }
      if (remind > 0) {
        final at = start.subtract(Duration(minutes: remind));
        if (!at.isAfter(now)) continue;
        final lesson = controller.lessons
            .where((l) => l.number == i + 1)
            .firstOrNull;
        if (lesson == null) continue;
        _schedule(
          2000 + i,
          NotificationContent(
            title: 'Скоро звонок',
            lines: [
              '${lesson.subject} в ${formatClock(start)}, каб. ${lesson.room}',
              'До звонка $remind мин',
            ],
          ),
          at,
        );
      }
    }
  }

  void _schedule(int id, NotificationContent content, DateTime instant) {
    final body = content.lines.join('\n');
    _plugin.zonedSchedule(
      id,
      content.title,
      body,
      tz.TZDateTime.from(instant, tz.UTC),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule',
          'Расписание',
          channelDescription: 'Текущая пара и следующий звонок',
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showWhen: false,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  void _show(int id, NotificationContent content, {required bool ongoing}) {
    final body = content.lines.join('\n');
    _plugin.show(
      id,
      content.title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule',
          'Расписание',
          channelDescription: 'Текущая пара и следующий звонок',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: ongoing,
          onlyAlertOnce: true,
          showWhen: false,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }
}