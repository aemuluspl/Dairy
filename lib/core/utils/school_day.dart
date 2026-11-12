import '../../data/models/lesson.dart';

/// Пометки «Сегодня» / «Завтра» для экрана расписания.
class DayMarks {
  const DayMarks({this.today, this.tomorrow});

  /// День, который сейчас идёт (пока не закончился последний урок).
  final int? today;

  /// Следующий учебный день, если он наступает буквально завтра.
  final int? tomorrow;
}

/// Состояние «прямо сейчас» для верхней плашки расписания.
enum LiveStatusKind { beforeSchool, inLesson, onBreak, tomorrow, nextDay }

class LiveStatus {
  const LiveStatus(
    this.kind, {
    this.lesson,
    this.time,
    this.day,
    this.lessonCount,
  });

  final LiveStatusKind kind;
  final Lesson? lesson;
  final String? time;
  final int? day;
  final int? lessonCount;
}

bool isSchoolDay(int weekday) =>
    weekday >= DateTime.monday && weekday <= DateTime.saturday;

int nextSchoolDay(int weekday) {
  var next = weekday + 1;
  if (next > DateTime.saturday) next = DateTime.monday;
  return next;
}

int minutesOf(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return 0;
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  return hours * 60 + minutes;
}

DateTime? _lessonEnd(Lesson lesson, DateTime reference) {
  final parts = lesson.end.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return DateTime(reference.year, reference.month, reference.day, hour, minute);
}

/// «Сегодня» — пока идёт учебный день (до конца последнего урока).
/// «Завтра» — следующий учебный день, только если он наступает завтра
/// (в воскресенье это понедельник, в субботу вечером — уже нет).
DayMarks resolveDayMarks(DateTime now, Map<int, List<Lesson>> schedule) {
  final weekday = now.weekday;
  var todayOpen = false;

  if (isSchoolDay(weekday)) {
    final lessons = schedule[weekday] ?? const <Lesson>[];
    if (lessons.isEmpty) {
      todayOpen = now.hour < 14;
    } else {
      final end = _lessonEnd(lessons.last, now);
      todayOpen = end == null || now.isBefore(end);
    }
  }

  final today = todayOpen ? weekday : null;
  final reference = today ?? weekday;
  final next = nextSchoolDay(reference);
  final tomorrowDate = DateTime(now.year, now.month, now.day + 1);
  final tomorrow = !todayOpen && tomorrowDate.weekday == next ? next : null;

  return DayMarks(today: today, tomorrow: tomorrow);
}

LiveStatus resolveLiveStatus(DateTime now, Map<int, List<Lesson>> schedule) {
  final weekday = now.weekday;
  final marks = resolveDayMarks(now, schedule);
  final minutes = now.hour * 60 + now.minute;

  if (marks.today != null) {
    final lessons = schedule[marks.today!] ?? const <Lesson>[];
    final first = lessons.firstOrNull;
    if (first == null) {
      return const LiveStatus(LiveStatusKind.tomorrow, lessonCount: 0);
    }
    if (minutes < minutesOf(first.start)) {
      return LiveStatus(LiveStatusKind.beforeSchool, time: first.start);
    }

    for (final lesson in lessons) {
      if (minutes >= minutesOf(lesson.start) &&
          minutes < minutesOf(lesson.end)) {
        return LiveStatus(LiveStatusKind.inLesson, lesson: lesson);
      }
    }

    for (final lesson in lessons) {
      if (minutes < minutesOf(lesson.start)) {
        return LiveStatus(LiveStatusKind.onBreak, time: lesson.start);
      }
    }
  }

  final reference = marks.today ?? weekday;
  final next = nextSchoolDay(reference);
  final tomorrowDate = DateTime(now.year, now.month, now.day + 1);
  if (tomorrowDate.weekday == next) {
    return LiveStatus(
      LiveStatusKind.tomorrow,
      day: next,
      lessonCount: (schedule[next] ?? const <Lesson>[]).length,
    );
  }
  return LiveStatus(LiveStatusKind.nextDay, day: next);
}
