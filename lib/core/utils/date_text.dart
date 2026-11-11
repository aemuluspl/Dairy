const List<String> _monthsGenitive = <String>[
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

const List<String> _monthsEnglish = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _weekdaysFull = <String>[
  'понедельник',
  'вторник',
  'среда',
  'четверг',
  'пятница',
  'суббота',
  'воскресенье',
];

const List<String> _weekdaysFullEnglish = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _weekdaysShort = <String>[
  'Пн',
  'Вт',
  'Ср',
  'Чт',
  'Пт',
  'Сб',
  'Вс',
];

const List<String> _weekdaysShortEnglish = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String capitalizeFirst(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String weekdayFull(int weekday, {bool english = false}) =>
    (english ? _weekdaysFullEnglish : _weekdaysFull)[weekday - 1];

String weekdayShort(int weekday, {bool english = false}) =>
    (english ? _weekdaysShortEnglish : _weekdaysShort)[weekday - 1];

String formatDayMonth(DateTime date, {DateTime? now, bool english = false}) {
  final referenceYear = (now ?? DateTime.now()).year;
  final base = english
      ? '${_monthsEnglish[date.month - 1]} ${date.day}'
      : '${date.day} ${_monthsGenitive[date.month - 1]}';
  return date.year == referenceYear ? base : '$base ${date.year}';
}

String formatTime(DateTime date) {
  final hours = date.hour.toString().padLeft(2, '0');
  final minutes = date.minute.toString().padLeft(2, '0');
  return '$hours:$minutes';
}

String formatDeadline(DateTime date, {bool english = false}) =>
    '${formatDayMonth(date, english: english)} · ${formatTime(date)}';

String formatHeaderDate(DateTime date, {bool english = false}) =>
    '${capitalizeFirst(weekdayFull(date.weekday, english: english))}, '
    '${formatDayMonth(date, english: english)}';

String formatWeekdayWithDate(DateTime date, {bool english = false}) =>
    '${capitalizeFirst(weekdayFull(date.weekday, english: english))}, '
    '${formatDayMonth(date, english: english)}';

/// Заголовок группы задач: «Сегодня, 9 ноября», «Завтра, ...», «Просрочено · ...».
String groupTitleFor(
  DateTime deadline, {
  DateTime? now,
  bool english = false,
}) {
  final reference = now ?? DateTime.now();
  final difference = dateOnly(deadline).difference(dateOnly(reference)).inDays;
  final date = formatDayMonth(deadline, now: reference, english: english);

  if (difference < 0) {
    return english ? 'Overdue · $date' : 'Просрочено · $date';
  }
  if (difference == 0) {
    return english ? 'Today, $date' : 'Сегодня, $date';
  }
  if (difference == 1) {
    return english ? 'Tomorrow, $date' : 'Завтра, $date';
  }
  if (difference == 2) {
    return english ? 'Day after tomorrow, $date' : 'Послезавтра, $date';
  }
  return formatWeekdayWithDate(deadline, english: english);
}
