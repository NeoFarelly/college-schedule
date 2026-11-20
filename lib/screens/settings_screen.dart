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
  late final TextEditingController _groupController;
  bool _saturday = false;
  bool _refreshing = false;
  String? _groupError;

  @override
  void initState() {
    super.initState();
    _groupController = TextEditingController(text: widget.controller.group);
  }

  @override
  void dispose() {
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    final value = _groupController.text.trim();
    if (value.isEmpty) {
      setState(() => _groupError = 'Введите название или номер группы');
      return;
    }
    setState(() => _groupError = null);
    await widget.controller.setGroup(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Группа сохранена, расписание обновляется')),
    );
  }

  Future<void> _forceRefresh() async {
    if (_refreshing) return;
    if (widget.controller.group.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала укажите учебную группу')),
      );
      return;
    }
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Настройки')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const Text(
                'Учебная группа',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _groupController,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveGroup(),
                decoration: InputDecoration(
                  labelText: 'Название или номер группы',
                  hintText: 'Например, ИС-21',
                  errorText: _groupError,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveGroup,
                  child: const Text('Сохранить группу'),
                ),
              ),
              const SizedBox(height: 28),
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
                'Будни и суббота хранятся отдельно. Изменения сохраняются автоматически.',
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
                schedule:
                    _saturday ? controller.saturdayBells : controller.weekdayBells,
                onChanged: (schedule) =>
                    controller.saveBells(schedule, saturday: _saturday),
              ),
              const SizedBox(height: 28),
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
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
                        controller.isMock
                            ? 'Сейчас показываются демо-данные. Реальный сайт колледжа подключается в ParserService.'
                            : 'Расписание загружается с сайта колледжа и сохраняется на устройстве.',
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
    );
  }
}