import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bell_schedule.dart';
import '../models/cached_schedule.dart';
import '../models/notification_settings.dart';
import '../models/site_data.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const _manifestKey = 'manifest';
  static const _siteBellsKey = 'bells_site';
  static const _groupKey = 'group';
  static const _configKey = 'config';
  static const _notificationKey = 'notification_settings';

  NotificationSettings loadNotificationSettings() {
    final raw = _prefs.getString(_notificationKey);
    if (raw == null) return const NotificationSettings();
    try {
      return NotificationSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const NotificationSettings();
    }
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) =>
      _prefs.setString(_notificationKey, jsonEncode(settings.toJson()));

  AppConfig loadConfig() {
    final raw = _prefs.getString(_configKey);
    if (raw == null) return const AppConfig(enabled: true, message: '');
    try {
      return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppConfig(enabled: true, message: '');
    }
  }

  Future<void> saveConfig(AppConfig config) =>
      _prefs.setString(_configKey, jsonEncode(config.toJson()));

  String loadGroup() => _prefs.getString(_groupKey) ?? '21Н';

  Future<void> saveGroup(String group) => _prefs.setString(_groupKey, group);

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