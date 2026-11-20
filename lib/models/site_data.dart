import 'bell_schedule.dart';
import 'lesson.dart';

class AppConfig {
  final bool enabled;
  final String message;

  const AppConfig({required this.enabled, required this.message});

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        enabled: json['enabled'] as bool? ?? true,
        message: json['message'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'enabled': enabled, 'message': message};
}

class ScheduleManifest {
  final List<String> days;
  final List<String> groups;
  final String bellsUpdatedAt;

  const ScheduleManifest({
    required this.days,
    required this.groups,
    required this.bellsUpdatedAt,
  });

  factory ScheduleManifest.fromJson(Map<String, dynamic> json) =>
      ScheduleManifest(
        days: (json['days'] as List<dynamic>).cast<String>(),
        groups: (json['groups'] as List<dynamic>? ?? []).cast<String>(),
        bellsUpdatedAt: json['bellsUpdatedAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'days': days,
        'groups': groups,
        'bellsUpdatedAt': bellsUpdatedAt,
      };
}

class DaySchedule {
  final String date;
  final Map<String, List<Lesson>> groups;

  const DaySchedule({required this.date, required this.groups});

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
        date: json['date'] as String,
        groups: (json['groups'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>)
                .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
        ),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'groups': groups.map((key, value) => MapEntry(key, value.map((l) => l.toJson()).toList())),
      };
}

class SiteBells {
  final BellSchedule weekday;
  final BellSchedule thursday;
  final BellSchedule saturday;

  const SiteBells({
    required this.weekday,
    required this.thursday,
    required this.saturday,
  });

  factory SiteBells.fromJson(Map<String, dynamic> json) => SiteBells(
        weekday: _schedule(json['weekday']),
        thursday: _schedule(json['thursday'] ?? json['weekday']),
        saturday: _schedule(json['saturday']),
      );

  static BellSchedule _schedule(dynamic value) => BellSchedule(
        (value as List<dynamic>)
            .map(
              (e) => BellPeriod(
                parseClock((e as Map<String, dynamic>)['start'] as String),
                parseClock(e['end'] as String),
              ),
            )
            .toList(),
      );

  BellSchedule forType(BellDayType type) => switch (type) {
        BellDayType.weekday => weekday,
        BellDayType.thursday => thursday,
        BellDayType.saturday => saturday,
      };

  Map<String, dynamic> toJson() => {
        'weekday': _labels(weekday),
        'thursday': _labels(thursday),
        'saturday': _labels(saturday),
      };

  static List<Map<String, String>> _labels(BellSchedule schedule) => schedule
      .periods
      .map((p) => {'start': p.startLabel, 'end': p.endLabel})
      .toList();
}