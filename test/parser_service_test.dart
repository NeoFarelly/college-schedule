import 'package:college_schedule/models/lesson.dart';
import 'package:college_schedule/services/parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserService();

  test('mock помечен как демо-данные', () {
    expect(parser.isMock, isTrue);
  });

  test('расписание упорядочено и поля заполнены', () async {
    final lessons = await parser.fetchSchedule('ИС-21');
    if (DateTime.now().weekday == DateTime.sunday) {
      expect(lessons, isEmpty);
      return;
    }
    expect(lessons, isNotEmpty);
    for (var i = 0; i < lessons.length; i++) {
      expect(lessons[i].number, i + 1);
      expect(lessons[i].subject, isNotEmpty);
      expect(lessons[i].room, isNotEmpty);
      expect(lessons[i].teacher, isNotEmpty);
    }
  });

  test('для одной группы результат детерминирован', () async {
    final a = await parser.fetchSchedule('ИС-21');
    final b = await parser.fetchSchedule('ИС-21');
    expect(
      a.map((Lesson l) => l.toJson()).toList(),
      b.map((Lesson l) => l.toJson()).toList(),
    );
  });

  test('суббота: сокращенный день, не больше трех пар', () async {
    final lessons = await parser.fetchSchedule('ИС-21');
    if (DateTime.now().weekday == DateTime.saturday) {
      expect(lessons.length, 3);
    }
  });
}