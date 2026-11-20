import 'dart:convert';

import 'package:college_schedule/services/parser_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final weekdayBells = [
    {'start': '08:30', 'end': '10:00'},
    {'start': '10:10', 'end': '11:40'},
    {'start': '12:10', 'end': '13:40'},
    {'start': '13:50', 'end': '15:20'},
    {'start': '15:30', 'end': '17:00'},
    {'start': '17:10', 'end': '18:40'},
  ];
  final bellsJson = {
    'weekday': weekdayBells,
    'thursday': weekdayBells,
    'saturday': [
      {'start': '08:30', 'end': '09:40'},
      {'start': '09:50', 'end': '11:00'},
      {'start': '11:10', 'end': '12:20'},
      {'start': '12:30', 'end': '13:40'},
      {'start': '13:50', 'end': '15:00'},
      {'start': '15:10', 'end': '16:20'},
    ],
  };
  final client = MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('index.json')) {
      return http.Response(
        jsonEncode({'group': '21Н', 'days': ['2026-11-20'], 'groups': ['21Н'], 'bellsUpdatedAt': ''}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (path.endsWith('day-2026-11-20.json')) {
      return http.Response(
        jsonEncode({
          'date': '2026-11-20',
          'groups': {
            '21Н': [
              {'number': 1, 'subject': 'ФТТ', 'room': '213', 'teacher': 'Юхновец С.В.'},
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    if (path.endsWith('bells.json')) {
      return http.Response(jsonEncode(bellsJson), 200);
    }
    return http.Response('not found', 404);
  });
  final parser = ParserService(client: client);

  test('манифест читается', () async {
    final manifest = await parser.fetchManifest();
    expect(manifest.days, ['2026-11-20']);
  });

  test('день парсится в уроки по группам', () async {
    final day = await parser.fetchDay('2026-11-20');
    final lessons = day.groups['21Н']!;
    expect(lessons.single.subject, 'ФТТ');
    expect(lessons.single.room, '213');
    expect(lessons.single.teacher, 'Юхновец С.В.');
  });

  test('звонки сайта парсятся в минуты', () async {
    final bells = await parser.fetchBells();
    expect(bells.weekday.periods.first.startMinutes, 510);
    expect(bells.weekday.periods.first.endMinutes, 600);
    expect(bells.saturday.periods.first.endMinutes, 580);
    expect(bells.thursday.periods.first.startMinutes, 510);
  });

  test('404 дает ошибку, а не пустые данные', () async {
    expect(parser.fetchDay('2026-11-21'), throwsA(isA<Exception>()));
  });

  test('источник не демо-данные', () {
    expect(parser.isMock, isFalse);
  });
}