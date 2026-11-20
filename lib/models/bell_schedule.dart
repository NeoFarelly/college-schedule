String formatMinutes(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String formatClock(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

int parseClock(String label) {
  final parts = label.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

enum BellDayType { weekday, thursday, saturday }

class BellPeriod {
  final int startMinutes;
  final int endMinutes;

  const BellPeriod(this.startMinutes, this.endMinutes);

  bool get isValid =>
      startMinutes >= 0 && endMinutes > startMinutes && endMinutes <= 24 * 60;

  String get startLabel => formatMinutes(startMinutes);
  String get endLabel => formatMinutes(endMinutes);

  factory BellPeriod.fromJson(Map<String, dynamic> json) =>
      BellPeriod((json['start'] as num).toInt(), (json['end'] as num).toInt());

  Map<String, dynamic> toJson() => {'start': startMinutes, 'end': endMinutes};
}

class BellSchedule {
  final List<BellPeriod> periods;

  const BellSchedule(this.periods);

  // Колледж: понедельник, вторник, среда, пятница (скан raspisanie-26-27.pdf).
  factory BellSchedule.weekday() => const BellSchedule([
        BellPeriod(495, 540), // 08:15-09:00
        BellPeriod(550, 595), // 09:10-09:55
        BellPeriod(620, 665), // 10:20-11:05
        BellPeriod(675, 720), // 11:15-12:00
        BellPeriod(745, 790), // 12:25-13:10
        BellPeriod(800, 845), // 13:20-14:05
        BellPeriod(855, 900), // 14:15-15:00
        BellPeriod(910, 955), // 15:10-15:55
        BellPeriod(965, 1010), // 16:05-16:50
        BellPeriod(1020, 1065), // 17:00-17:45
        BellPeriod(1075, 1120), // 17:55-18:40
        BellPeriod(1130, 1175), // 18:50-19:35
      ]);

  // Четверг: после 6-й пары информационный час, далее сдвиг.
  factory BellSchedule.thursday() => const BellSchedule([
        BellPeriod(495, 540),
        BellPeriod(550, 595),
        BellPeriod(620, 665),
        BellPeriod(675, 720),
        BellPeriod(745, 790),
        BellPeriod(800, 845),
        BellPeriod(885, 930), // 14:45-15:30
        BellPeriod(940, 985), // 15:40-16:25
        BellPeriod(995, 1040), // 16:35-17:20
        BellPeriod(1050, 1095), // 17:30-18:15
        BellPeriod(1105, 1150), // 18:25-19:10
        BellPeriod(1160, 1205), // 19:20-20:05
      ]);

  // Суббота: сокращенные перемены, 8 пар.
  factory BellSchedule.saturday() => const BellSchedule([
        BellPeriod(495, 540), // 08:15-09:00
        BellPeriod(550, 595), // 09:10-09:55
        BellPeriod(605, 650), // 10:05-10:50
        BellPeriod(660, 705), // 11:00-11:45
        BellPeriod(715, 760), // 11:55-12:40
        BellPeriod(770, 815), // 12:50-13:35
        BellPeriod(825, 870), // 13:45-14:30
        BellPeriod(880, 925), // 14:40-15:25
      ]);

  factory BellSchedule.fromJson(Map<String, dynamic> json) {
    final list = (json['periods'] as List<dynamic>)
        .map((e) => BellPeriod.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.length < 6 || list.length > 12) {
      throw const FormatException('В расписании звонков должно быть от 6 до 12 пар');
    }
    return BellSchedule(list);
  }

  Map<String, dynamic> toJson() =>
      {'periods': periods.map((p) => p.toJson()).toList()};

  BellPeriod? periodFor(int pairNumber) =>
      pairNumber >= 1 && pairNumber <= periods.length
          ? periods[pairNumber - 1]
          : null;

  BellSchedule copyWithPeriod(int index, BellPeriod period) {
    final next = [...periods];
    next[index] = period;
    return BellSchedule(next);
  }
}