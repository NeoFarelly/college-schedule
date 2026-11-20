import 'bell_schedule.dart';

class ScheduleManifest {
  final List<String> days;
  final String bellsUpdatedAt;

  const ScheduleManifest({
    required this.days,
    required this.bellsUpdatedAt,
  });

  factory ScheduleManifest.fromJson(Map<String, dynamic> json) =>
      ScheduleManifest(
        days: (json['days'] as List<dynamic>).cast<String>(),
        bellsUpdatedAt: json['bellsUpdatedAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'days': days,
        'bellsUpdatedAt': bellsUpdatedAt,
      };
}

class SiteBells {
  final BellSchedule weekday;
  final BellSchedule saturday;

  const SiteBells({required this.weekday, required this.saturday});

  factory SiteBells.fromJson(Map<String, dynamic> json) => SiteBells(
        weekday: _schedule(json['weekday']),
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

  Map<String, dynamic> toJson() => {
        'weekday': weekday.periods
            .map((p) => {'start': p.startLabel, 'end': p.endLabel})
            .toList(),
        'saturday': saturday.periods
            .map((p) => {'start': p.startLabel, 'end': p.endLabel})
            .toList(),
      };
}