String plural(
  int count,
  String one,
  String few,
  String many,
) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}

String tasksCount(int count) =>
    '$count ${plural(count, 'задача', 'задачи', 'задач')}';

String lessonsCount(int count) =>
    '$count ${plural(count, 'урок', 'урока', 'уроков')}';

String subjectsCount(int count) =>
    '$count ${plural(count, 'предмет', 'предмета', 'предметов')}';

String daysCount(int count) => '$count ${plural(count, 'день', 'дня', 'дней')}';
