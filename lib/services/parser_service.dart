import '../models/lesson.dart';

// Заглушка по запросу владельца: реальный HTML колледжа подключается здесь
// (http.get + package:html), контракт fetchSchedule при этом не меняется.
class ParserService {
  bool get isMock => true;

  Future<List<Lesson>> fetchSchedule(String group) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _mockForToday(group);
  }

  static const _pool = <List<String>>[
    ['Математика', '305', 'Смирнова А. П.'],
    ['Информатика', '214', 'Ковалёв Д. И.'],
    ['Английский язык', '118', 'Ефимова Н. С.'],
    ['Физика', '402', 'Гусев П. А.'],
    ['История', '226', 'Лебедева М. В.'],
    ['Физическая культура', 'Спортзал', 'Орлов С. К.'],
    ['Русский язык', '301', 'Зайцева Т. Н.'],
    ['Литература', '301', 'Зайцева Т. Н.'],
    ['Химия', '12', 'Фролов И. М.'],
    ['Обществознание', '226', 'Лебедева М. В.'],
    ['Инженерная графика', '214', 'Ковалёв Д. И.'],
    ['Биология', '12', 'Фролов И. М.'],
  ];

  static const _pairsPerDay = <int, int>{
    DateTime.monday: 5,
    DateTime.tuesday: 6,
    DateTime.wednesday: 5,
    DateTime.thursday: 4,
    DateTime.friday: 5,
    DateTime.saturday: 3,
    DateTime.sunday: 0,
  };

  List<Lesson> _mockForToday(String group) {
    final now = DateTime.now();
    final count = _pairsPerDay[now.weekday] ?? 0;
    if (count == 0) return [];
    // Сдвиг пула от названия группы: разные группы видят разные предметы.
    final shift =
        group.trim().isEmpty ? 0 : group.hashCode.abs() % _pool.length;
    return List.generate(count, (i) {
      final row = _pool[(shift + i) % _pool.length];
      return Lesson(
        number: i + 1,
        subject: row[0],
        room: row[1],
        teacher: row[2],
      );
    });
  }
}