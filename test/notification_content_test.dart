import 'package:college_schedule/models/bell_schedule.dart';
import 'package:college_schedule/models/lesson.dart';
import 'package:college_schedule/models/schedule_snapshot.dart';
import 'package:college_schedule/services/notification_content.dart';
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
  const bells = BellSchedule([
    BellPeriod(510, 600),
    BellPeriod(610, 700),
    BellPeriod(730, 820),
    BellPeriod(830, 920),
    BellPeriod(930, 1020),
    BellPeriod(1030, 1120),
  ]);
  DateTime at(int h, int m) => DateTime(2026, 11, 20, h, m);

  test('lesson: текущая пара, кабинет, преподаватель, звонок и следующая', () {
    final content = buildNotificationContent(
      snapshotAt(lessons, bells, at(10, 30)),
      at(10, 30),
    )!;
    expect(content.title, 'Сейчас: Физика, 2 пара');
    expect(content.lines[0], 'Кабинет 402, Гусев П. А.');
    expect(content.lines[1], 'Звонок в 11:40, осталось 70 мин');
    expect(
      content.lines[2],
      'Следующая: История в 12:10, каб. 226, Лебедева М. В.',
    );
  });

  test('lesson: showNext=false убирает блок следующей пары', () {
    final content = buildNotificationContent(
      snapshotAt(lessons, bells, at(10, 30)),
      at(10, 30),
      showNext: false,
    )!;
    expect(content.lines.length, 2);
  });

  test('betweenLessons: перемена и звонок', () {
    final content = buildNotificationContent(
      snapshotAt(lessons, bells, at(11, 50)),
      at(11, 50),
    )!;
    expect(content.title, 'Перемена');
    expect(content.lines[0], 'Звонок в 12:10');
    expect(
      content.lines[1],
      'Следующая: История в 12:10, каб. 226, Лебедева М. В.',
    );
  });

  test('beforeStart: до первой пары', () {
    final content = buildNotificationContent(
      snapshotAt(lessons, bells, at(7, 0)),
      at(7, 0),
    )!;
    expect(content.title, 'До первой пары');
    expect(content.lines[0], 'Начало в 08:30');
    expect(
      content.lines[1],
      'Следующая: Математика в 08:30, каб. 305, Смирнова А. П.',
    );
  });

  test('afterEnd: без завтрашнего дня уведомление снимается', () {
    final content = buildNotificationContent(
      snapshotAt(lessons, bells, at(19, 0)),
      at(19, 0),
    );
    expect(content, isNull);
  });

  test('afterEnd: с завтрашней первой парой', () {
    final content = buildNotificationContent(
      snapshotAt(lessons, bells, at(19, 0)),
      at(19, 0),
      tomorrowFirst: const Lesson(
        number: 1,
        subject: 'Химия',
        room: '12',
        teacher: 'Фролов И. М.',
      ),
      tomorrowStart: at(8, 30),
    )!;
    expect(content.title, 'Пары закончились');
    expect(content.lines.single, 'Завтра первая: Химия в 08:30, каб. 12');
  });

  test('noLessons: уведомление снимается', () {
    final content = buildNotificationContent(
      snapshotAt([], bells, at(10, 0)),
      at(10, 0),
    );
    expect(content, isNull);
  });
}