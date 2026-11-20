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
  final Map<BellDayType, BellSchedule> overrides = {};
  bool _refreshing = false;
  String _loadedToday = isoDate(DateTime.now());

  Future<void> loadCached() async {
    for (final type in BellDayType.values) {
      final override = storage.loadOverride(type);
      if (override != null) overrides[type] = override;
    }
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

  Future<void> saveOverride(BellSchedule schedule, BellDayType type) async {
    overrides[type] = schedule;
    await storage.saveOverride(schedule, type);
    notifyListeners();
  }

  Future<void> resetOverrides() async {
    overrides.clear();
    await storage.clearOverrides();
    notifyListeners();
  }

  BellSchedule bellsFor(DateTime day) => bellsForType(
        day.weekday == DateTime.saturday
            ? BellDayType.saturday
            : day.weekday == DateTime.thursday
                ? BellDayType.thursday
                : BellDayType.weekday,
      );

  BellSchedule bellsForType(BellDayType type) {
    final override = overrides[type];
    if (override != null) return override;
    final site = siteBells;
    if (site != null) return site.forType(type);
    return switch (type) {
      BellDayType.weekday => BellSchedule.weekday(),
      BellDayType.thursday => BellSchedule.thursday(),
      BellDayType.saturday => BellSchedule.saturday(),
    };
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