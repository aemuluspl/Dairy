/// Урок в расписании. Время хранится строками вида «08:30»,
/// потому что для отображения этого достаточно, а JSON остаётся читаемым.
class Lesson {
  const Lesson({
    required this.subject,
    required this.start,
    required this.end,
    this.room,
  });

  final String subject;
  final String start;
  final String end;
  final String? room;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'subject': subject,
      'start': start,
      'end': end,
      'room': room,
    };
  }

  factory Lesson.fromMap(Map<dynamic, dynamic> map) {
    return Lesson(
      subject: map['subject']?.toString() ?? 'Предмет',
      start: map['start']?.toString() ?? '08:30',
      end: map['end']?.toString() ?? '09:10',
      room: map['room']?.toString(),
    );
  }
}
