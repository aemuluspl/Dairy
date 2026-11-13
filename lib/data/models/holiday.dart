/// Период каникул / выходных, когда уроков нет.
///
/// Границы включительные и хранятся как календарные даты (без времени).
class HolidayPeriod {
  HolidayPeriod({required DateTime start, required DateTime end})
      : start = _dateOnly(start),
        end = _dateOnly(end) {
    if (this.end.isBefore(this.start)) {
      throw ArgumentError('Конец каникул раньше начала');
    }
  }

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final day = _dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  int get days => end.difference(start).inDays + 1;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };

  static HolidayPeriod? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final start = DateTime.tryParse(raw['start']?.toString() ?? '');
    final end = DateTime.tryParse(raw['end']?.toString() ?? '');
    if (start == null || end == null) return null;
    if (end.isBefore(start)) return null;
    return HolidayPeriod(start: start, end: end);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
