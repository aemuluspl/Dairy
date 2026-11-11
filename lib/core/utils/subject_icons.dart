import 'package:flutter/material.dart';

/// Иконка подбирается по названию канонического предмета.
IconData subjectIcon(String subject) {
  final value = subject.toLowerCase();
  if (value.contains('алгебр') || value.contains('матем')) {
    return Icons.calculate_rounded;
  }
  if (value.contains('геометр')) return Icons.change_history_rounded;
  if (value.contains('русск')) return Icons.translate_rounded;
  if (value.contains('литератур') || value.contains('чтени')) {
    return Icons.menu_book_rounded;
  }
  if (value.contains('физик')) return Icons.science_rounded;
  if (value.contains('хим')) return Icons.biotech_rounded;
  if (value.contains('биолог')) return Icons.eco_rounded;
  if (value.contains('истори')) return Icons.account_balance_rounded;
  if (value.contains('обществ')) return Icons.groups_rounded;
  if (value.contains('географ')) return Icons.public_rounded;
  if (value.contains('англ') ||
      value.contains('немец') ||
      value.contains('француз')) {
    return Icons.language_rounded;
  }
  if (value.contains('информ')) return Icons.computer_rounded;
  if (value.contains('обж') || value.contains('безопас')) {
    return Icons.health_and_safety_rounded;
  }
  if (value.contains('физкультур') || value.contains('физра')) {
    return Icons.sports_soccer_rounded;
  }
  if (value.contains('технолог') || value.contains('труд')) {
    return Icons.handyman_rounded;
  }
  return Icons.school_rounded;
}
