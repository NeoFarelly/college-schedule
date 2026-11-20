import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/schedule_controller.dart';
import 'services/parser_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  final prefs = await SharedPreferences.getInstance();
  final controller = ScheduleController(
    storage: StorageService(prefs),
    parser: ParserService(),
  );
  // Первый кадр строится сразу из кэша, сеть не блокирует запуск.
  await controller.loadCached();
  runApp(ScheduleApp(controller: controller));
}