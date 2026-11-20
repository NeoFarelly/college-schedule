import 'package:flutter/material.dart';

import '../models/bell_schedule.dart';
import '../models/schedule_snapshot.dart';
import 'app_theme.dart';

String _countdown(DateTime target, DateTime now) {
  final total = target.difference(now).inSeconds;
  final clamped = total < 0 ? 0 : total;
  final h = clamped ~/ 3600;
  final m = (clamped % 3600) ~/ 60;
  final s = clamped % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

class NowCard extends StatelessWidget {
  final ScheduleSnapshot snapshot;
  final DateTime now;

  const NowCard({super.key, required this.snapshot, required this.now});

  @override
  Widget build(BuildContext context) {
    final current = snapshot.current;
    final next = snapshot.next;
    final target = snapshot.target;

    final (label, caption, showTimer) = switch (snapshot.phase) {
      DayPhase.lesson => ('Сейчас идет', 'до конца пары', true),
      DayPhase.betweenLessons => ('Сейчас перемена', 'до конца перемены', true),
      DayPhase.beforeStart => ('До первой пары', 'до начала занятий', true),
      DayPhase.afterEnd => ('Пары на сегодня закончились', 'На сегодня всё', false),
      DayPhase.noLessons => ('Сегодня пар нет', '', false),
    };

    var detail = '';
    var timerCaption = caption;
    switch (snapshot.phase) {
      case DayPhase.lesson:
        detail =
            '${current!.number} пара, каб. ${current.room}, ${current.teacher}';
        timerCaption = 'до конца пары, конец в ${formatClock(target!)}';
      case DayPhase.betweenLessons:
        if (next != null && target != null) {
          detail = 'Дальше: ${next.subject} в ${formatClock(target)}';
        }
      case DayPhase.beforeStart:
        if (target != null) detail = 'Начало в ${formatClock(target)}';
      case DayPhase.afterEnd:
      case DayPhase.noLessons:
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (snapshot.phase == DayPhase.lesson) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: kAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (current != null) ...[
            const SizedBox(height: 8),
            Text(
              current.subject,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
          ],
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(fontSize: 13, color: kTextSecondary),
            ),
          ],
          if (showTimer && target != null) ...[
            const SizedBox(height: 14),
            Text(
              _countdown(target, now),
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
                height: 1.0,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              timerCaption,
              style: const TextStyle(fontSize: 13, color: kTextSecondary),
            ),
          ] else if (caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              caption,
              style: const TextStyle(fontSize: 13, color: kTextSecondary),
            ),
          ],
        ],
      ),
    );
  }
}