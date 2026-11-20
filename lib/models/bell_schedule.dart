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

  // Пары по 90 минут, перемены 10 минут, после второй пары большой перерыв.
  factory BellSchedule.weekday() => const BellSchedule([
        BellPeriod(510, 600), // 08:30-10:00
        BellPeriod(610, 700), // 10:10-11:40
        BellPeriod(730, 820), // 12:10-13:40
        BellPeriod(830, 920), // 13:50-15:20
        BellPeriod(930, 1020), // 15:30-17:00
        BellPeriod(1030, 1120), // 17:10-18:40
      ]);

  // Сокращенные пары по 70 минут.
  factory BellSchedule.saturday() => const BellSchedule([
        BellPeriod(510, 580), // 08:30-09:40
        BellPeriod(590, 660), // 09:50-11:00
        BellPeriod(670, 740), // 11:10-12:20
        BellPeriod(750, 820), // 12:30-13:40
        BellPeriod(830, 900), // 13:50-15:00
        BellPeriod(910, 980), // 15:10-16:20
      ]);

  factory BellSchedule.fromJson(Map<String, dynamic> json) {
    final list = (json['periods'] as List<dynamic>)
        .map((e) => BellPeriod.fromJson(e as Map<String, dynamic>))
        .toList();
    if (list.length < 6 || list.length > 7) {
      throw const FormatException('В расписании звонков должно быть 6 или 7 пар');
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