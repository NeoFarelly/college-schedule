import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bell_schedule.dart';
import '../models/cached_schedule.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const _groupKey = 'group';
  static const _weekdayBellsKey = 'bells_weekday';
  static const _saturdayBellsKey = 'bells_saturday';
  static const _cacheKey = 'schedule_cache';

  String loadGroup() => _prefs.getString(_groupKey) ?? '';

  Future<void> saveGroup(String group) => _prefs.setString(_groupKey, group);

  BellSchedule loadBells({required bool saturday}) {
    final fallback =
        saturday ? BellSchedule.saturday() : BellSchedule.weekday();
    final raw =
        _prefs.getString(saturday ? _saturdayBellsKey : _weekdayBellsKey);
    if (raw == null) return fallback;
    try {
      return BellSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return fallback;
    }
  }

  Future<void> saveBells(BellSchedule schedule, {required bool saturday}) =>
      _prefs.setString(
        saturday ? _saturdayBellsKey : _weekdayBellsKey,
        jsonEncode(schedule.toJson()),
      );

  CachedSchedule? loadCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return CachedSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCache(CachedSchedule cache) =>
      _prefs.setString(_cacheKey, jsonEncode(cache.toJson()));
}