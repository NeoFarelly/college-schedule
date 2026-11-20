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
  static const _overrideWeekdayKey = 'bells_override_weekday';
  static const _overrideSaturdayKey = 'bells_override_saturday';

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

  BellSchedule? loadOverride({required bool saturday}) {
    final raw = _prefs.getString(
      saturday ? _overrideSaturdayKey : _overrideWeekdayKey,
    );
    if (raw == null) return null;
    try {
      return BellSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOverride(BellSchedule schedule, {required bool saturday}) =>
      _prefs.setString(
        saturday ? _overrideSaturdayKey : _overrideWeekdayKey,
        jsonEncode(schedule.toJson()),
      );

  Future<void> clearOverrides() async {
    await _prefs.remove(_overrideWeekdayKey);
    await _prefs.remove(_overrideSaturdayKey);
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