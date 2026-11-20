import 'bell_schedule.dart';
import 'lesson.dart';

enum DayPhase { noLessons, beforeStart, lesson, betweenLessons, afterEnd }

class ScheduleSnapshot {
  final DayPhase phase;
  final Lesson? current;
  final Lesson? next;

  // Конец текущей пары, конец перемены или начало первой/следующей пары.
  final DateTime? target;

  // Начало следующей пары: во время урока target указывает на конец текущей.
  final DateTime? nextStart;

  const ScheduleSnapshot({
    required this.phase,
    this.current,
    this.next,
    this.target,
    this.nextStart,
  });
}

DateTime _atTime(DateTime day, int minutes) =>
    DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

ScheduleSnapshot snapshotAt(
  List<Lesson> lessons,
  BellSchedule bells,
  DateTime now,
) {
  if (lessons.isEmpty) {
    return const ScheduleSnapshot(phase: DayPhase.noLessons);
  }
  final sorted = [...lessons]..sort((a, b) => a.number.compareTo(b.number));

  for (var i = 0; i < sorted.length; i++) {
    final period = bells.periodFor(sorted[i].number);
    if (period == null) continue;
    final start = _atTime(now, period.startMinutes);
    final end = _atTime(now, period.endMinutes);
    if (!now.isBefore(start) && now.isBefore(end)) {
      final nextLesson = i + 1 < sorted.length ? sorted[i + 1] : null;
      final nextPeriod =
          nextLesson != null ? bells.periodFor(nextLesson.number) : null;
      return ScheduleSnapshot(
        phase: DayPhase.lesson,
        current: sorted[i],
        next: nextLesson,
        target: end,
        nextStart:
            nextPeriod != null ? _atTime(now, nextPeriod.startMinutes) : null,
      );
    }
  }

  DateTime? firstStart;
  for (final lesson in sorted) {
    final period = bells.periodFor(lesson.number);
    if (period == null) continue;
    final start = _atTime(now, period.startMinutes);
    firstStart ??= start;
    if (now.isBefore(start)) {
      return ScheduleSnapshot(
        phase: now.isBefore(firstStart)
            ? DayPhase.beforeStart
            : DayPhase.betweenLessons,
        next: lesson,
        target: start,
        nextStart: start,
      );
    }
  }

  return const ScheduleSnapshot(phase: DayPhase.afterEnd);
}