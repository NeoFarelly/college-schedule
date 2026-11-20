import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/bell_schedule.dart';
import '../models/cached_schedule.dart';
import '../models/lesson.dart';
import '../models/site_data.dart';
import 'parser_service.dart';
import 'storage_service.dart';

enum ScheduleStatus { loading, ready, error }

class ScheduleController extends ChangeNotifier {
  final StorageService storage;
  final ParserService parser;

  ScheduleController({required this.storage, required this.parser});

  static const group = '21Н';

  List<String> days = [];
  String selectedDate = isoDate(DateTime.now());
  List<Lesson> lessons = [];
  ScheduleStatus status = ScheduleStatus.loading;
  bool offline = false;
  DateTime? updatedAt;
  SiteBells? siteBells;
  BellSchedule? overrideWeekday;
  BellSchedule? overrideSaturday;
  bool _refreshing = false;
  String _loadedToday = isoDate(DateTime.now());

  Future<void> loadCached() async {
    overrideWeekday = storage.loadOverride(saturday: false);
    overrideSaturday = storage.loadOverride(saturday: true);
    siteBells = storage.loadSiteBells();
    days = storage.loadManifest()?.days ?? [];
    final cache = storage.loadDay(selectedDate);
    if (cache != null && cache.date == selectedDate) {
      lessons = cache.lessons;
      updatedAt = cache.updatedAt;
      status = ScheduleStatus.ready;
    } else {
      lessons = [];
      status = ScheduleStatus.loading;
    }
    notifyListeners();
    unawaited(refresh());
  }

  Future<bool> refresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    if (lessons.isEmpty) {
      status = ScheduleStatus.loading;
      notifyListeners();
    }
    try {
      final manifest = await parser.fetchManifest();
      days = manifest.days;
      await storage.saveManifest(manifest);
      try {
        final bells = await parser.fetchBells();
        siteBells = bells;
        await storage.saveSiteBells(bells);
      } catch (_) {
        // Звонки с сайта появятся после первого OCR-прогона CI.
      }
      await _loadDay(selectedDate);
      offline = false;
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

  Future<void> _loadDay(String date) async {
    if (!days.contains(date)) {
      lessons = [];
      updatedAt = DateTime.now();
      status = ScheduleStatus.ready;
      return;
    }
    final result = await parser.fetchDay(date);
    result.sort((a, b) => a.number.compareTo(b.number));
    lessons = result;
    updatedAt = DateTime.now();
    status = ScheduleStatus.ready;
    await storage.saveDay(CachedSchedule(
      group: group,
      date: date,
      updatedAt: updatedAt!,
      isMock: false,
      lessons: lessons,
    ));
  }

  Future<void> selectDate(String date) async {
    if (date == selectedDate) return;
    selectedDate = date;
    final cache = storage.loadDay(date);
    if (cache != null && cache.date == date) {
      lessons = cache.lessons;
      updatedAt = cache.updatedAt;
      status = ScheduleStatus.ready;
    } else {
      lessons = [];
      status = ScheduleStatus.loading;
    }
    notifyListeners();
    try {
      await _loadDay(date);
      offline = false;
    } catch (_) {
      offline = true;
      if (lessons.isEmpty) status = ScheduleStatus.error;
    }
    notifyListeners();
  }

  Future<void> saveOverride(BellSchedule schedule, {required bool saturday}) async {
    if (saturday) {
      overrideSaturday = schedule;
    } else {
      overrideWeekday = schedule;
    }
    await storage.saveOverride(schedule, saturday: saturday);
    notifyListeners();
  }

  Future<void> resetOverrides() async {
    overrideWeekday = null;
    overrideSaturday = null;
    await storage.clearOverrides();
    notifyListeners();
  }

  BellSchedule bellsFor(DateTime day) =>
      bellsForDayType(day.weekday == DateTime.saturday);

  BellSchedule bellsForDayType(bool saturday) {
    final override = saturday ? overrideSaturday : overrideWeekday;
    if (override != null) return override;
    final site = siteBells;
    if (site != null) return saturday ? site.saturday : site.weekday;
    return saturday ? BellSchedule.saturday() : BellSchedule.weekday();
  }

  bool get isToday => selectedDate == isoDate(DateTime.now());

  void ensureToday() {
    final today = isoDate(DateTime.now());
    if (selectedDate == _loadedToday && selectedDate != today) {
      _loadedToday = today;
      unawaited(selectDate(today));
    }
  }
}