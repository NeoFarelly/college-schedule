import 'package:flutter/material.dart';

import '../models/bell_schedule.dart';
import '../models/lesson.dart';
import 'app_theme.dart';

class LessonTile extends StatelessWidget {
  final Lesson lesson;
  final BellPeriod? period;
  final bool isCurrent;
  final bool isPast;

  const LessonTile({
    super.key,
    required this.lesson,
    required this.period,
    required this.isCurrent,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final subjectColor = isPast ? kTextSecondary : kTextPrimary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? kSurfaceHigh : kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrent ? kBorder : Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${lesson.number}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isCurrent ? kAccent : kTextSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period?.startLabel ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: subjectColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  period?.endLabel ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: subjectColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lesson.teacher,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              lesson.room,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: subjectColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}