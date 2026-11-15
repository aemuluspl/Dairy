/// Урок в расписании. Время хранится строками вида «08:30»,
/// потому что для отображения этого достаточно, а JSON остаётся читаемым.
class Lesson {
  const Lesson({
    required this.subject,
    required this.start,
    required this.end,
    this.room,
    this.number,
  });

  final String subject;
  final String start;
  final String end;
  final String? room;

  /// Номер урока в дне. Может отсутствовать: у РОВ или внеурочных
  /// занятий в эталонном JSON приходит `null`.
  final int? number;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'subject': subject,
      'start': start,
      'end': end,
      'room': room,
      'number': number,
    };
  }

  factory Lesson.fromMap(Map<dynamic, dynamic> map) {
    return Lesson(
      subject: map['subject']?.toString() ?? 'Предмет',
      start: map['start']?.toString() ?? '08:30',
      end: map['end']?.toString() ?? '09:10',
      room: map['room']?.toString(),
      number: _numberOf(map['number']),
    );
  }

  static int? _numberOf(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  Lesson copyWith({
    String? subject,
    String? start,
    String? end,
    String? room,
    int? number,
  }) {
    return Lesson(
      subject: subject ?? this.subject,
      start: start ?? this.start,
      end: end ?? this.end,
      room: room ?? this.room,
      number: number ?? this.number,
    );
  }
}
