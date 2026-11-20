import 'package:flutter/material.dart';

import '../models/bell_schedule.dart';
import 'app_theme.dart';

class BellsEditor extends StatefulWidget {
  final BellSchedule schedule;
  final ValueChanged<BellSchedule> onChanged;

  const BellsEditor({
    super.key,
    required this.schedule,
    required this.onChanged,
  });

  @override
  State<BellsEditor> createState() => _BellsEditorState();
}

class _BellsEditorState extends State<BellsEditor> {
  String? _error;

  @override
  void didUpdateWidget(BellsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schedule != widget.schedule) _error = null;
  }

  Future<void> _pick(int index, bool isStart) async {
    final period = widget.schedule.periods[index];
    final initial = isStart ? period.startMinutes : period.endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final minutes = picked.hour * 60 + picked.minute;
    final updated = isStart
        ? BellPeriod(minutes, period.endMinutes)
        : BellPeriod(period.startMinutes, minutes);
    if (!updated.isValid) {
      setState(() {
        _error = 'Пара ${index + 1}: конец должен быть позже начала';
      });
      return;
    }
    setState(() => _error = null);
    widget.onChanged(widget.schedule.copyWithPeriod(index, updated));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.schedule.periods.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      '${i + 1} пара',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _TimeButton(
                    label: 'Начало',
                    value: widget.schedule.periods[i].startLabel,
                    onPressed: () => _pick(i, true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeButton(
                    label: 'Конец',
                    value: widget.schedule.periods[i].endLabel,
                    onPressed: () => _pick(i, false),
                  ),
                ),
              ],
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 13, color: kError),
            ),
          ),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onPressed;

  const _TimeButton({
    super.key,
    required this.label,
    required this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: kTextSecondary),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onPressed,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}