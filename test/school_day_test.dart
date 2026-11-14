import 'package:flutter_test/flutter_test.dart';
import 'package:school_diary/core/utils/school_day.dart';
import 'package:school_diary/data/models/lesson.dart';

void main() {
  const List<Lesson> day = <Lesson>[
    Lesson(subject: 'Алгебра', start: '08:00', end: '08:40'),
    Lesson(subject: 'Физика', start: '08:50', end: '09:30'),
    Lesson(subject: 'История', start: '09:45', end: '10:25'),
    Lesson(subject: 'Русский', start: '10:40', end: '11:20'),
    Lesson(subject: 'Химия', start: '11:35', end: '12:15'),
    Lesson(subject: 'Биология', start: '12:30', end: '13:10'),
    Lesson(subject: 'Геометрия', start: '13:25', end: '14:05'),
  ];

  final Map<int, List<Lesson>> schedule = <int, List<Lesson>>{
    for (var weekday = DateTime.monday; weekday <= DateTime.saturday; weekday++)
      weekday: day,
  };

  test('до конца уроков день помечен «сегодня»', () {
    final marks = resolveDayMarks(DateTime(2026, 11, 11, 10), schedule);

    expect(marks.today, DateTime.wednesday);
    expect(marks.tomorrow, isNull);
  });

  test('после последнего урока «сегодня» уходит на следующий день', () {
    final marks = resolveDayMarks(DateTime(2026, 11, 11, 15), schedule);

    expect(marks.today, isNull);
    expect(marks.tomorrow, DateTime.thursday);
  });

  test('в воскресенье «завтра» — понедельник', () {
    final marks = resolveDayMarks(DateTime(2026, 11, 15, 12), schedule);

    expect(marks.today, isNull);
    expect(marks.tomorrow, DateTime.monday);
  });

  test('в субботу вечером метки пустые, следующий день — понедельник', () {
    final now = DateTime(2026, 11, 14, 15);
    final marks = resolveDayMarks(now, schedule);
    final live = resolveLiveStatus(now, schedule);

    expect(marks.today, isNull);
    expect(marks.tomorrow, isNull);
    expect(live.kind, LiveStatusKind.nextDay);
    expect(live.day, DateTime.monday);
  });

  test('живой статус: урок, перемена и до начала', () {
    final inLesson = resolveLiveStatus(DateTime(2026, 11, 11, 9, 0), schedule);
    expect(inLesson.kind, LiveStatusKind.inLesson);
    expect(inLesson.lesson?.subject, 'Физика');
    expect(inLesson.lesson?.start, '08:50');

    final onBreak = resolveLiveStatus(DateTime(2026, 11, 11, 8, 45), schedule);
    expect(onBreak.kind, LiveStatusKind.onBreak);
    expect(onBreak.time, '08:50');

    final before = resolveLiveStatus(DateTime(2026, 11, 11, 7, 30), schedule);
    expect(before.kind, LiveStatusKind.beforeSchool);
    expect(before.time, '08:00');
  });

  test('живой статус после школы: завтра N уроков', () {
    final live = resolveLiveStatus(DateTime(2026, 11, 11, 15), schedule);

    expect(live.kind, LiveStatusKind.tomorrow);
    expect(live.day, DateTime.thursday);
    expect(live.lessonCount, 7);
  });

  test('живой статус отдаёт следующий урок', () {
    final inLesson = resolveLiveStatus(DateTime(2026, 11, 11, 9), schedule);
    expect(inLesson.nextLesson?.subject, 'История');
    expect(inLesson.nextLesson?.start, '09:45');

    final onBreak = resolveLiveStatus(DateTime(2026, 11, 11, 8, 45), schedule);
    expect(onBreak.nextLesson?.subject, 'Физика');

    final before = resolveLiveStatus(DateTime(2026, 11, 11, 7, 30), schedule);
    expect(before.nextLesson?.subject, 'Алгебра');
  });

  test('суббота-выходной уводит «завтра» на понедельник', () {
    final friday = DateTime(2026, 11, 13, 15);
    final withSaturday = resolveDayMarks(friday, schedule);
    expect(withSaturday.tomorrow, DateTime.saturday);

    final marks = resolveDayMarks(friday, schedule, saturdayOff: true);
    final live = resolveLiveStatus(friday, schedule, saturdayOff: true);

    expect(marks.tomorrow, isNull);
    expect(live.kind, LiveStatusKind.nextDay);
    expect(live.day, DateTime.monday);
  });
}
