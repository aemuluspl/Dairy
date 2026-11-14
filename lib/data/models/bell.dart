/// Звонок: пара «начало – конец», общая для сетки расписания.
class Bell {
  const Bell({required this.start, required this.end});

  final String start;
  final String end;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'start': start,
        'end': end,
      };

  factory Bell.fromMap(Map<dynamic, dynamic> map) {
    return Bell(
      start: map['start']?.toString() ?? '08:00',
      end: map['end']?.toString() ?? '08:40',
    );
  }
}
