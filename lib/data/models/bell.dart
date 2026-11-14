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

/// Стандартная сетка звонков. Используется как запасная для дня,
/// в котором ещё нет уроков и не настроены свои звонки.
const List<Bell> defaultBellGrid = <Bell>[
  Bell(start: '08:00', end: '08:40'),
  Bell(start: '08:50', end: '09:30'),
  Bell(start: '09:45', end: '10:25'),
  Bell(start: '10:40', end: '11:20'),
  Bell(start: '11:35', end: '12:15'),
  Bell(start: '12:30', end: '13:10'),
  Bell(start: '13:25', end: '14:05'),
];
