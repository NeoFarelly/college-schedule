import 'lesson.dart';

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class CachedSchedule {
  final String group;
  final String date;
  final DateTime updatedAt;
  final bool isMock;
  final List<Lesson> lessons;

  const CachedSchedule({
    required this.group,
    required this.date,
    required this.updatedAt,
    required this.isMock,
    required this.lessons,
  });

  bool isForToday(DateTime now) => date == isoDate(now);

  factory CachedSchedule.fromJson(Map<String, dynamic> json) => CachedSchedule(
        group: json['group'] as String,
        date: json['date'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        isMock: json['isMock'] as bool? ?? false,
        lessons: (json['lessons'] as List<dynamic>)
            .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'group': group,
        'date': date,
        'updatedAt': updatedAt.toIso8601String(),
        'isMock': isMock,
        'lessons': lessons.map((l) => l.toJson()).toList(),
      };
}