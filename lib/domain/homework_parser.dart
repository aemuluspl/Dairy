import '../data/seed/default_aliases.dart';
import 'school_calendar.dart';
import 'subject_resolver.dart';

class ParsedHomework {
  const ParsedHomework({
    required this.subject,
    required this.description,
    required this.deadline,
    required this.rawTag,
    this.due,
    this.usedSchedule = false,
  });

  final String subject;
  final String description;
  final DateTime deadline;
  final String rawTag;

  /// День урока, к которому задана домашка (до сдвига на вечер).
  final DateTime? due;

  /// Дедлайн посчитан по реальному расписанию предмета.
  final bool usedSchedule;
}

/// Парсер «вброса».
///
/// 1. Делит строку на задачи по хэштегам.
/// 2. Убирает хэштеги из описания и разбирает слипшиеся теги.
/// 3. Понимает алиасы предметов.
/// 4. Считает дедлайн: 20:00 накануне дня урока, по расписанию.
class HomeworkParser {
  HomeworkParser({
    SubjectResolver? resolver,
    this.defaultHour = 20,
  }) : resolver = resolver ?? SubjectResolver(defaultSubjectAliases);

  final SubjectResolver resolver;
  final int defaultHour;

  static final RegExp _hashtagPattern = RegExp(r'#([^\s#]+)', unicode: true);
  static final RegExp _numericDatePattern =
      RegExp(r'(\d{1,2})[./](\d{1,2})(?:[./](\d{2,4}))?');
  static final RegExp _monthDatePattern = RegExp(
    r'(\d{1,2})\s+(января|февраля|марта|апреля|мая|июня|июля|августа|сентября|октября|ноября|декабря)(?:\s+(\d{4}))?',
  );

  static const Map<String, int> _monthNumbers = <String, int>{
    'января': 1,
    'февраля': 2,
    'марта': 3,
    'апреля': 4,
    'мая': 5,
    'июня': 6,
    'июля': 7,
    'августа': 8,
    'сентября': 9,
    'октября': 10,
    'ноября': 11,
    'декабря': 12,
  };

  static const Map<int, List<String>> _weekdayStems = <int, List<String>>{
    DateTime.monday: <String>['понедельник', 'пн'],
    DateTime.tuesday: <String>['вторник', 'вт'],
    DateTime.wednesday: <String>['сред', 'ср'],
    DateTime.thursday: <String>['четверг', 'чт'],
    DateTime.friday: <String>['пятниц', 'пт'],
    DateTime.saturday: <String>['суббот', 'сб'],
    DateTime.sunday: <String>['воскресень', 'вс'],
  };

  List<ParsedHomework> parse(
    String input, {
    DateTime? now,
    SchoolCalendar? calendar,
  }) {
    final text = input.trim();
    if (text.isEmpty) return const <ParsedHomework>[];

    final reference = now ?? DateTime.now();
    final matches = _hashtagPattern.allMatches(text).toList(growable: false);

    if (matches.isEmpty) {
      final description = _cleanDescription(text);
      if (description.isEmpty) return const <ParsedHomework>[];
      final deadline = _deadlineFor(
        text,
        reference,
        subject: 'Разное',
        calendar: calendar,
      );
      return <ParsedHomework>[
        ParsedHomework(
          subject: 'Разное',
          description: description,
          deadline: deadline.value,
          rawTag: '',
          due: deadline.due,
          usedSchedule: deadline.bySchedule,
        ),
      ];
    }

    final leading = text.substring(0, matches.first.start).trim();
    final result = <ParsedHomework>[];

    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      var tag = _cleanTag(match.group(1) ?? '');
      if (tag.isEmpty) continue;

      // Слипшийся тег: #алгебраупр15 → предмет «Алгебра», хвост «упр15».
      String? gluedRest;
      if (resolver.resolveOrNull(tag) == null) {
        final split = resolver.splitGlued(tag);
        if (split != null) {
          tag = split.tag;
          gluedRest = split.rest;
        }
      }

      final subject = resolver.resolve(tag);
      final segmentEnd =
          index + 1 < matches.length ? matches[index + 1].start : text.length;
      var body = text.substring(match.end, segmentEnd).trim();
      if (gluedRest != null) {
        body = body.isEmpty ? gluedRest : '$gluedRest $body';
      }
      if (index == 0 && leading.isNotEmpty) {
        body = body.isEmpty ? leading : '$leading $body';
      }

      final deadline = _deadlineFor(
        body,
        reference,
        subject: subject,
        calendar: calendar,
      );

      result.add(
        ParsedHomework(
          subject: subject,
          description: _cleanDescription(body),
          deadline: deadline.value,
          rawTag: tag,
          due: deadline.due,
          usedSchedule: deadline.bySchedule,
        ),
      );
    }

