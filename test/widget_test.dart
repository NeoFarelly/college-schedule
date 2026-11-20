import 'dart:convert';

import 'package:college_schedule/app.dart';
import 'package:college_schedule/models/cached_schedule.dart';
import 'package:college_schedule/models/lesson.dart';
import 'package:college_schedule/services/parser_service.dart';
import 'package:college_schedule/services/schedule_controller.dart';
import 'package:college_schedule/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _todayLesson = Lesson(
  number: 1,
  subject: 'Математика',
  room: '305',
  teacher: 'Смирнова А. П.',
);
const _tomorrowLesson = Lesson(
  number: 1,
  subject: 'Физика',
  room: '402',
  teacher: 'Гусев П. А.',
);
const _otherGroupLesson = Lesson(
  number: 1,
  subject: 'Химия',
  room: '12',
  teacher: 'Фролов И. М.',
);

final _weekdayBells = [
  {'start': '08:30', 'end': '10:00'},
  {'start': '10:10', 'end': '11:40'},
  {'start': '12:10', 'end': '13:40'},
  {'start': '13:50', 'end': '15:20'},
  {'start': '15:30', 'end': '17:00'},
  {'start': '17:10', 'end': '18:40'},
];
final _bellsJson = {
  'weekday': _weekdayBells,
  'thursday': _weekdayBells,
  'saturday': [
    {'start': '08:30', 'end': '09:40'},
    {'start': '09:50', 'end': '11:00'},
    {'start': '11:10', 'end': '12:20'},
    {'start': '12:30', 'end': '13:40'},
    {'start': '13:50', 'end': '15:00'},
    {'start': '15:10', 'end': '16:20'},
  ],
};

http.Client _okClient(String today, String tomorrow) => MockClient((request) async {
      final path = request.url.path;
      const headers = {'content-type': 'application/json; charset=utf-8'};
      if (path.endsWith('index.json')) {
        return http.Response(
          jsonEncode({
            'group': '21Н',
            'days': [today, tomorrow],
            'groups': ['21Н', '21О'],
            'bellsUpdatedAt': '',
          }),
          200,
          headers: headers,
        );
      }
      if (path.endsWith('day-$today.json')) {
        return http.Response(
          jsonEncode({
            'date': today,
            'groups': {
              '21Н': [_todayLesson.toJson()],
              '21О': [_otherGroupLesson.toJson()],
            },
          }),
          200,
          headers: headers,
        );
      }
      if (path.endsWith('day-$tomorrow.json')) {
        return http.Response(
          jsonEncode({
            'date': tomorrow,
            'groups': {'21Н': [_tomorrowLesson.toJson()]},
          }),
          200,
          headers: headers,
        );
      }
      if (path.endsWith('bells.json')) {
        return http.Response(jsonEncode(_bellsJson), 200, headers: headers);
      }
      return http.Response('not found', 404);
    });

http.Client _failClient() => MockClient((_) async => http.Response('err', 500));

Future<ScheduleController> _makeController({
  Map<String, Object> prefs = const {},
  http.Client? client,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = StorageService(await SharedPreferences.getInstance());
  final controller = ScheduleController(
    storage: storage,
    parser: ParserService(client: client ?? _failClient()),
  );
  await controller.loadCached();
  return controller;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  testWidgets('ошибка сети без кэша: состояние ошибки и повтор', (tester) async {
    final controller = await _makeController();
    await tester.pumpWidget(ScheduleApp(controller: controller));
    await tester.pump();

    expect(find.text('Не удалось загрузить расписание'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pump();
    expect(find.text('Не удалось загрузить расписание'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('кэш отображается сразу, до ответа сети', (tester) async {
    final now = DateTime.now();
    final today = isoDate(now);
    final controller = await _makeController(prefs: {
      'manifest': jsonEncode({'days': [today], 'groups': ['21Н'], 'bellsUpdatedAt': ''}),
      'bells_site': jsonEncode(_bellsJson),
      'day_$today': jsonEncode(CachedSchedule(
        date: today,
        updatedAt: now,
        groups: {'21Н': [_todayLesson]},
      ).toJson()),
    });
    await tester.pumpWidget(ScheduleApp(controller: controller));
    await tester.pump();

    expect(find.text('Группа 21Н'), findsOneWidget);
    expect(find.text('Математика'), findsWidgets);
    expect(find.textContaining('Офлайн'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('настройки открываются и показывают звонки', (tester) async {
    final now = DateTime.now();
    final today = isoDate(now);
    final tomorrow = isoDate(now.add(const Duration(days: 1)));
    final controller = await _makeController(client: _okClient(today, tomorrow));
    await tester.pumpWidget(ScheduleApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('Настройки'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Расписание звонков'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Сбросить к звонкам сайта'), 300);
    expect(find.text('Сбросить к звонкам сайта'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('принудительное обновление показывает результат', (tester) async {
    final now = DateTime.now();
    final today = isoDate(now);
    final tomorrow = isoDate(now.add(const Duration(days: 1)));
    final controller = await _makeController(client: _okClient(today, tomorrow));
    await tester.pumpWidget(ScheduleApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip('Настройки'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(find.text('Принудительно обновить расписание'), 300);
    await tester.tap(find.text('Принудительно обновить расписание'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Расписание обновлено'), findsOneWidget);
    expect(controller.lessons, isNotEmpty);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('переключение дня меняет расписание', (tester) async {
    final now = DateTime.now();
    final today = isoDate(now);
    final tomorrow = isoDate(now.add(const Duration(days: 1)));
    final controller = await _makeController(client: _okClient(today, tomorrow));
    await tester.pumpWidget(ScheduleApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Математика'), findsWidgets);
    final label = DateFormat('EE d.MM', 'ru').format(now.add(const Duration(days: 1)));
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.selectedDate, tomorrow);
    expect(find.text('Физика'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('выбор группы меняет расписание', (tester) async {
    final now = DateTime.now();
    final today = isoDate(now);
    final tomorrow = isoDate(now.add(const Duration(days: 1)));
    final controller = await _makeController(client: _okClient(today, tomorrow));
    await tester.pumpWidget(ScheduleApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Математика'), findsWidgets);
    await tester.tap(find.text('Группа 21Н'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('21О'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.selectedGroup, '21О');
    expect(find.text('Химия'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}