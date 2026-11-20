import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bell_schedule.dart';
import '../models/cached_schedule.dart';
import '../models/lesson.dart';
import 'parser_service.dart';
import 'storage_service.dart';

enum ScheduleStatus { loading, ready, error }

class ScheduleController extends ChangeNotifier {
  final StorageService storage;
  final ParserService parser;

  ScheduleController({required this.storage, required this.parser});

  String group = '';
  BellSchedule weekdayBells = BellSchedule.weekday();
  BellSchedule saturdayBells = BellSchedule.saturday();
  List<Lesson> lessons = [];
  ScheduleStatus status = ScheduleStatus.loading;
  bool offline = false;
  bool isMock = false;
  DateTime? updatedAt;
  DateTime? dataDate;
  bool _refreshing = false;

  // Первый кадр строится из кэша, сеть запускается только после этого.
  Future<void> loadCached() async {
    group = storage.loadGroup();
    weekdayBells = storage.loadBells(saturday: false);
    saturdayBells = storage.loadBells(saturday: true);
    final cache = storage.loadCache();
    final now = DateTime.now();
    if (cache != null && cache.group == group && cache.isForToday(now)) {
      lessons = cache.lessons;
      updatedAt = cache.updatedAt;
      dataDate = now;
      isMock = cache.isMock;
      status = ScheduleStatus.ready;
    } else {
      lessons = [];
      status = group.isEmpty ? ScheduleStatus.ready : ScheduleStatus.loading;
    }
    notifyListeners();
    if (group.isNotEmpty) {
      unawaited(refresh());
    }
  }

  Future<bool> refresh() async {
    if (group.isEmpty || _refreshing) return false;
    _refreshing = true;
    if (lessons.isEmpty) {
      status = ScheduleStatus.loading;
      notifyListeners();
    }
    try {
      final result = await parser.fetchSchedule(group);
      result.sort((a, b) => a.number.compareTo(b.number));
      lessons = result;
      updatedAt = DateTime.now();
      dataDate = DateTime.now();
      isMock = parser.isMock;
      offline = false;
      status = ScheduleStatus.ready;
      await storage.saveCache(CachedSchedule(
        group: group,
        date: isoDate(DateTime.now()),
        updatedAt: updatedAt!,
        isMock: isMock,
        lessons: lessons,
      ));
      notifyListeners();
      return true;
    } catch (_) {
      offline = true;
      if (lessons.isEmpty) status = ScheduleStatus.error;
      notifyListeners();
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<void> setGroup(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == group) return;
    group = trimmed;
    await storage.saveGroup(group);
    lessons = [];
    updatedAt = null;
    dataDate = null;
    status = ScheduleStatus.loading;
    notifyListeners();
    await refresh();
  }

  Future<void> saveBells(BellSchedule schedule, {required bool saturday}) async {
    if (saturday) {
      saturdayBells = schedule;
    } else {
      weekdayBells = schedule;
    }
    await storage.saveBells(schedule, saturday: saturday);
    notifyListeners();
  }

  BellSchedule bellsFor(DateTime day) =>
      day.weekday == DateTime.saturday ? saturdayBells : weekdayBells;

  // Вызывается при возврате приложения из фона и при смене суток тикером.
  void ensureToday() {
    final now = DateTime.now();
    if (dataDate != null && isoDate(dataDate!) != isoDate(now)) {
      lessons = [];
      dataDate = null;
      status = ScheduleStatus.loading;
      notifyListeners();
      unawaited(refresh());
    }
  }
}