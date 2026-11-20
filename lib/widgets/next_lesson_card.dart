import 'package:flutter/material.dart';

import '../models/bell_schedule.dart';
import '../models/schedule_snapshot.dart';
import 'app_theme.dart';

class NextLessonCard extends StatelessWidget {
  final ScheduleSnapshot snapshot;

  const NextLessonCard({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final next = snapshot.next;
    final nextStart = snapshot.nextStart;

    if (next == null) {
      if (snapshot.phase != DayPhase.lesson) return const SizedBox.shrink();
      return const GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Это последняя пара',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'После нее занятий сегодня нет',
              style: TextStyle(fontSize: 13, color: kTextSecondary),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      tint: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Следующая пара',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            next.subject,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${next.number} пара, начало в ${nextStart != null ? formatClock(nextStart) : ''}',
            style: const TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            next.teacher,
            style: const TextStyle(fontSize: 13, color: kTextSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Кабинет',
            style: TextStyle(fontSize: 13, color: kTextSecondary),
          ),
          const SizedBox(height: 2),
          // Кабинет читается на бегу: масштаб подстраивается под длину строки.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              next.room,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}