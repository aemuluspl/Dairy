import 'dart:convert';

import '../data/models/bell.dart';
import '../data/models/lesson.dart';

/// Результат разбора импортируемого расписания.
class ScheduleImport {
  const ScheduleImport({
    required this.schedule,
    required this.bells,
    required this.aliases,
  });

  final Map<int, List<Lesson>> schedule;
  final List<Bell> bells;
  final Map<String, List<String>> aliases;
}

/// Импорт и экспорт расписания: JSON и человекочитаемый текст.
class ScheduleTransferService {
  const ScheduleTransferService._();

  static const int version = 1;
  static const String format = 'hash.schedule';

  static const List<String> _weekdayKeys = <String>[
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const List<String> _weekdayTitles = <String>[
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  /// Уникальные звонки из расписания в порядке возрастания времени.
  static List<Bell> deriveBells(Map<int, List<Lesson>> schedule) {
    final seen = <String>{};
    final bells = <Bell>[];
    for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
      for (final lesson in schedule[day] ?? const <Lesson>[]) {
        final key = '${lesson.start}-${lesson.end}';
        if (seen.add(key)) {
          bells.add(Bell(start: lesson.start, end: lesson.end));
        }
      }
    }
    bells.sort((a, b) => a.start.compareTo(b.start));
    return bells;
  }

  static String exportJson({
    required Map<int, List<Lesson>> schedule,
    required Map<String, List<String>> aliases,
    List<Bell>? bells,
  }) {
    final days = <String, dynamic>{};
    for (var day = DateTime.monday; day <= DateTime.saturday; day++) {
      days['$day'] = (schedule[day] ?? const <Lesson>[])
          .map((lesson) => lesson.toMap())
          .toList(growable: false);
    }

    final payload = <String, dynamic>{
      'format': format,
      'version': version,
      'schedule': days,
      'bells': (bells ?? deriveBells(schedule))
          .map((bell) => bell.toMap())
          .toList(growable: false),
      'aliases': aliases,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static String exportText({
    required Map<int, List<Lesson>> schedule,
    List<Bell>? bells,
  }) {
    final buffer = StringBuffer();
    for (var day = DateTime.monday; day <= DateTime.saturday; day++) {
      final lessons = schedule[day] ?? const <Lesson>[];
      buffer.writeln(_weekdayTitles[day - 1].toUpperCase());
      if (lessons.isEmpty) {
        buffer.writeln('—');
      } else {
        for (final lesson in lessons) {
          final room = lesson.room == null || lesson.room!.isEmpty
              ? ''
              : ' · каб. ${lesson.room}';
          buffer.writeln(
            '${lesson.start}–${lesson.end} ${lesson.subject}$room',
          );
        }
      }
      buffer.writeln();
    }

    final ring = bells ?? deriveBells(schedule);
    if (ring.isNotEmpty) {
      buffer.writeln('ЗВОНКИ');
      for (var index = 0; index < ring.length; index++) {
        buffer.writeln(
          '${index + 1}. ${ring[index].start}–${ring[index].end}',
        );
      }
    }

    return buffer.toString().trim();
  }

  static ScheduleImport? tryParse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    if (text.startsWith('{')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) return _fromJson(decoded);
      } catch (_) {
        return null;
      }
    }

    return _fromText(text);
  }

