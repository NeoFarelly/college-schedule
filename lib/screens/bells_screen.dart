import 'package:flutter/material.dart';

import '../models/bell_schedule.dart';
import '../services/schedule_controller.dart';
import '../widgets/app_theme.dart';
import '../widgets/bells_editor.dart';
import 'settings_screen.dart';

class BellsScreen extends StatefulWidget {
  final ScheduleController controller;

  const BellsScreen({super.key, required this.controller});

  @override
  State<BellsScreen> createState() => _BellsScreenState();
}

class _BellsScreenState extends State<BellsScreen> {
  BellDayType _type = BellDayType.weekday;

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
      appBar: AppBar(
        title: const Text('Расписание звонков'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(controller: controller),
              ),
            ),
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Настройки',
          ),
        ],
      ),
      body: Stack(
        children: [
          const Wallpaper(),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  const Text(
                    'По умолчанию звонки с сайта колледжа. Ваши правки сохраняются отдельно.',
                    style: TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<BellDayType>(
                    segments: const [
                      ButtonSegment(
                        value: BellDayType.weekday,
                        label: Text('Будни'),
                      ),
                      ButtonSegment(
                        value: BellDayType.thursday,
                        label: Text('Четверг'),
                      ),
                      ButtonSegment(
                        value: BellDayType.saturday,
                        label: Text('Суббота'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) =>
                        setState(() => _type = selection.first),
                  ),
                  const SizedBox(height: 16),
                  BellsEditor(
                    schedule: controller.bellsForType(_type),
                    onChanged: (schedule) =>
                        controller.saveOverride(schedule, _type),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _resetBells,
                      child: const Text('Сбросить к звонкам сайта'),
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