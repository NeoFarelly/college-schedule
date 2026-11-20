import 'package:flutter/material.dart';

import '../services/schedule_controller.dart';
import 'app_theme.dart';

Future<void> showGroupPicker(
  BuildContext context,
  ScheduleController controller,
) async {
  final groups = controller.availableGroups;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xF0101426),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Выберите группу',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
          ),
          for (final group in groups)
            ListTile(
              title: Text(
                group,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              trailing: group == controller.selectedGroup
                  ? const Icon(Icons.check, color: kAccent)
                  : null,
              onTap: () {
                controller.selectGroup(group);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    ),
  );
}