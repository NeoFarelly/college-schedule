import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/schedule_controller.dart';
import 'services/parser_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final controller = ScheduleController(
    storage: storage,
    parser: ParserService(),
  );
  // Первый кадр строится сразу из кэша, сеть не блокирует запуск.
  await controller.loadCached();
  if (!kIsWeb) {
    final notifications = NotificationService(
      controller: controller,
      storage: storage,
    );
    unawaited(notifications.init());
  }
  runApp(ScheduleApp(controller: controller));
}