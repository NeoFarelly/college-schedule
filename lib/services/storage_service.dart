import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bell_schedule.dart';
import '../models/cached_schedule.dart';
import '../models/site_data.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const _manifestKey = 'manifest';
  static const _siteBellsKey = 'bells_site';

  String _overrideKey(BellDayType type) => 'bells_override_${type.name}';

  String _dayKey(String date) => 'day_$date';

  ScheduleManifest? loadManifest() {
    final raw = _prefs.getString(_manifestKey);
    if (raw == null) return null;
    try {
      return ScheduleManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveManifest(ScheduleManifest manifest) =>
      _prefs.setString(_manifestKey, jsonEncode(manifest.toJson()));

  SiteBells? loadSiteBells() {
    final raw = _prefs.getString(_siteBellsKey);
    if (raw == null) return null;
    try {
      return SiteBells.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSiteBells(SiteBells bells) =>
      _prefs.setString(_siteBellsKey, jsonEncode(bells.toJson()));

  BellSchedule? loadOverride(BellDayType type) {
    final raw = _prefs.getString(_overrideKey(type));
    if (raw == null) return null;
    try {
      return BellSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOverride(BellSchedule schedule, BellDayType type) =>
      _prefs.setString(_overrideKey(type), jsonEncode(schedule.toJson()));

  Future<void> clearOverrides() async {
    for (final type in BellDayType.values) {
      await _prefs.remove(_overrideKey(type));
    }
  }

  CachedSchedule? loadDay(String date) {
    final raw = _prefs.getString(_dayKey(date));
    if (raw == null) return null;
    try {
      return CachedSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDay(CachedSchedule cache) =>
      _prefs.setString(_dayKey(cache.date), jsonEncode(cache.toJson()));
}