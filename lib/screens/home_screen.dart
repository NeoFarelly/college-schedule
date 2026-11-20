import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/schedule_snapshot.dart';
import '../services/schedule_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/lesson_tile.dart';
import '../widgets/next_lesson_card.dart';
import '../widgets/now_card.dart';
import '../widgets/state_views.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ScheduleController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final Timer _ticker;
  final ValueNotifier<DateTime> _now = ValueNotifier(DateTime.now());
  final ValueNotifier<int?> _currentPair = ValueNotifier(null);
  int _lastDay = DateTime.now().day;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    _onTick(_ticker);
  }

  // Тикер обновляет только карточки; список перерисовывается
  // лишь при смене номера текущей пары.
  void _onTick(Timer _) {
    final t = DateTime.now();
    _now.value = t;
    final controller = widget.controller;
    final number = controller.isToday
        ? snapshotAt(controller.lessons, controller.bellsFor(t), t).current?.number
        : null;
    if (number != _currentPair.value) _currentPair.value = number;
    if (t.day != _lastDay) {
      _lastDay = t.day;
      controller.ensureToday();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.ensureToday();
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    _now.dispose();
    _currentPair.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Stack(
        children: [
          const Wallpaper(),
          SafeArea(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final controller = widget.controller;
                if (controller.status == ScheduleStatus.loading &&
                    controller.lessons.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(height: 16),
                        Text(
                          'Загружаю расписание',
                          style: TextStyle(fontSize: 15, color: kTextSecondary),
                        ),
                      ],
                    ),
                  );
                }
                if (controller.status == ScheduleStatus.error &&
                    controller.lessons.isEmpty) {
                  return MessageStateView(
                    icon: Icons.cloud_off_outlined,
                    title: 'Не удалось загрузить расписание',
                    subtitle:
                        'Проверьте подключение к интернету и попробуйте снова.',
                    actionLabel: 'Повторить',
                    onAction: () => controller.refresh(),
                  );
                }
                if (controller.lessons.isEmpty) {
                  final published = controller.days.contains(controller.selectedDate);
                  return MessageStateView(
                    icon: Icons.event_busy_outlined,
                    title: 'В этот день пар нет',
                    subtitle: published
                        ? 'У группы 21Н в этот день занятий нет.'
                        : 'Расписание на этот день еще не опубликовано на сайте.',
                  );
                }
                return _buildSchedule(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule(ScheduleController controller) {
    final selected = DateTime.parse(controller.selectedDate);
    final dateLabel = DateFormat('EEEE, d MMMM', 'ru').format(selected);
    final capitalized = dateLabel[0].toUpperCase() + dateLabel.substring(1);

    return RefreshIndicator(
      color: kAccent,
      backgroundColor: const Color(0xE61C2333),
      onRefresh: () async {
        await controller.refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capitalized,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Группа 21Н',
                      style: TextStyle(fontSize: 14, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Настройки',
                color: kTextPrimary,
                iconSize: 26,
              ),
            ],
          ),
          const SizedBox(height: 6),
          _StatusLine(controller: controller),
          const SizedBox(height: 12),
          if (controller.days.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = controller.days[index];
                  final label = DateFormat('EE d.MM', 'ru')
                      .format(DateTime.parse(date));
                  return ChoiceChip(
                    label: Text(label),
                    selected: date == controller.selectedDate,
                    showCheckmark: false,
                    onSelected: (_) => controller.selectDate(date),
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: date == controller.selectedDate
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: date == controller.selectedDate
                          ? Colors.black
                          : kTextSecondary,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          if (controller.isToday)
            ValueListenableBuilder<DateTime>(
              valueListenable: _now,
              builder: (context, now, _) {
                final snapshot = snapshotAt(
                  controller.lessons,
                  controller.bellsFor(now),
                  now,
                );
                return Column(
                  children: [
                    NowCard(snapshot: snapshot, now: now),
                    const SizedBox(height: 12),
                    NextLessonCard(snapshot: snapshot),
                  ],
                );
              },
            ),
          if (controller.isToday) const SizedBox(height: 24),
          Text(
            controller.isToday ? 'Сегодня' : 'Пары за выбранный день',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<int?>(
            valueListenable: _currentPair,
            builder: (context, currentNumber, _) {
              final t = DateTime.now();
              final bells = controller.bellsFor(selected);
              return Column(
                children: [
                  for (final lesson in controller.lessons)
                    LessonTile(
                      lesson: lesson,
                      period: bells.periodFor(lesson.number),
                      isCurrent: lesson.number == currentNumber,
                      isPast: controller.isToday &&
                          _isPast(bells.periodFor(lesson.number)?.endMinutes, t),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isPast(int? endMinutes, DateTime now) {
    if (endMinutes == null) return false;
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      endMinutes ~/ 60,
      endMinutes % 60,
    );
    return !now.isBefore(end);
  }
}

class _StatusLine extends StatelessWidget {
  final ScheduleController controller;

  const _StatusLine({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final updated = controller.updatedAt;
    final timeText = updated != null ? DateFormat('HH:mm').format(updated) : '';
    final String text;
    if (controller.offline) {
      text = timeText.isEmpty
          ? 'Офлайн: расписание не загружено'
          : 'Офлайн: кэш от $timeText';
    } else {
      text = timeText.isEmpty ? 'Данные не загружены' : 'Обновлено в $timeText';
    }
    return Row(
      children: [
        Icon(
          controller.offline
              ? Icons.cloud_off_outlined
              : Icons.check_circle_outline,
          size: 14,
          color: kTextSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$text, источник guo-mpk.by',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: kTextSecondary),
          ),
        ),
      ],
    );
  }
}