  static ScheduleImport? _fromJson(Map<dynamic, dynamic> root) {
    // Новый формат: {schedule, bells, aliases}.
    var rawSchedule = root['schedule'];
    var rawBells = root['bells'];
    var rawAliases = root['aliases'];

    // Совместимость со старым экспортом 1.0.x:
    // {modules: {homework: {schedule, subjectAliases}}}.
    if (rawSchedule == null && root['modules'] is Map) {
      final modules = root['modules'] as Map;
      final homework = modules['homework'];
      if (homework is Map) {
        rawSchedule = homework['schedule'];
        rawAliases = homework['subjectAliases'];
      }
    }

    if (rawSchedule is! Map) return null;

    final bells = <Bell>[];
    if (rawBells is List) {
      for (final item in rawBells) {
        if (item is Map) {
          bells.add(Bell.fromMap(item));
        } else if (item is String) {
          final parsed = _parseBellLine(item);
          if (parsed != null) bells.add(parsed);
        }
      }
    }

    final schedule = <int, List<Lesson>>{
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        day: <Lesson>[],
    };

    for (final entry in rawSchedule.entries) {
      final day = _dayNumber(entry.key.toString());
      if (day == null) continue;
      final rawLessons = entry.value;
      if (rawLessons is! List) continue;

      for (var index = 0; index < rawLessons.length; index++) {
        final item = rawLessons[index];
        if (item is! Map) continue;
        final fallback = index < bells.length ? bells[index] : null;
        final lesson = Lesson(
          subject: item['subject']?.toString() ?? 'Предмет',
          start: item['start']?.toString() ?? fallback?.start ?? '08:00',
          end: item['end']?.toString() ?? fallback?.end ?? '08:40',
          room: item['room']?.toString(),
        );
        schedule[day]!.add(lesson);
      }
    }

    final aliases = <String, List<String>>{};
    if (rawAliases is Map) {
      for (final entry in rawAliases.entries) {
        final value = entry.value;
        if (value is List) {
          aliases[entry.key.toString()] = value
              .map((alias) => alias.toString().trim())
              .where((alias) => alias.isNotEmpty)
              .toList(growable: false);
        }
      }
    }

    return ScheduleImport(schedule: schedule, bells: bells, aliases: aliases);
  }

  static ScheduleImport? _fromText(String text) {
    final schedule = <int, List<Lesson>>{
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        day: <Lesson>[],
    };
    final bells = <Bell>[];

    int? currentDay;
    var inBells = false;
    var foundDay = false;

    final lessonPattern = RegExp(
      r'^(\d{1,2})[:.](\d{2})\s*[-–—]\s*(\d{1,2})[:.](\d{2})\s+(.+)$',
    );
    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final day = _dayFromTitle(line);
      if (day != null) {
        currentDay = day;
        inBells = false;
        foundDay = true;
        continue;
      }

      final upper = line.toUpperCase();
      if (upper.startsWith('ЗВОНК') || upper.startsWith('BELLS')) {
        inBells = true;
        currentDay = null;
        continue;
      }

      if (inBells) {
        final bell = _parseBellLine(line);
        if (bell != null) bells.add(bell);
        continue;
      }

      if (currentDay == null) continue;
      if (line == '—' || line == '-') continue;

      final match = lessonPattern.firstMatch(line);
      if (match == null) continue;

      final start = '${match.group(1)!.padLeft(2, '0')}:${match.group(2)!}';
      final end = '${match.group(3)!.padLeft(2, '0')}:${match.group(4)!}';
      var body = match.group(5)!.trim();
      String? room;
      final roomIndex = body.indexOf(' · каб. ');
      if (roomIndex >= 0) {
        room = body.substring(roomIndex + 8).trim();
        body = body.substring(0, roomIndex).trim();
      }
      if (body.isEmpty) continue;

      schedule[currentDay]!.add(
        Lesson(subject: body, start: start, end: end, room: room),
      );
    }

    if (!foundDay) return null;
    return ScheduleImport(
      schedule: schedule,
      bells: bells,
      aliases: const <String, List<String>>{},
    );
  }

  static Bell? _parseBellLine(String line) {
    final match = RegExp(
      r'^(?:\d+[.)]\s*)?(\d{1,2})[:.](\d{2})\s*[-–—]\s*(\d{1,2})[:.](\d{2})\s*$',
    ).firstMatch(line.trim());
    if (match == null) return null;
    return Bell(
      start: '${match.group(1)!.padLeft(2, '0')}:${match.group(2)!}',
      end: '${match.group(3)!.padLeft(2, '0')}:${match.group(4)!}',
    );
  }

  static int? _dayNumber(String raw) {
    final numeric = int.tryParse(raw);
    if (numeric != null && numeric >= 1 && numeric <= 7) return numeric;
    final index = _weekdayKeys.indexOf(raw.toLowerCase());
    return index >= 0 ? index + 1 : null;
  }

  static int? _dayFromTitle(String line) {
    final upper = line.toUpperCase();
    for (var index = 0; index < _weekdayTitles.length; index++) {
      final title = _weekdayTitles[index].toUpperCase();
      if (upper == title ||
          upper.startsWith('$title,') ||
          upper.startsWith('$title ')) {
        return index + 1;
      }
    }
    return null;
  }
}
