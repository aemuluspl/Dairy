import '../data/models/holiday.dart';
import '../data/models/lesson.dart';
import 'subject_resolver.dart';

/// Учебный календарь: какие дни вообще учебные и когда у предмета урок.
///
/// Используется парсером дедлайнов, экраном расписания и редактором.
/// Календарь создаётся «на лету» из текущего состояния приложения,
/// поэтому изменения расписания и каникул сразу влияют на расчёты.
class SchoolCalendar {
  SchoolCalendar({
    required this.schedule,
    List<HolidayPeriod> holidays = const <HolidayPeriod>[],
    this.saturdayOff = false,
    this.resolver,
  }) : holidays = List<HolidayPeriod>.unmodifiable(holidays);

  final Map<int, List<Lesson>> schedule;
  final List<HolidayPeriod> holidays;
  final bool saturdayOff;
  final SubjectResolver? resolver;

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Попадает ли дата в период каникул.
  bool isHoliday(DateTime date) {
    for (final period in holidays) {
      if (period.contains(date)) return true;
    }
    return false;
  }

  HolidayPeriod? holidayAt(DateTime date) {
    for (final period in holidays) {
      if (period.contains(date)) return period;
    }
    return null;
  }

  /// Учебный ли день: не воскресенье, не отключённая суббота, не каникулы.
  bool isSchoolDay(DateTime date) {
    final weekday = date.weekday;
    if (weekday == DateTime.sunday) return false;
    if (saturdayOff && weekday == DateTime.saturday) return false;
    return !isHoliday(date);
  }

  /// Ближайший учебный день строго после [date].
  DateTime nextSchoolDay(DateTime date) {
    var next = dateOnly(date).add(const Duration(days: 1));
    var guard = 0;
    while (!isSchoolDay(next) && guard < 400) {
      next = next.add(const Duration(days: 1));
      guard++;
    }
    return next;
  }

  List<Lesson> lessonsFor(int weekday) => schedule[weekday] ?? const <Lesson>[];

  /// Совпадает ли название урока с каноническим предметом.
  ///
  /// «Общество» → «Обществознание», «Труд» → «Технология», «ОБЗР» → «ОБЖ».
  bool lessonMatches(String lessonSubject, String canonicalSubject) {
    final subject = canonicalSubject.trim().toLowerCase();
    if (subject.isEmpty) return false;
    final raw = lessonSubject.trim().toLowerCase();
    if (raw == subject) return true;

    final normalizer = resolver;
    if (normalizer == null) {
      return normalizerFallback(raw) == normalizerFallback(subject);
    }
    return normalizer.resolve(lessonSubject) == canonicalSubject;
  }

  bool hasLessonFor(String canonicalSubject, int weekday) {
    for (final lesson in lessonsFor(weekday)) {
      if (lessonMatches(lesson.subject, canonicalSubject)) return true;
    }
    return false;
  }

  /// Ближайшие даты (начиная с [from], включая его), когда у предмета урок.
  ///
  /// Учитывает каникулы, воскресенье и режим «суббота — выходной».
  List<DateTime> upcomingSubjectDates(
    String canonicalSubject, {
    required DateTime from,
    int limit = 30,
  }) {
    final result = <DateTime>[];
    var cursor = dateOnly(from);
    for (var guard = 0; guard < 400 && result.length < limit; guard++) {
      if (isSchoolDay(cursor) &&
          hasLessonFor(canonicalSubject, cursor.weekday)) {
        result.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  /// Ближайшая дата урока предмета, начиная с [from] включительно.
  DateTime? firstSubjectDate(String canonicalSubject,
      {required DateTime from}) {
    final dates = upcomingSubjectDates(canonicalSubject, from: from, limit: 1);
    return dates.isEmpty ? null : dates.first;
  }

  static String normalizerFallback(String value) => value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll(RegExp(r'[^a-zа-я0-9]'), '');
}