    return result;
  }

  String _cleanTag(String raw) {
    return raw
        .replaceAll(RegExp(r'^[^A-Za-zА-Яа-яЁё0-9]+'), '')
        .replaceAll(RegExp(r'[^A-Za-zА-Яа-яЁё0-9_-]+$'), '');
  }

  String _cleanDescription(String raw) {
    return raw
        .replaceAll(_hashtagPattern, ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\s*\n\s*'), ' ')
        .trim();
  }

  ({DateTime value, DateTime due, bool bySchedule}) _deadlineFor(
    String rawText,
    DateTime now, {
    required String subject,
    SchoolCalendar? calendar,
  }) {
    final text = rawText.toLowerCase().replaceAll('ё', 'е');
    final today = SchoolCalendar.dateOnly(now);
    final words = text
        .split(RegExp(r'[^а-яa-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    // День, к которому задана домашка (день урока).
    DateTime due;
    var bySchedule = false;
    // Для дат «по умолчанию» дедлайн можно сдвинуть, если вечер уже прошёл.
    var flexible = false;

    final explicit = _parseExplicitDate(text, today);
    final shift = _shiftCount(words);

    if (explicit != null) {
      due = explicit;
    } else if (words.any((word) => word.startsWith('послезавтра'))) {
      due = _skipDaysOff(today.add(const Duration(days: 2)), calendar);
    } else if (words.any((word) => word.startsWith('завтра'))) {
      due = _skipDaysOff(today.add(const Duration(days: 1)), calendar);
    } else if (words.any((word) => word.startsWith('сегодня'))) {
      due = today;
    } else {
      final weekday = _findWeekday(words);
      if (weekday != null) {
        final candidate = _nextWeekday(today, weekday, now);
        // Явно названный день сдвигаем только если он выпал на каникулы
        // или отключённую субботу. Воскресенье остаётся допустимым.
        due = candidate.weekday == DateTime.sunday
            ? candidate
            : _skipDaysOff(candidate, calendar);
      } else {
        // Даты нет — ищем ближайший урок этого предмета в расписании.
        final scheduled = _subjectDeadline(
          subject: subject,
          today: today,
          now: now,
          calendar: calendar,
          shift: shift ?? 0,
        );
        if (scheduled != null) {
          return (
            value: scheduled.deadline,
            due: scheduled.due,
            bySchedule: true,
          );
        }

        due = calendar?.nextSchoolDay(today) ?? _nextSchoolDay(today);
        flexible = true;
        bySchedule = false;
      }
    }

    // Дедлайн — вечер (20:00) накануне дня урока.
    var candidate = _eveningBefore(due, today);

    while (flexible && candidate.isBefore(now)) {
      due = calendar?.nextSchoolDay(due) ?? _nextSchoolDay(due);
      candidate = _eveningBefore(due, today);
    }

    return (
      value: candidate,
      due: SchoolCalendar.dateOnly(due),
      bySchedule: bySchedule
    );
  }

  /// Дедлайн по расписанию: ближайший урок предмета (со сдвигом «через урок»).
  ({DateTime deadline, DateTime due})? _subjectDeadline({
    required String subject,
    required DateTime today,
    required DateTime now,
    required int shift,
    SchoolCalendar? calendar,
  }) {
    if (calendar == null || subject == 'Разное') return null;

    final dates = calendar.upcomingSubjectDates(subject, from: today);
    if (dates.isEmpty) return null;

    var index = shift;
    while (index < dates.length) {
      final due = dates[index];
      final candidate = _eveningBefore(due, today);
      if (!candidate.isBefore(now)) {
        return (deadline: candidate, due: due);
      }
      index++;
    }
    return null;
  }

  /// «через урок» = 1, «через 2 урока» = 2, «на следующий урок» = 0.
  int? _shiftCount(List<String> words) {
    final mentionsLesson = words.any((word) => word.startsWith('урок'));
    if (!mentionsLesson) return null;

    final throughIndex = words.indexWhere((word) => word.startsWith('через'));
    if (throughIndex >= 0) {
      for (var index = throughIndex + 1; index < words.length; index++) {
        final number = int.tryParse(words[index]);
        if (number != null && number > 0) return number;
        if (words[index].startsWith('урок')) return 1;
      }
      return 1;
    }

    if (words.any((word) => word.startsWith('следующ'))) return 0;
    return null;
  }

  /// Сдвигает выпавший выходной/каникулы на ближайший учебный день.
  DateTime _skipDaysOff(DateTime date, SchoolCalendar? calendar) {
    if (calendar == null || calendar.isSchoolDay(date)) return date;
    if (date.weekday == DateTime.sunday) return date;
    return calendar.nextSchoolDay(date);
  }

  /// 20:00 накануне дня урока. Если урок уже сегодня — вечер сегодня.
  DateTime _eveningBefore(DateTime due, DateTime today) {
    final previous = due.subtract(const Duration(days: 1));
    final target = previous.isBefore(today) ? today : previous;
    return DateTime(
      target.year,
      target.month,
      target.day,
      defaultHour,
    );
  }

  /// Ближайший учебный день строго после [date]. Воскресенье — выходной.
  DateTime _nextSchoolDay(DateTime date) {
    var next = date.add(const Duration(days: 1));
    while (next.weekday == DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime? _parseExplicitDate(String text, DateTime today) {
    final numeric = _numericDatePattern.firstMatch(text);
    if (numeric != null) {
      final day = int.tryParse(numeric.group(1) ?? '');
      final month = int.tryParse(numeric.group(2) ?? '');
      var year = int.tryParse(numeric.group(3) ?? '') ?? today.year;
      if (year < 100) year += 2000;
      if (day == null || month == null) return null;

      final candidate = _safeDate(year, month, day);
      if (candidate == null) return null;
      if (numeric.group(3) == null && candidate.isBefore(today)) {
        return _safeDate(year + 1, month, day);
      }
      return candidate;
    }

    final byMonth = _monthDatePattern.firstMatch(text);
    if (byMonth != null) {
      final day = int.tryParse(byMonth.group(1) ?? '');
      final month = _monthNumbers[byMonth.group(2)];
      var year = int.tryParse(byMonth.group(3) ?? '') ?? today.year;
      if (day == null || month == null) return null;

      var candidate = _safeDate(year, month, day);
      if (candidate == null) return null;
      if (byMonth.group(3) == null && candidate.isBefore(today)) {
        year += 1;
        candidate = _safeDate(year, month, day);
      }
      return candidate;
    }

    return null;
  }

  DateTime? _safeDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  int? _findWeekday(List<String> words) {
    for (final word in words) {
      for (final entry in _weekdayStems.entries) {
        for (final stem in entry.value) {
          final matches =
              stem.length <= 2 ? word == stem : word.startsWith(stem);
          if (matches) return entry.key;
        }
      }
    }
    return null;
  }

  DateTime _nextWeekday(DateTime today, int weekday, DateTime now) {
    var difference = (weekday - today.weekday) % 7;
    if (difference == 0 && now.hour >= defaultHour) difference = 7;
    return today.add(Duration(days: difference));
  }
}
