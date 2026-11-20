import '../models/bell_schedule.dart';
import '../models/lesson.dart';
import '../models/schedule_snapshot.dart';

class NotificationContent {
  final String title;
  final List<String> lines;

  const NotificationContent({required this.title, required this.lines});
}

NotificationContent? buildNotificationContent(
  ScheduleSnapshot snapshot,
  DateTime now, {
  bool showNext = true,
  Lesson? tomorrowFirst,
  DateTime? tomorrowStart,
}) {
  String nextLine(Lesson lesson, DateTime start) =>
      'Следующая: ${lesson.subject} в ${formatClock(start)}, каб. ${lesson.room}, ${lesson.teacher}';
  final next = snapshot.next;
  final nextStart = snapshot.nextStart;
  final nextBlock = showNext && next != null && nextStart != null
      ? nextLine(next, nextStart)
      : null;

  switch (snapshot.phase) {
    case DayPhase.noLessons:
      return null;
    case DayPhase.lesson:
      final current = snapshot.current!;
      final minutes = snapshot.target!.difference(now).inMinutes;
      return NotificationContent(
        title: 'Сейчас: ${current.subject}, ${current.number} пара',
        lines: [
          'Кабинет ${current.room}, ${current.teacher}',
          'Звонок в ${formatClock(snapshot.target!)}, осталось ${minutes < 0 ? 0 : minutes} мин',
          if (nextBlock != null) nextBlock,
        ],
      );
    case DayPhase.betweenLessons:
      return NotificationContent(
        title: 'Перемена',
        lines: [
          'Звонок в ${formatClock(snapshot.target!)}',
          if (nextBlock != null) nextBlock,
        ],
      );
    case DayPhase.beforeStart:
      return NotificationContent(
        title: 'До первой пары',
        lines: [
          'Начало в ${formatClock(snapshot.target!)}',
          if (nextBlock != null) nextBlock,
        ],
      );
    case DayPhase.afterEnd:
      if (tomorrowFirst == null || tomorrowStart == null) return null;
      return NotificationContent(
        title: 'Пары закончились',
        lines: [
          'Завтра первая: ${tomorrowFirst.subject} в ${formatClock(tomorrowStart)}, каб. ${tomorrowFirst.room}',
        ],
      );
  }
}