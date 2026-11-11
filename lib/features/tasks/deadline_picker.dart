import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

/// Ручная корректировка дедлайна. Время всегда 20:00 —
/// вечерний слот, в который удобно закрыть домашку.
Future<DateTime?> pickHomeworkDeadline(
  BuildContext context,
  DateTime current,
) async {
  final strings = context.read<AppState>().strings;
  final now = DateTime.now();
  final firstDate = DateTime(now.year - 1, now.month, now.day);
  final initial = current.isBefore(firstDate) ? now : current;

  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate,
    lastDate: DateTime(now.year + 3, 12, 31),
    helpText: strings.datePickerHelp,
    cancelText: strings.cancel,
    confirmText: strings.save,
    locale:
        strings.isEnglish ? const Locale('en', 'US') : const Locale('ru', 'RU'),
  );

  if (picked == null) return null;
  return DateTime(picked.year, picked.month, picked.day, 20);
}
