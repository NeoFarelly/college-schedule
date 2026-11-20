class Lesson {
  final int number;
  final String subject;
  final String room;
  final String teacher;

  const Lesson({
    required this.number,
    required this.subject,
    required this.room,
    required this.teacher,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        number: (json['number'] as num).toInt(),
        subject: json['subject'] as String,
        room: json['room'] as String,
        teacher: json['teacher'] as String,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'subject': subject,
        'room': room,
        'teacher': teacher,
      };
}