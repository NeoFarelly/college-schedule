import 'dart:convert';

import 'package:college_schedule/app.dart';
import 'package:college_schedule/models/cached_schedule.dart';
import 'package:college_schedule/models/lesson.dart';
import 'package:college_schedule/services/schedule_controller.dart';
import 'package:college_schedule/services/parser_service.dart';
import 'package:college_schedule/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingParser extends ParserService {
  @override
  Future<List<Lesson>> fetchSchedule(String group) async =>
      throw Exception('сеть недоступна');
}

Future<ScheduleController> _makeController({
  Map<String, Object> prefs = const {},
  ParserService? parser,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = StorageService(await SharedPreferences.getInstance());
  final controller = ScheduleController(
    storage: storage,
    parser: parser ?? ParserService(),
  );
  await controller.loadCached();
  return controller;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  testWidgets('группа не указана: пустое состояние и вход в настройки',
      (tester) async {
    final controller = await _makeController();
    await tester.pumpWidget(ScheduleApp(controller: controller));
    await tester.pump();

    expect(find.text('Укажите учебную группу'), findsOneWidget);
    await tester.tap(find.text('Открыть настройки'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Учебная группа'), findsOneWidget);
    expect(find.text('Расписание звонков'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('кэш отображается сразу, до ответа сети', (tester) async {
    final now = DateTime.now();
    final cache = {
      'group': 'ИС-21',
      'date': isoDate(now),
      'updatedAt': now.toIso8601String(),
      'isMock': true,
      'lessons': [
        const Lesson(
          number: 1,
          subject: 'Математика',
          room: '305',
          teacher: 'Смирнова А. П.',
        ).toJson(),
      ],
    };
    final controller = await _makeController(
      prefs: {'group': 'ИС-21', 'schedule_cache': jsonEncode(cache)},
    );
    await tester.pumpWidget(ScheduleApp(controller: controller));
    await tester.pump();

    expect(find.text('Группа ИС-21'), findsOneWidget);
    expect(find.text('Математика'), findsWidgets);
    expect(find.text('305'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('ошибка сети без кэша: состояние ошибки и повтор',
      (tester) async {
    final controller = await _makeController(
      prefs: {'group': 'ИС-21'},
      parser: _FailingParser(),
    );
    await tester.pumpWidget(ScheduleApp(controller: controller));
    await tester.pump();

    expect(find.text('Не удалось загрузить расписание'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pump();
    expect(find.text('Не удалось загрузить расписание'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('сохранение группы из настроек запускает загрузку',
      (tester) async {
    final controller = await _makeController();
    await tester.pumpWidget(ScheduleApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Открыть настройки'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField), 'ПО-33');
    await tester.tap(find.text('Сохранить группу'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.group, 'ПО-33');
    expect(controller.status, ScheduleStatus.ready);
    if (DateTime.now().weekday != DateTime.sunday) {
      expect(controller.lessons, isNotEmpty);
    }

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}