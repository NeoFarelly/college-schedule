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

  static const defaultGroup = '21Н';

  List<String> days = [];
  List<String> manifestGroups = [];
  String selectedDate = isoDate(DateTime.now());
  String selectedGroup = defaultGroup;
  Map<String, List<Lesson>> dayGroups = {};
  final Map<String, Set<String>> availability = {};
  ScheduleStatus status = ScheduleStatus.loading;
  bool offline = false;
  DateTime? updatedAt;
  SiteBells? siteBells;
  bool enabled = true;
  String blockMessage = '';
  final Map<BellDayType, BellSchedule> overrides = {};
  bool _refreshing = false;
  String _loadedToday = isoDate(DateTime.now());

  List<Lesson> get lessons => dayGroups[selectedGroup] ?? const [];

  bool isDayAvailable(String date) {
    final groups = availability[date];
    if (groups != null) return groups.contains(selectedGroup);
    return days.contains(date);
  }

  void _markAvailability(String date, Map<String, List<Lesson>> groups) {
    availability[date] = groups.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toSet();
  }

  Future<void> _loadAvailability() async {
    final entries = await Future.wait(days.map((date) async {
      final cached = storage.loadDay(date);
      if (cached != null && cached.date == date) {
        return MapEntry(date, cached.groups);
      }
      try {
        final day = await parser.fetchDay(date);
        await storage.saveDay(CachedSchedule(
          date: date,
          updatedAt: DateTime.now(),
          groups: day.groups,
        ));
        return MapEntry(date, day.groups);
      } catch (_) {
        return MapEntry(date, null);
      }
    }));
    for (final entry in entries) {
      final groups = entry.value;
      if (groups == null) {
        availability.remove(entry.key);
      } else {
        _markAvailability(entry.key, groups);
      }
    }
  }

  List<String> get availableGroups {
    final set = <String>{...manifestGroups, ...dayGroups.keys};
    return set.toList()
      ..sort((a, b) => a.replaceAll('Ё', 'Е').compareTo(b.replaceAll('Ё', 'Е')));
  }

  Future<void> loadCached() async {
    final config = storage.loadConfig();
    enabled = config.enabled;
    blockMessage = config.message;
    selectedGroup = storage.loadGroup();
    for (final type in BellDayType.values) {
      final override = storage.loadOverride(type);
      if (override != null) overrides[type] = override;
    }
    siteBells = storage.loadSiteBells();
    final manifest = storage.loadManifest();
    days = manifest?.days ?? [];
    manifestGroups = manifest?.groups ?? [];
    final cache = storage.loadDay(selectedDate);
    if (cache != null && cache.date == selectedDate) {
      dayGroups = cache.groups;
      _markAvailability(selectedDate, dayGroups);
      updatedAt = cache.updatedAt;
      status = ScheduleStatus.ready;
    } else {
      dayGroups = {};
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
      try {
        final config = await parser.fetchConfig();
        enabled = config.enabled;
        blockMessage = config.message;
        await storage.saveConfig(config);
      } catch (_) {
        // Без сети оставляем последний известный флаг.
      }
      if (!enabled) {
        notifyListeners();
        return true;
      }
      final manifest = await parser.fetchManifest();
      days = manifest.days;
      manifestGroups = manifest.groups;
      await storage.saveManifest(manifest);
      await _loadAvailability();
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
      dayGroups = {};
      updatedAt = DateTime.now();
      status = ScheduleStatus.ready;
      return;
    }
    final result = await parser.fetchDay(date);
    dayGroups = result.groups;
    _markAvailability(date, dayGroups);
    updatedAt = DateTime.now();
    status = ScheduleStatus.ready;
    await storage.saveDay(CachedSchedule(
      date: date,
      updatedAt: updatedAt!,
      groups: dayGroups,
    ));
  }

  Future<void> selectGroup(String group) async {
    if (group == selectedGroup) return;
    selectedGroup = group;
    await storage.saveGroup(group);
    notifyListeners();
  }

  Future<void> selectDate(String date) async {
    if (date == selectedDate) return;
    selectedDate = date;
    final cache = storage.loadDay(date);
    if (cache != null && cache.date == date) {
      dayGroups = cache.groups;
      _markAvailability(date, dayGroups);
      updatedAt = cache.updatedAt;
      status = ScheduleStatus.ready;
    } else {
      dayGroups = {};
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