import '../data/seed/default_aliases.dart';
import 'subject_resolver.dart';

class ParsedHomework {
  const ParsedHomework({
    required this.subject,
    required this.description,
    required this.deadline,
    required this.rawTag,
  });

  final String subject;
  final String description;
  final DateTime deadline;
  final String rawTag;
}

/// Парсер «вброса».
///
/// 1. Делит строку на задачи по хэштегам.
/// 2. Убирает хэштеги из описания.
/// 3. Понимает алиасы предметов.
/// 4. Считает дедлайн и перешагивает выходные.
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

  List<ParsedHomework> parse(String input, {DateTime? now}) {
    final text = input.trim();
    if (text.isEmpty) return const <ParsedHomework>[];

    final reference = now ?? DateTime.now();
    final matches = _hashtagPattern.allMatches(text).toList(growable: false);

    if (matches.isEmpty) {
      final description = _cleanDescription(text);
      if (description.isEmpty) return const <ParsedHomework>[];
      return <ParsedHomework>[
        ParsedHomework(
          subject: 'Разное',
          description: description,
          deadline: _deadlineFor(text, reference),
          rawTag: '',
        ),
      ];
    }

    final leading = text.substring(0, matches.first.start).trim();
    final result = <ParsedHomework>[];

    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      final tag = _cleanTag(match.group(1) ?? '');
      if (tag.isEmpty) continue;

      final segmentEnd =
          index + 1 < matches.length ? matches[index + 1].start : text.length;
      var body = text.substring(match.end, segmentEnd).trim();
      if (index == 0 && leading.isNotEmpty) {
        body = body.isEmpty ? leading : '$leading $body';
      }

      result.add(
        ParsedHomework(
          subject: resolver.resolve(tag),
          description: _cleanDescription(body),
          deadline: _deadlineFor(body, reference),
          rawTag: tag,
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

  DateTime _deadlineFor(String rawText, DateTime now) {
    final text = rawText.toLowerCase().replaceAll('ё', 'е');
    final today = DateTime(now.year, now.month, now.day);
    final words = text
        .split(RegExp(r'[^а-яa-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    DateTime target;
    final explicit = _parseExplicitDate(text, today);

    if (explicit != null) {
      target = explicit;
    } else if (words.any((word) => word.startsWith('послезавтра'))) {
      target = today.add(const Duration(days: 2));
    } else if (words.any((word) => word.startsWith('завтра'))) {
      target = today.add(const Duration(days: 1));
    } else if (words.any((word) => word.startsWith('сегодня'))) {
      target = today;
    } else {
      final weekday = _findWeekday(words);
      target = weekday != null
          ? _nextWeekday(today, weekday, now)
          : _defaultSchoolDate(today);
    }

    // Пятница/суббота + «на понедельник» => домашку делаем в воскресенье вечером.
    if ((today.weekday == DateTime.friday ||
            today.weekday == DateTime.saturday) &&
        target.weekday == DateTime.monday) {
      target = target.subtract(const Duration(days: 1));
    }

    // Любой дедлайн, попавший на субботу, переносится на воскресенье.
    if (target.weekday == DateTime.saturday) {
      target = target.add(const Duration(days: 1));
    }

    if (target.isBefore(today)) target = today;

    return DateTime(
      target.year,
      target.month,
      target.day,
      defaultHour,
    );
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

  DateTime _defaultSchoolDate(DateTime today) {
    switch (today.weekday) {
      case DateTime.friday:
        return today.add(const Duration(days: 2)); // воскресенье
      case DateTime.saturday:
        return today.add(const Duration(days: 1)); // воскресенье
      case DateTime.sunday:
        return today.add(const Duration(days: 1)); // понедельник
      default:
        return today.add(const Duration(days: 1));
    }
  }
}
