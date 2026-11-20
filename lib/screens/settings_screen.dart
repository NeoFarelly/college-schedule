import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/schedule_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/bells_editor.dart';

class SettingsScreen extends StatefulWidget {
  final ScheduleController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saturday = false;
  bool _refreshing = false;

  Future<void> _forceRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final ok = await widget.controller.refresh();
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Расписание обновлено'
              : 'Не удалось обновить: проверьте интернет',
        ),
      ),
    );
  }

  Future<void> _resetBells() async {
    await widget.controller.resetOverrides();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Звонки сайта восстановлены')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Настройки')),
      body: Stack(
        children: [
          const Wallpaper(),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final bells = controller.bellsForDayType(_saturday);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Группа 21Н',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Расписание берется с guo-mpk.by только для группы 21Н, по дням.',
                          style: TextStyle(fontSize: 13, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Расписание звонков',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'По умолчанию звонки с сайта колледжа. Ваши правки сохраняются отдельно.',
                    style: TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Будни')),
                      ButtonSegment(value: true, label: Text('Суббота')),
                    ],
                    selected: {_saturday},
                    onSelectionChanged: (selection) =>
                        setState(() => _saturday = selection.first),
                  ),
                  const SizedBox(height: 16),
                  BellsEditor(
                    schedule: bells,
                    onChanged: (schedule) =>
                        controller.saveOverride(schedule, saturday: _saturday),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _resetBells,
                      child: const Text('Сбросить к звонкам сайта'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Данные',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Последнее обновление',
                          style: TextStyle(fontSize: 15, color: kTextSecondary),
                        ),
                      ),
                      Text(
                        controller.updatedAt != null
                            ? DateFormat('HH:mm').format(controller.updatedAt!)
                            : 'еще не загружено',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _refreshing ? null : _forceRefresh,
                      child: _refreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Принудительно обновить расписание'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const GlassCard(
                    radius: 20,
                    padding: EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: kTextSecondary,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Документы расписания и скан звонков парсятся в GitHub Actions и обновляются каждые 30 минут.',
                            style: TextStyle(
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