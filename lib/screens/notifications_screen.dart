import 'package:flutter/material.dart';

import '../services/schedule_controller.dart';
import '../widgets/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  final ScheduleController controller;

  const NotificationsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Уведомления')),
      body: Stack(
        children: [
          const Wallpaper(),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final settings = controller.notificationSettings;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  GlassCard(
                    radius: 20,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: settings.enabled,
                            onChanged: (value) => controller
                                .saveNotificationSettings(
                              settings.copyWith(enabled: value),
                            ),
                            title: const Text(
                              'Уведомление в шторке',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kTextPrimary,
                              ),
                            ),
                            subtitle: const Text(
                              'Текущая пара, кабинет, преподаватель и время звонка',
                              style: TextStyle(
                                fontSize: 13,
                                color: kTextSecondary,
                              ),
                            ),
                          ),
                          SwitchListTile(
                            value: settings.showNext,
                            onChanged: settings.enabled
                                ? (value) => controller
                                    .saveNotificationSettings(
                                      settings.copyWith(showNext: value),
                                    )
                                : null,
                            title: const Text(
                              'Показывать следующую пару',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kTextPrimary,
                              ),
                            ),
                            subtitle: const Text(
                              'Предмет, преподаватель, кабинет и начало',
                              style: TextStyle(
                                fontSize: 13,
                                color: kTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Напоминать до звонка',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Отдельное уведомление за выбранное время до начала пары.',
                    style: TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Выкл')),
                      ButtonSegment(value: 1, label: Text('1 мин')),
                      ButtonSegment(value: 3, label: Text('3 мин')),
                      ButtonSegment(value: 5, label: Text('5 мин')),
                    ],
                    selected: {settings.remindMinutes},
                    onSelectionChanged: settings.enabled
                        ? (selection) => controller.saveNotificationSettings(
                              settings.copyWith(
                                remindMinutes: selection.first,
                              ),
                            )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    radius: 20,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: kTextSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            settings.enabled
                                ? 'Уведомление живет в шторке, пока приложение запущено. Если оно не появляется, разрешите уведомления для приложения в настройках Android.'
                                : 'Включите тумблер, чтобы видеть текущую пару и следующий звонок в шторке Android.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: kTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}