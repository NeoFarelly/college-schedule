import 'lesson.dart';
import 'site_data.dart';

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class CachedSchedule {
  final String date;
  final DateTime updatedAt;
  final Map<String, List<Lesson>> groups;

  const CachedSchedule({
    required this.date,
    required this.updatedAt,
    required this.groups,
  });

  bool isForToday(DateTime now) => date == isoDate(now);

  factory CachedSchedule.fromJson(Map<String, dynamic> json) =>
      CachedSchedule(
        date: json['date'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        groups: DaySchedule.fromJson({'date': json['date'], 'groups': json['groups']}).groups,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'updatedAt': updatedAt.toIso8601String(),
        'groups': groups.map((key, value) => MapEntry(key, value.map((l) => l.toJson()).toList())),
      };
}