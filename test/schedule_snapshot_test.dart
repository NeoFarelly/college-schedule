import 'package:college_schedule/models/bell_schedule.dart';
import 'package:college_schedule/models/lesson.dart';
import 'package:college_schedule/models/schedule_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lessons = [
    Lesson(
      number: 1,
      subject: 'Математика',
      room: '305',
      teacher: 'Смирнова А. П.',
    ),
    Lesson(number: 2, subject: 'Физика', room: '402', teacher: 'Гусев П. А.'),
    Lesson(
      number: 3,
      subject: 'История',
      room: '226',
      teacher: 'Лебедева М. В.',
    ),
  ];
  final bells = const BellSchedule([
    BellPeriod(510, 600),
    BellPeriod(610, 700),
    BellPeriod(730, 820),
    BellPeriod(830, 920),
    BellPeriod(930, 1020),
    BellPeriod(1030, 1120),
  ]);
  DateTime at(int h, int m) => DateTime(2026, 11, 20, h, m);

  test('идет вторая пара: текущая, следующая и конец пары', () {
    final s = snapshotAt(lessons, bells, at(10, 30));
    expect(s.phase, DayPhase.lesson);
    expect(s.current!.number, 2);
    expect(s.next!.number, 3);
    expect(s.target, at(11, 40));
    expect(s.nextStart, at(12, 10));
  });

  test('перемена между второй и третьей парой', () {
    final s = snapshotAt(lessons, bells, at(11, 50));
    expect(s.phase, DayPhase.betweenLessons);
    expect(s.current, isNull);
    expect(s.next!.number, 3);
    expect(s.target, at(12, 10));
  });

  test('до первой пары', () {
    final s = snapshotAt(lessons, bells, at(7, 0));
    expect(s.phase, DayPhase.beforeStart);
    expect(s.next!.number, 1);
    expect(s.target, at(8, 30));
  });

  test('после последней пары', () {
    final s = snapshotAt(lessons, bells, at(19, 0));
    expect(s.phase, DayPhase.afterEnd);
    expect(s.current, isNull);
    expect(s.next, isNull);
  });

  test('пустой день', () {
    final s = snapshotAt([], bells, at(10, 0));
    expect(s.phase, DayPhase.noLessons);
  });

  test('границы: ровно начало пары и ровно конец пары', () {
    expect(snapshotAt(lessons, bells, at(8, 30)).phase, DayPhase.lesson);
    expect(
      snapshotAt(lessons, bells, at(10, 0)).phase,
      DayPhase.betweenLessons,
    );
  });

  test('пропущенные номера пар: длинная перемена', () {
    final sparse = [lessons[0], lessons[2]];
    final s = snapshotAt(sparse, bells, at(10, 30));
    expect(s.phase, DayPhase.betweenLessons);
    expect(s.next!.number, 3);
    expect(s.target, at(12, 10));
  });

  test('субботние звонки: сокращенная пара', () {
    final saturday = const BellSchedule([
      BellPeriod(510, 580),
      BellPeriod(590, 660),
      BellPeriod(670, 740),
      BellPeriod(750, 820),
      BellPeriod(830, 900),
      BellPeriod(910, 980),
    ]);
    final s = snapshotAt(lessons, saturday, at(9, 30));
    expect(s.phase, DayPhase.lesson);
    expect(s.current!.number, 1);
    expect(s.target, at(9, 40));
  });

  test('последняя пара: следующей нет', () {
    final s = snapshotAt(lessons, bells, at(12, 30));
    expect(s.phase, DayPhase.lesson);
    expect(s.current!.number, 3);
    expect(s.next, isNull);
    expect(s.nextStart, isNull);
  });
}