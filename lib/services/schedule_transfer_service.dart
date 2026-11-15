import 'dart:convert';

import '../data/models/bell.dart';
import '../data/models/lesson.dart';

/// Результат разбора импортируемого расписания.
class ScheduleImport {
  const ScheduleImport({
    required this.schedule,
    required this.bellsByDay,
    required this.aliases,
  });

  final Map<int, List<Lesson>> schedule;

  /// Ручная сетка звонков по дням 1–7 (формат v2).
  final Map<int, List<Bell>> bellsByDay;

  final Map<String, List<String>> aliases;

  /// Плоский список всех звонков — удобно для проверок и текста.
  List<Bell> get bells {
    final seen = <String>{};
    final result = <Bell>[];
    for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
      for (final bell in bellsByDay[day] ?? const <Bell>[]) {
        if (seen.add('${bell.start}-${bell.end}')) result.add(bell);
      }
    }
    return result;
  }
}

/// Импорт и экспорт расписания: JSON и человекочитаемый текст.
class ScheduleTransferService {
  const ScheduleTransferService._();

  static const int version = 2;
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

  static const List<String> _weekdayShort = <String>[
    'пн',
    'вт',
    'ср',
    'чт',
    'пт',
    'сб',
    'вс',
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
    Map<int, List<Bell>>? bellsByDay,
  }) {
    final days = <String, dynamic>{};
    for (var day = DateTime.monday; day <= DateTime.saturday; day++) {
      days['$day'] = (schedule[day] ?? const <Lesson>[])
          .map((lesson) => lesson.toMap())
          .toList(growable: false);
    }

    // v2: звонки хранятся по дням, чтобы у каждого дня могла быть
    // своя сетка (например, дополнительный урок РОВ в понедельник).
    final bells = <String, dynamic>{};
    final source = bellsByDay ??
        <int, List<Bell>>{
          for (var day = DateTime.monday; day <= DateTime.saturday; day++)
            day: deriveBells(<int, List<Lesson>>{
              day: schedule[day] ?? const <Lesson>[],
            }),
        };
    for (var day = DateTime.monday; day <= DateTime.saturday; day++) {
      final list = source[day] ?? const <Bell>[];
      if (list.isEmpty) continue;
      bells['$day'] = list.map((bell) => bell.toMap()).toList(growable: false);
    }

    final payload = <String, dynamic>{
      'format': format,
      'version': version,
      'schedule': days,
      'bells': bells,
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
    dynamic rawSchedule;
    dynamic rawBells;
    dynamic rawAliases;

    void readContainer(Map<dynamic, dynamic> map) {
      rawSchedule ??=
          map['schedule'] ?? map['days'] ?? map['week'] ?? map['timetable'];
      rawBells ??= map['bells'] ?? map['calls'] ?? map['bellSchedule'];
      rawAliases ??= map['aliases'] ?? map['subjectAliases'];

      // Совместимость со старым экспортом 1.0.x:
      // {modules: {homework: {schedule, subjectAliases}}}.
      final modules = map['modules'];
      if (modules is Map) {
        final homework = modules['homework'];
        if (homework is Map) {
          rawSchedule ??= homework['schedule'];
          rawAliases ??= homework['subjectAliases'];
        }
      }
    }

    readContainer(root);

    // Голый словарь дней: {"Понедельник": [...], "monday": [...]}.
    if (rawSchedule == null &&
        root.keys.any((key) => _dayNumber(key.toString()) != null)) {
      rawSchedule = root;
    }
    if (rawSchedule == null) return null;

    // Звонки по дням — единственная сетка, которой доверяем для
    // отображения. Плоский список считается глобальной сеткой и
    // используется только как запасной вариант для уроков без времени.
    final bellsByDay = <int, List<Bell>>{};
    final legacyBells = <Bell>[];
    if (rawBells is Map) {
      for (final entry in rawBells.entries) {
        final day = _dayNumber(entry.key.toString());
        if (day == null) continue;
        final list = _parseBells(entry.value);
        if (list.isNotEmpty) bellsByDay[day] = list;
      }
    } else if (rawBells is List) {
      legacyBells.addAll(_parseBells(rawBells));
    }

    final schedule = <int, List<Lesson>>{
      for (var day = DateTime.monday; day <= DateTime.sunday; day++)
        day: <Lesson>[],
    };

    for (final entry in _dayEntries(rawSchedule).entries) {
      final day = entry.key;
      final dayBells = bellsByDay[day] ?? const <Bell>[];
      final items = entry.value;

      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        if (item is! Map) continue;
        final fallback = index < dayBells.length
            ? dayBells[index]
            : (index < legacyBells.length ? legacyBells[index] : null);
        final lesson = _parseLesson(item, fallback);
        if (lesson == null) continue;
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

    return ScheduleImport(
      schedule: schedule,
      bellsByDay: bellsByDay,
      aliases: aliases,
    );
  }

  /// Приводит любую форму дней к карте «номер дня → уроки».
  ///
  /// Поддерживаются словари (`{"monday": [...]}`) и массивы
  /// (`[{"day": "Понедельник", "lessons": [...]}]`).
  static Map<int, List<dynamic>> _dayEntries(dynamic raw) {
    final result = <int, List<dynamic>>{};

    void add(int day, List<dynamic> lessons) {
      if (lessons.isEmpty) {
        result.putIfAbsent(day, () => <dynamic>[]);
        return;
      }
      result.putIfAbsent(day, () => <dynamic>[]).addAll(lessons);
    }

    if (raw is Map) {
      for (final entry in raw.entries) {
        final day = _dayNumber(entry.key.toString());
        if (day == null) continue;
        add(day, _lessonsOf(entry.value));
      }
    } else if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final key = item['day'] ??
            item['weekday'] ??
            item['id'] ??
            item['name'] ??
            item['title'];
        if (key == null) continue;
        final day = _dayNumber(key.toString());
        if (day == null) continue;
        add(
          day,
          _lessonsOf(
            item['lessons'] ?? item['items'] ?? item['subjects'],
          ),
        );
      }
    }

    return result;
  }

  static List<dynamic> _lessonsOf(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      for (final key in const <String>[
        'lessons',
        'items',
        'subjects',
        'schedule',
        'list',
      ]) {
        final nested = value[key];
        if (nested is List) return nested;
      }
    }
    return const <dynamic>[];
  }

  /// Один урок из JSON. `number: null` (РОВ, внеурочка) — валидный случай.
  static Lesson? _parseLesson(Map<dynamic, dynamic> item, Bell? fallback) {
    var subject = (item['subject'] ??
            item['name'] ??
            item['title'] ??
            item['lesson'] ??
            '')
        .toString()
        .trim();
    if (subject.isEmpty) subject = 'Предмет';

    var start = _timeOf(
      item['start'] ?? item['startTime'] ?? item['begin'] ?? item['from'],
    );
    var end = _timeOf(
      item['end'] ?? item['endTime'] ?? item['finish'] ?? item['to'],
    );

    final interval = item['time'] ?? item['interval'] ?? item['period'];
    if ((start == null || end == null) && interval != null) {
      final parts =
          interval.toString().split(RegExp(r'\s*[-–—]\s*'));
      if (parts.length >= 2) {
        start ??= _timeOf(parts[0]);
        end ??= _timeOf(parts[1]);
      }
    }

    start ??= fallback?.start ?? '08:00';
    end ??= fallback?.end ?? '08:40';

    final roomRaw = item['room'] ??
        item['cabinet'] ??
        item['office'] ??
        item['classroom'];
    final room = roomRaw?.toString().trim();

    return Lesson(
      subject: subject,
      start: start,
      end: end,
      room: room == null || room.isEmpty ? null : room,
      number: _intOf(
        item['number'] ?? item['lessonNumber'] ?? item['index'],
      ),
    );
  }

  static String? _timeOf(Object? raw) {
    if (raw == null) return null;
    final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(raw.toString());
    if (match == null) return null;
    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final hour = hours < 0 ? 0 : (hours > 23 ? 23 : hours);
    final minute = minutes < 0 ? 0 : (minutes > 59 ? 59 : minutes);
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  static int? _intOf(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  static List<Bell> _parseBells(Object? raw) {
    final result = <Bell>[];
    if (raw is! List) return result;
    for (final item in raw) {
      if (item is Map) {
        result.add(Bell.fromMap(item));
      } else if (item is String) {
        final parsed = _parseBellLine(item);
        if (parsed != null) result.add(parsed);
      }
    }
    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
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
      bellsByDay: <int, List<Bell>>{
        if (bells.isNotEmpty)
          for (var day = DateTime.monday; day <= DateTime.saturday; day++)
            day: List<Bell>.from(bells),
      },
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
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return null;

    final numeric = int.tryParse(value);
    if (numeric != null && numeric >= 1 && numeric <= 7) return numeric;

    final index = _weekdayKeys.indexOf(value);
    if (index >= 0) return index + 1;

    final titleIndex =
        _weekdayTitles.indexWhere((title) => title.toLowerCase() == value);
    if (titleIndex >= 0) return titleIndex + 1;

    final shortIndex = _weekdayShort.indexOf(value);
    if (shortIndex >= 0) return shortIndex + 1;

    // «Понедельник, 9 класс» или «Monday — 8A».
    for (var i = 0; i < _weekdayTitles.length; i++) {
      if (value.startsWith(_weekdayTitles[i].toLowerCase())) return i + 1;
    }
    for (var i = 0; i < _weekdayKeys.length; i++) {
      if (value.startsWith(_weekdayKeys[i])) return i + 1;
    }
    return null;
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
