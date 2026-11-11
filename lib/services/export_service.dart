import 'dart:convert';

import '../data/models/lesson.dart';
import '../data/models/task.dart';

/// Экспорт в формате, который можно будет слить с будущими модулями
/// (заметки, контакты PDB и т.д.).
class ExportService {
  const ExportService._();

  static const int schemaVersion = 1;

  static const List<String> _weekdayKeys = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static String buildJson({
    required List<Task> tasks,
    required Map<int, List<Lesson>> schedule,
    required Map<String, List<String>> aliases,
  }) {
    final scheduleJson = <String, dynamic>{};
    for (final entry in schedule.entries) {
      final key = entry.key >= 1 && entry.key <= 7
          ? _weekdayKeys[entry.key - 1]
          : 'day_${entry.key}';
      scheduleJson[key] =
          entry.value.map((lesson) => lesson.toMap()).toList(growable: false);
    }

    final payload = <String, dynamic>{
      'format': 'school-diary.unified-db',
      'schemaVersion': schemaVersion,
      'app': 'Дневник',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'modules': <String, dynamic>{
        'homework': <String, dynamic>{
          'tasks': tasks.map((task) => task.toMap()).toList(growable: false),
          'schedule': scheduleJson,
          'subjectAliases': aliases,
        },
      },
      'reservedModules': <String>['notes', 'contacts'],
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}
