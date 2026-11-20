import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cached_schedule.dart';
import '../models/schedule_snapshot.dart';
import '../services/schedule_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/group_picker.dart';
import '../widgets/lesson_tile.dart';
import '../widgets/next_lesson_card.dart';
import '../widgets/now_card.dart';
import '../widgets/state_views.dart';
import 'bells_screen.dart';
import 'notifications_screen.dart';

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
      unawaited(widget.controller.refresh());
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

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xF0101426),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule, color: kTextSecondary),
              title: const Text(
                'Расписание звонков',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        BellsScreen(controller: widget.controller),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_outlined,
                color: kTextSecondary,
              ),
              title: const Text(
                'Уведомления',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              subtitle: kIsWeb
                  ? const Text(
                      'Доступно в Android-приложении',
                      style: TextStyle(fontSize: 12, color: kTextSecondary),
                    )
                  : null,
              enabled: !kIsWeb,
              onTap: kIsWeb
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              NotificationsScreen(controller: widget.controller),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final controller = widget.controller;
    final selectable =
        controller.days.where(controller.isDayAvailable).toList();
    if (selectable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Для группы ${controller.selectedGroup} нет дней с парами',
          ),
        ),
      );
      return;
    }
    final initial = selectable.contains(controller.selectedDate)
        ? DateTime.parse(controller.selectedDate)
        : DateTime.parse(selectable.first);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2026, 9, 1),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      selectableDayPredicate: (day) => controller.isDayAvailable(isoDate(day)),
    );
    if (picked == null || !mounted) return;
    await controller.selectDate(isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _pickDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEEE, d MMMM', 'ru').format(
                      DateTime.parse(widget.controller.selectedDate),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.expand_more, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const Wallpaper(),
          SafeArea(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final controller = widget.controller;
                if (!controller.enabled) {
                  return MessageStateView(
                    icon: Icons.lock_outline,
                    title: 'Приложение отключено',
                    subtitle: controller.blockMessage.isNotEmpty
                        ? controller.blockMessage
                        : 'Владелец временно отключил приложение.',
                  );
                }
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
                        ? 'У группы ${controller.selectedGroup} в этот день занятий нет.'
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
                child: Text(
                  capitalized,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _openMenu,
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Настройки',
                color: kTextPrimary,
                iconSize: 26,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => showGroupPicker(context, controller),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text('Группа ${controller.selectedGroup}'),
              ),
              const SizedBox(width: 10),
              Expanded(child: _StatusLine(controller: controller)),
            ],
          ),
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
                  final enabled = controller.isDayAvailable(date);
                  final isSelected =
                      date == controller.selectedDate && enabled;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: enabled
                        ? (_) => controller.selectDate(date)
                        : null,
                    selectedColor: Colors.white,
                    backgroundColor:
                        Colors.white.withValues(alpha: enabled ? 0.08 : 0.03),
                    disabledColor: Colors.white.withValues(alpha: 0.03),
                    side: BorderSide(
                      color: Colors.white
                          .withValues(alpha: enabled ? 0.16 : 0.06),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? Colors.black
                          : enabled
                              ? kTextSecondary
                              : kTextSecondary.withValues(alpha: 0.38),
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

  const _StatusLine({required this.controller});

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